part of '../keycloak_wrapper.dart';

/// Contains all the configurations required for the authentication requests.
class KeycloakConfig {
  /// The singleton of this class.
  static final KeycloakConfig instance = KeycloakConfig._();

  String? _bundleIdentifier;

  String? _clientId;

  String? _frontendUrl;

  String? _realm;

  /// Initializes the configuration settings, which are essential for interacting with the Keycloak server.
  factory KeycloakConfig({
    required String bundleIdentifier,
    required String clientId,
    required String frontendUrl,
    required String realm,
  }) {
    assert(
      RegExp(r'^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$')
          .hasMatch(bundleIdentifier),
      'Invalid bundle identifier. Must not contain characters that are not allowed inside a hostname, such as spaces, underscores, etc.',
    );
    return instance
      ..bundleIdentifier = bundleIdentifier
      ..clientId = clientId
      ..frontendUrl = frontendUrl
      ..realm = realm;
  }

  KeycloakConfig._();

  /// The application unique identifier.
  String get bundleIdentifier => _bundleIdentifier ?? '';

  set bundleIdentifier(String? value) {
    if (value == null) return;
    _bundleIdentifier = value;
    _secureStorage.write(key: _bundleIdentifierKey, value: value);
  }

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  String get clientId => _clientId ?? '';

  set clientId(String? value) {
    if (value == null) return;
    _clientId = value;
    _secureStorage.write(key: _clientIdKey, value: value);
  }

  /// The fixed base URL for frontend requests.
  String get frontendUrl => _frontendUrl ?? '';

  set frontendUrl(String? value) {
    if (value == null) return;
    _frontendUrl = value;
    _secureStorage.write(key: _frontendUrlKey, value: value);
  }

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  /// The realm name.
  String get realm => _realm ?? '';

  set realm(String? value) {
    if (value == null) return;
    _realm = value;
    _secureStorage.write(key: _realmKey, value: value);
  }

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUri => '$_bundleIdentifier://login-callback';

  /// Initializes Keycloak local configuration.
  Future<void> initialize() async {
    bundleIdentifier = await _secureStorage.read(key: _bundleIdentifierKey);
    clientId = await _secureStorage.read(key: _clientIdKey);
    frontendUrl = await _secureStorage.read(key: _frontendUrlKey);
    realm = await _secureStorage.read(key: _realmKey);
  }
}
