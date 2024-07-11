part of '../keycloak_wrapper.dart';

/// Manages user authentication and token exchange using Keycloak.
///
/// It uses [KeycloakConfig] for configuration settings and relies on `flutter_appauth` package for OAuth2 authorization.
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

  /// Returns the access token string.
  ///
  /// To get the payload, do `JWT.decode(KeycloakWrapper().accessToken).payload`.
  String? get accessToken => tokenResponse?.accessToken;

  /// The stream of the user authentication state.
  ///
  /// Returns true if the user is currently logged in.
  Stream<bool> get authenticationStream => _streamController.stream;

  /// Returns the id token string.
  ///
  /// To get the payload, do `JWT.decode(KeycloakWrapper().idToken).payload`.
  String? get idToken => tokenResponse?.idToken;

  /// Whether this package has been initialized.
  bool get isInitialized => _isInitialized;

  /// Returns the refresh token string.
  ///
  /// To get the payload, do `JWT.decode(KeycloakWrapper().refreshToken).payload`.
  String? get refreshToken => tokenResponse?.refreshToken;

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
    try {
      await updateToken();
      _isInitialized = true;
    } catch (e, s) {
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
      _streamController.add(false);
      return true;
    } catch (e, s) {
      onError('Failed to logout.', e, s);
      return false;
    }
  }

  /// Requests a new access token before it expires.
  Future<void> updateToken() async {
    final securedRefreshToken =
        await _secureStorage.read(key: _refreshTokenKey);

    if (securedRefreshToken == null) {
      developer.log('No refresh token found.', name: 'keycloak_wrapper');
      _streamController.add(false);
    } else if (JWT.decode(securedRefreshToken).isExpired) {
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
