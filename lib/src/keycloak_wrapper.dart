part of keycloak_wrapper;

class KeycloakWrapper {
  static const _appAuth = FlutterAppAuth();

  static Future<void> login(KeycloakConfig config) async {
    // Create request
    final authorizationTokenRequest = AuthorizationTokenRequest(
        config.clientId, config.redirectUrl,
        issuer: config.issuer,
        scopes: ['openid', 'profile', 'email', 'offline_access'],
        promptValues: ['login'],
        allowInsecureConnections: true);

    // Call Keycloak for authorize and exchange code
    final result =
        await _appAuth.authorizeAndExchangeCode(authorizationTokenRequest);

    debugPrint('Result: $result');
  }
}
