part of '../keycloak_wrapper.dart';

/// A wrapper around the Keycloak authentication service.
///
/// Provides functionalities for user authentication, token management, and resource authorization.
class KeycloakWrapper {
  static KeycloakWrapper? _instance;

  bool _isInitialized = false;

  final KeycloakConfig _keycloakConfig;

  late final _streamController = StreamController<bool>.broadcast();

  /// Called whenever an error gets caught.
  ///
  /// By default, all errors will be printed into the console.
  void Function(String message, Object error, StackTrace stackTrace) onError =
      (message, error, stackTrace) => developer.log(
            message,
            name: 'keycloak_wrapper',
            error: error,
            stackTrace: stackTrace,
          );

  /// The details from making a successful token exchange.
  TokenResponse? tokenResponse;

  factory KeycloakWrapper({required KeycloakConfig config}) =>
      _instance ??= KeycloakWrapper._(config);

  KeycloakWrapper._(this._keycloakConfig);

  Timer? _refreshTimer;

  /// Returns the access token string.
  ///
  /// To get the payload, do `JWT.decode(keycloakWrapper.accessToken).payload`.
  String? get accessToken => tokenResponse?.accessToken;

  /// The stream of the user authentication state.
  ///
  /// Returns true if the user is currently logged in.
  Stream<bool> get authenticationStream => _streamController.stream;

  /// Returns the id token string.
  ///
  /// To get the payload, do `JWT.decode(keycloakWrapper.idToken).payload`.
  String? get idToken => tokenResponse?.idToken;

  /// Whether this package has been initialized.
  bool get isInitialized => _isInitialized;

  /// Returns the refresh token string.
  ///
  /// To get the payload, do `JWT.decode(keycloakWrapper.refreshToken).payload`.
  String? get refreshToken => tokenResponse?.refreshToken;

  /// Call this after login or token refresh to schedule the next refresh.
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();

    final accessToken = this.accessToken;
    if (accessToken == null) return;

    final jwt = JWT.decode(accessToken);
    final remaining = jwt.remainingTime;
    if (remaining == null || remaining.inSeconds <= 0) return;

    // Refresh 1 minute before expiry, but not less than 5 seconds from now
    final refreshIn = remaining - const Duration(minutes: 1);
    final duration = refreshIn > const Duration(seconds: 5)
        ? refreshIn
        : const Duration(seconds: 5);

    _refreshTimer = Timer(duration, () async {
      await updateToken();
      _scheduleTokenRefresh(); // Reschedule after refresh
    });
  }

  /// Call this in login and updateToken after a successful token response.
  void _onTokenUpdated() {
    _scheduleTokenRefresh();
    // ...any other logic you want after token update...
  }

  /// Call this on logout or dispose to cancel the timer.
  void _cancelTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Retrieves the current user information.
  Future<Map<String, dynamic>?> getUserInfo() async {
    _assertInitialization();
    try {
      final url = Uri.parse(_keycloakConfig.userInfoEndpoint);
      final client = HttpClient();
      final request = await client.getUrl(url)
        ..headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();
      return jsonDecode(responseBody) as Map<String, dynamic>?;
    } catch (e, s) {
      onError('Failed to fetch user info.', e, s);
      return null;
    }
  }

  /// Initializes the user authentication state and refreshes the token.
  Future<void> initialize() async {
    const key = 'keycloak:hasRunBefore';
    final prefs = SharedPreferencesAsync();
    final hasRunBefore = await prefs.getBool(key) ?? false;

    if (!hasRunBefore) {
      _secureStorage.deleteAll();
      prefs.setBool(key, true);
    }

    try {
      _isInitialized = true;
      await updateToken();
    } catch (e, s) {
      _isInitialized = false;
      onError('Failed to initialize plugin.', e, s);
    }
  }

  /// Logs the user in.
  ///
  /// Returns true if login is successful.
  Future<bool> login() async {
    _assertInitialization();
    try {
      tokenResponse = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _keycloakConfig.clientId,
          _keycloakConfig.redirectUri,
          issuer: _keycloakConfig.issuer,
          scopes: _keycloakConfig.scopes,
          promptValues: ['login'],
          allowInsecureConnections: _keycloakConfig.allowInsecureConnections,
          clientSecret: _keycloakConfig.clientSecret,
        ),
      );

      if (tokenResponse.isValid) {
        if (refreshToken != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: refreshToken,
          );
        }
        _onTokenUpdated(); // <-- Schedule refresh
      } else {
        developer.log('Invalid token response.', name: 'keycloak_wrapper');
      }

      _streamController.add(tokenResponse.isValid);
      return tokenResponse.isValid;
    } catch (e, s) {
      onError('Failed to login.', e, s);
      return false;
    }
  }

  /// Logs the user out.
  ///
  /// Returns true if logout is successful.
  Future<bool> logout() async {
    _assertInitialization();
    try {
      final request = EndSessionRequest(
        idTokenHint: idToken,
        issuer: _keycloakConfig.issuer,
        postLogoutRedirectUrl: _keycloakConfig.redirectUri,
        allowInsecureConnections: _keycloakConfig.allowInsecureConnections,
      );

      await _appAuth.endSession(request);
      await _secureStorage.deleteAll();
      tokenResponse = null;
      _cancelTokenRefresh(); // <-- Cancel scheduled refresh
      _streamController.add(false);
      return true;
    } catch (e, s) {
      onError('Failed to logout.', e, s);
      return false;
    }
  }

  /// Requests a new access token if it expires within the given duration.
  Future<void> updateToken([Duration? duration]) async {
    final securedRefreshToken =
        await _secureStorage.read(key: _refreshTokenKey);

    if (securedRefreshToken == null) {
      developer.log('No refresh token found.', name: 'keycloak_wrapper');
      _streamController.add(false);
    } else if (JWT
        .decode(securedRefreshToken)
        .willExpired(duration ?? Duration.zero)) {
      developer.log('Expired refresh token', name: 'keycloak_wrapper');
      _streamController.add(false);
    } else {
      final isConnected = await hasNetwork();

      if (isConnected) {
        tokenResponse = await _appAuth.token(
          TokenRequest(
            _keycloakConfig.clientId,
            _keycloakConfig.redirectUri,
            issuer: _keycloakConfig.issuer,
            scopes: _keycloakConfig.scopes,
            refreshToken: securedRefreshToken,
            allowInsecureConnections: _keycloakConfig.allowInsecureConnections,
            clientSecret: _keycloakConfig.clientSecret,
          ),
        );

        if (tokenResponse.isValid) {
          if (refreshToken != null) {
            await _secureStorage.write(
              key: _refreshTokenKey,
              value: refreshToken,
            );
          }
          _onTokenUpdated(); // <-- Schedule refresh
        } else {
          developer.log('Invalid token response.', name: 'keycloak_wrapper');
        }

        _streamController.add(tokenResponse.isValid);
      } else {
        developer.log('No internet connection.', name: 'keycloak_wrapper');
        _streamController.add(true);
      }
    }
  }

  void _assertInitialization() {
    assert(
      _isInitialized,
      'Make sure the package has been initialized prior to calling this method.',
    );
  }
}
