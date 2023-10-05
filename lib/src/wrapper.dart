part of keycloak_wrapper;

class KeycloakWrapper {
  KeycloakWrapper._();

  static KeycloakWrapper? _instance = KeycloakWrapper._();

  // Lazy loading singleton factory constructor.
  factory KeycloakWrapper() => _instance ??= KeycloakWrapper._();

  late final _streamController = StreamController<bool>();

  /// Stream of the user authentication states. Returns true if login is successful.
  Stream<bool> get authenticationStream => _streamController.stream;

  /// Details from making a successful token exchange.
  TokenResponse? tokenResponse;

  /// Called whenever an error gets caught.
  void Function(Object e, StackTrace s) onError = (e, s) => debugPrint('$e');

  /// Returns the payload of the id token.
  Map<String, dynamic>? get idToken => jwtDecode(tokenResponse?.idToken);

  /// Returns the payload of the access token.
  Map<String, dynamic>? get accessToken =>
      jwtDecode(tokenResponse?.accessToken);

  /// Returns the payload of the refresh token.
  Map<String, dynamic>? get refreshToken =>
      jwtDecode(tokenResponse?.refreshToken);

  /// Initializes Keycloak local configuration.
  Future<void> initialize() async {
    try {
      final securedRefreshToken =
          await _secureStorage.read(key: _refreshTokenKey);

      if (securedRefreshToken == null) {
        debugPrint('No refresh token found.');
        _streamController.add(false);
      } else {
        await KeycloakConfig.instance.initialize();

        tokenResponse = await _appAuth.token(TokenRequest(
            KeycloakConfig.instance.clientId,
            KeycloakConfig.instance.redirectUrl,
            issuer: KeycloakConfig.instance.issuer,
            refreshToken: securedRefreshToken,
            allowInsecureConnections: true));

        await _secureStorage.write(
            key: _refreshTokenKey, value: tokenResponse?.refreshToken);

        debugPrint(
            '${tokenResponse.isValid ? 'Valid' : 'Invalid'} refresh token.');

        _streamController.add(tokenResponse.isValid);
      }
    } catch (e, s) {
      debugPrint('An error occured during initialization.');
      onError(e, s);
    }
  }

  /// Logs the user in.
  Future<void> login(KeycloakConfig config) async {
    try {
      tokenResponse = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(config.clientId, config.redirectUrl,
              issuer: config.issuer,
              scopes: ['openid', 'profile', 'email', 'offline_access'],
              promptValues: ['login'],
              allowInsecureConnections: true));

      if (tokenResponse.isValid) {
        if (refreshToken != null) {
          await _secureStorage.write(
              key: _refreshTokenKey, value: tokenResponse!.refreshToken);
        }
      } else {
        debugPrint('Invalid token response.');
      }

      _streamController.add(tokenResponse.isValid);
    } catch (e, s) {
      debugPrint('An error occured during logging user in.');
      onError(e, s);
    }
  }

  /// Logs the user out.
  Future<void> logout() async {
    try {
      final request = EndSessionRequest(
          idTokenHint: tokenResponse?.idToken,
          issuer: KeycloakConfig.instance.issuer,
          postLogoutRedirectUrl: KeycloakConfig.instance.redirectUrl);

      await _appAuth.endSession(request);
      await _secureStorage.deleteAll();

      _streamController.add(false);
    } catch (e, s) {
      debugPrint('An error occured during logging user out.');
      onError(e, s);
    }
  }

  /// Returns current user information retrieved from the Keycloak server.
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final url = Uri.parse(
          '${KeycloakConfig.instance.issuer}/protocol/openid-connect/userinfo');
      final client = HttpClient();
      final request = await client.getUrl(url)
        ..headers.add(HttpHeaders.authorizationHeader,
            'Bearer ${tokenResponse?.accessToken}');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      return jsonDecode(responseBody);
    } catch (e, s) {
      debugPrint('An error occured during fetching user info.');
      onError(e, s);
      return null;
    }
  }
}
