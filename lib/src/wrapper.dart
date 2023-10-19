part of keycloak_wrapper;

class KeycloakWrapper {
  KeycloakWrapper._();

  static KeycloakWrapper? _instance = KeycloakWrapper._();

  factory KeycloakWrapper() => _instance ??= KeycloakWrapper._();

  late final _streamController = StreamController<bool>();

  /// Stream of the user authentication state. Returns true if login is successful.
  Stream<bool> get authenticationStream => _streamController.stream;

  /// Details from making a successful token exchange.
  TokenResponse? tokenResponse;

  /// Called whenever an error gets caught. By default, all errors will be printed into the console.
  void Function(Object e, StackTrace s) onError = (e, s) => debugPrint('$e');

  /// Returns the payload of the id token.
  Map<String, dynamic>? get idToken => jwtDecode(tokenResponse?.idToken);

  /// Returns the payload of the access token.
  Map<String, dynamic>? get accessToken =>
      jwtDecode(tokenResponse?.accessToken);

  /// Returns the payload of the refresh token.
  Map<String, dynamic>? get refreshToken =>
      jwtDecode(tokenResponse?.refreshToken);

  /// Initializes the user authentication state and refresh token.
  Future<void> initialize() async {
    try {
      final securedRefreshToken =
          await _secureStorage.read(key: _refreshTokenKey);

      if (securedRefreshToken == null) {
        debugPrint('No refresh token found.');
        _streamController.add(false);
      } else {
        await KeycloakConfig.instance.initialize();

        final host = Uri.parse(KeycloakConfig.instance.issuer).host;
        final isConnected = await hasNetwork(host);

        if (isConnected) {
          tokenResponse = await _appAuth.token(TokenRequest(
              KeycloakConfig.instance.clientId,
              KeycloakConfig.instance.redirectUri,
              issuer: KeycloakConfig.instance.issuer,
              refreshToken: securedRefreshToken,
              allowInsecureConnections: true));

          await _secureStorage.write(
              key: _refreshTokenKey, value: tokenResponse?.refreshToken);

          debugPrint(
              '${tokenResponse.isValid ? 'Valid' : 'Invalid'} refresh token.');

          _streamController.add(tokenResponse.isValid);
        } else {
          _streamController.add(true);
        }
      }
    } catch (e, s) {
      debugPrint('An error occured during initialization.');
      onError(e, s);
    }
  }

  /// Checks if there is network connectivity.
  Future<bool> hasNetwork([String host = 'google.com']) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  /// Logs the user in. Returns true if login is successful.
  Future<bool> login(KeycloakConfig config) async {
    try {
      tokenResponse = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(config.clientId, config.redirectUri,
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
      return tokenResponse.isValid;
    } catch (e, s) {
      debugPrint('An error occured during logging user in.');
      onError(e, s);
      return false;
    }
  }

  /// Logs the user out. Returns true if logout is successful.
  Future<bool> logout() async {
    try {
      final request = EndSessionRequest(
          idTokenHint: tokenResponse?.idToken,
          issuer: KeycloakConfig.instance.issuer,
          postLogoutRedirectUrl: KeycloakConfig.instance.redirectUri);

      await _appAuth.endSession(request);
      await _secureStorage.deleteAll();

      _streamController.add(false);
      return true;
    } catch (e, s) {
      debugPrint('An error occured during logging user out.');
      onError(e, s);
      return false;
    }
  }

  /// Retrieves the current user information.
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
