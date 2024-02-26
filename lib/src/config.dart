part of '../keycloak_wrapper.dart';

/// Contains all the configurations required for the authentication requests.
class KeycloakConfig {
  /// Initializes the configuration settings, which are essential for interacting with the Keycloak server.
  factory KeycloakConfig({
    String? bundleIdentifier,
    required String clientId,
    required String frontendUrl,
    required String realm,
    String? redirectUrl,
  }) {
    assert(bundleIdentifier != null || redirectUrl != null,
        'The value of [bundleIdentifier] will be used in case there is no [redirectUrl] given, so one of them needs to be provided.');
    return instance
      ..clientId = clientId
      ..frontendUrl = frontendUrl
      ..realm = realm
      ..redirectUrl = redirectUrl ?? '$bundleIdentifier://login-callback';
  }

  KeycloakConfig._();

  /// The singleton of this class.
  static final KeycloakConfig instance = KeycloakConfig._();

  String? _clientId;

  String? _frontendUrl;

  String? _realm;

  String? _redirectUrl;

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  String get clientId => _clientId ?? '';

  /// The fixed base URL for frontend requests.
  String get frontendUrl => _frontendUrl ?? '';

  /// The realm name.
  String get realm => _realm ?? '';

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUrl => _redirectUrl ?? '';

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  set clientId(String? value) {
    if (value == null) return;
    _clientId = value;
    _secureStorage.write(key: _clientIdKey, value: value);
  }

  set frontendUrl(String? value) {
    if (value == null) return;
    _frontendUrl = value;
    _secureStorage.write(key: _frontendUrlKey, value: value);
  }

  set realm(String? value) {
    if (value == null) return;
    _realm = value;
    _secureStorage.write(key: _realmKey, value: value);
  }

  set redirectUrl(String? value) {
    if (value == null) return;
    _redirectUrl = value;
    _secureStorage.write(key: _redirectUrlKey, value: value);
  }

  /// Initializes Keycloak local configuration.
  Future<void> initialize() async {
    clientId = await _secureStorage.read(key: _clientIdKey);
    frontendUrl = await _secureStorage.read(key: _frontendUrlKey);
    realm = await _secureStorage.read(key: _realmKey);
    redirectUrl = await _secureStorage.read(key: _redirectUrlKey);
  }
}
