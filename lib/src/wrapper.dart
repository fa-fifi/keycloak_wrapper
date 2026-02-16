part of '../keycloak_wrapper.dart';

/// A wrapper around the Keycloak authentication service.
///
/// Provides functionalities for user authentication, token management, and resource authorization.
class KeycloakWrapper {
  static KeycloakWrapper? _instance;

  bool _isInitialized = false;

  late KeycloakConfig _keycloakConfig;

  Timer? _refreshTimer;

  TokenResponse? _tokenResponse;

  late final _streamController = StreamController<bool>.broadcast();

  /// Called whenever an error gets caught.
  ///
  /// By default, all errors will be printed into the console.
  void Function(String message, Object error, StackTrace stackTrace) onError =
      (message, error, stackTrace) => developer.log(
            message,
            name: _packageName,
            error: error,
            stackTrace: stackTrace,
          );

  factory KeycloakWrapper() => _instance ??= KeycloakWrapper._();

  KeycloakWrapper._();

  /// Returns the access token string.
  ///
  /// To get the payload, use `JWT.decode(keycloakWrapper.accessToken).payload`.
  String? get accessToken => _tokenResponse?.accessToken;

  /// The stream of the user authentication state.
  ///
  /// Emits `true` when the user is authenticated, `false` otherwise.
  Stream<bool> get authenticationStream => _streamController.stream;

  /// Returns the ID token string.
  ///
  /// To get the payload, use `JWT.decode(keycloakWrapper.idToken).payload`.
  String? get idToken => _tokenResponse?.idToken;

  /// Whether this package has been initialized.
  bool get isInitialized => _isInitialized;

  /// Returns the refresh token string.
  ///
  /// To get the payload, use `JWT.decode(keycloakWrapper.refreshToken).payload`.
  String? get refreshToken => _tokenResponse?.refreshToken;

  /// Disposes of resources used by this wrapper.
  ///
  /// Should be called when the wrapper is no longer needed.
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _streamController.close();
    _instance = null;
  }

  /// Exchanges the refresh token for new access and ID tokens.
  ///
  /// If [duration] is provided, only refreshes if the refresh token will
  /// expire within that duration.
  Future<void> exchangeTokens([Duration? duration]) async {
    try {
      final securedRefreshToken =
          await _secureStorage.read(key: _refreshTokenKey);

      if (securedRefreshToken == null) {
        developer.log('No refresh token found.', name: _packageName);
        _streamController.add(false);
      } else if (JWT
          .decode(securedRefreshToken)
          .hasExpired(duration ?? Duration.zero)) {
        developer.log('Refresh token expired.', name: _packageName);
        _streamController.add(false);
      } else {
        final isConnected = await hasNetwork();

        if (isConnected) {
          _tokenResponse = await _appAuth.token(
            TokenRequest(
              _keycloakConfig.clientId,
              _keycloakConfig.redirectUri,
              issuer: _keycloakConfig.issuer,
              scopes: _keycloakConfig.scopes,
              refreshToken: securedRefreshToken,
              allowInsecureConnections:
                  _keycloakConfig.allowInsecureConnections,
              clientSecret: _keycloakConfig.clientSecret,
            ),
          );

          if (_tokenResponse.isValid) {
            if (refreshToken != null) {
              await _secureStorage.write(
                key: _refreshTokenKey,
                value: refreshToken,
              );
            }
            _onTokenUpdated();
          } else {
            developer.log('Invalid token response.', name: _packageName);
          }

          _streamController.add(_tokenResponse.isValid);
        } else {
          developer.log('No internet connection.', name: _packageName);
          _streamController.add(true); // Still authenticated, just offline.
        }
      }
    } catch (e, s) {
      _handleError('Failed to exchange tokens.', e, s);
      _streamController.add(false);
    }
  }

  /// Retrieves the current user information from Keycloak.
  ///
  /// Returns a map containing user profile data, or `null` if the request fails.
  Future<Map<String, dynamic>?> getUserInfo() async {
    _assertInitialization();
    final client = HttpClient();

    try {
      final url = Uri.parse(_keycloakConfig.userInfoEndpoint);
      final request = await client.getUrl(url)
        ..headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return jsonDecode(responseBody) as Map<String, dynamic>?;
    } catch (e, s) {
      _handleError('Failed to fetch user info.', e, s);
      return null;
    } finally {
      client.close();
    }
  }

  /// Initializes the Keycloak wrapper with the provided configuration.
  ///
  /// Must be called before any other methods. Automatically attempts to
  /// restore the user's session if a valid refresh token exists.
  Future<void> initialize({required KeycloakConfig config}) async {
    _keycloakConfig = config;

    try {
      final prefs = SharedPreferencesAsync();
      final hasRunBefore = await prefs.getBool(_hasRunBeforeKey) ?? false;

      if (!hasRunBefore) {
        _secureStorage.deleteAll();
        prefs.setBool(_hasRunBeforeKey, true);
      }

      _isInitialized = true;
      await exchangeTokens();
    } catch (e, s) {
      _isInitialized = false;
      _handleError('Failed to initialize plugin.', e, s);
      rethrow; // Let caller know initialization failed.
    }
  }

  /// Logs the user in.
  ///
  /// Returns `true` if login is successful, `false` otherwise.
  Future<bool> login() async {
    _assertInitialization();

    try {
      _tokenResponse = await _appAuth.authorizeAndExchangeCode(
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

      if (_tokenResponse.isValid) {
        if (refreshToken != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: refreshToken,
          );
        }
        _onTokenUpdated();
      } else {
        developer.log('Invalid token response.', name: _packageName);
      }

      _streamController.add(_tokenResponse.isValid);
      return _tokenResponse.isValid;
    } catch (e, s) {
      _handleError('Failed to login.', e, s);
      return false;
    }
  }

  /// Logs the user out.
  ///
  /// Returns `true` if logout is successful, `false` otherwise.
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
      _tokenResponse = null;
      _refreshTimer?.cancel();
      _refreshTimer = null;
      _streamController.add(false);
      return true;
    } catch (e, s) {
      _handleError('Failed to logout.', e, s);
      return false;
    }
  }

  void _assertInitialization() {
    if (!_isInitialized) {
      throw StateError(
        'Make sure the package has been initialized prior to calling this method.',
      );
    }
  }

  void _handleError(String message, Object error, StackTrace stackTrace) {
    onError.call(message, error, stackTrace);

    if (error is PlatformException && error.code == 'token_failed') {
      // Token exchange failed, reset and reinitialize.
      final prefs = SharedPreferencesAsync();
      prefs.setBool(_hasRunBeforeKey, false);
      initialize(config: _keycloakConfig);
    }
  }

  void _onTokenUpdated() {
    developer.log('Token updated.');
    _scheduleTokenRefresh();
  }

  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    if (!_tokenResponse.isValid) return;

    Duration? refreshDuration;

    if (accessToken != null) {
      final jwt = JWT.decode(accessToken!);
      final remainingTime = jwt.remainingTime;

      if (remainingTime != null && remainingTime.inSeconds > 0) {
        // Refresh 1 minute before expiry, but at least 5 seconds from now
        final refreshIn = remainingTime - const Duration(minutes: 1);
        refreshDuration = refreshIn > const Duration(seconds: 5)
            ? refreshIn
            : const Duration(seconds: 5);
      }
    }

    if ((refreshDuration == null || refreshDuration.inSeconds <= 0) &&
        refreshToken != null) {
      final jwt = JWT.decode(refreshToken!);
      final remainingTime = jwt.remainingTime;

      if (remainingTime != null && remainingTime.inSeconds > 0) {
        // Refresh soon if we're relying on refresh token timing
        refreshDuration = const Duration(seconds: 5);
      }
    }

    if (refreshDuration == null) return;

    developer.log('refreshDuration $refreshDuration');

    _refreshTimer = Timer(refreshDuration, () async {
      await exchangeTokens();
    });
  }
}
