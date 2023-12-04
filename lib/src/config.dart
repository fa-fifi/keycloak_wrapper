part of keycloak_wrapper;

class KeycloakConfig {
  KeycloakConfig._();

  static final KeycloakConfig instance = KeycloakConfig._();

  /// Initializes the configuration settings such as
  /// [bundleIdentifier], [clientId], [frontendUrl], and [realm]. These settings
  /// are essential for interacting with the Keycloak server during the
  /// authentication process.
  factory KeycloakConfig(
          {required String bundleIdentifier,
          required String clientId,
          required String frontendUrl,
          required String realm}) =>
      instance
        ..bundleIdentifier = bundleIdentifier
        ..clientId = clientId
        ..frontendUrl = frontendUrl
        ..realm = realm;

  String? _bundleIdentifier;

  String? _clientId;

  String? _frontendUrl;

  String? _realm;

  /// The application unique identifier.
  String get bundleIdentifier => _bundleIdentifier ?? '';

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  String get clientId => _clientId ?? '';

  /// The fixed base URL for frontend requests.
  String get frontendUrl => _frontendUrl ?? '';

  /// The realm name.
  String get realm => _realm ?? '';

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUri => '$_bundleIdentifier://login-callback';

  /// The application unique identifier.
  set bundleIdentifier(String? value) {
    if (value == null) return;
    _bundleIdentifier = value;
    _secureStorage.write(key: _bundleIdentifierKey, value: value);
  }

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  set clientId(String? value) {
    if (value == null) return;
    _clientId = value;
    _secureStorage.write(key: _clientIdKey, value: value);
  }

  /// The fixed base URL for frontend requests.
  set frontendUrl(String? value) {
    if (value == null) return;
    _frontendUrl = value;
    _secureStorage.write(key: _frontendUrlKey, value: value);
  }

  /// The realm name.
  set realm(String? value) {
    if (value == null) return;
    _realm = value;
    _secureStorage.write(key: _realmKey, value: value);
  }

  /// Initializes Keycloak local configuration.
  Future<void> initialize() async {
    bundleIdentifier = await _secureStorage.read(key: _bundleIdentifierKey);
    clientId = await _secureStorage.read(key: _clientIdKey);
    frontendUrl = await _secureStorage.read(key: _frontendUrlKey);
    realm = await _secureStorage.read(key: _realmKey);
  }
}
