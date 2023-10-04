part of keycloak_wrapper;

class KeycloakConfig {
  KeycloakConfig._();

  static final KeycloakConfig instance = KeycloakConfig._();

  factory KeycloakConfig({
    required String bundleIdentifier,
    required String clientId,
    required String domain,
    required String realm,
  }) {
    instance.bundleIdentifier = bundleIdentifier;
    instance.clientId = clientId;
    instance.domain = domain;
    instance.realm = realm;
    return instance;
  }

  String? _bundleIdentifier;

  String? _clientId;

  String? _domain;

  String? _realm;

  String get bundleIdentifier => _bundleIdentifier ?? '';

  String get clientId => _clientId ?? '';

  String get domain => _domain ?? '';

  String get realm => _realm ?? '';

  String get issuer => 'http://$domain/realms/$realm';

  String get redirectUrl => '$_bundleIdentifier://login-callback';

  set bundleIdentifier(String? value) {
    if (value == null) return;
    _bundleIdentifier = value;
    _secureStorage.write(key: _bundleIdentifierKey, value: value);
  }

  set clientId(String? value) {
    if (value == null) return;
    _clientId = value;
    _secureStorage.write(key: _clientIdKey, value: value);
  }

  set domain(String? value) {
    if (value == null) return;
    _domain = value;
    _secureStorage.write(key: _domainKey, value: value);
  }

  set realm(String? value) {
    if (value == null) return;
    _realm = value;
    _secureStorage.write(key: _realmKey, value: value);
  }

  Future<void> initialize() async {
    bundleIdentifier = await _secureStorage.read(key: _bundleIdentifierKey);
    clientId = await _secureStorage.read(key: _clientIdKey);
    domain = await _secureStorage.read(key: _domainKey);
    realm = await _secureStorage.read(key: _realmKey);
  }
}
