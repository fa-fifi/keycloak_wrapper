part of '../keycloak_wrapper.dart';

/// Contains all the configurations required for the authentication requests.
class KeycloakConfig {
  KeycloakConfig._();

  /// The singleton of this class.
  static final KeycloakConfig instance = KeycloakConfig._();

  /// Initializes the configuration settings, which are essential for interacting with the Keycloak server.
  factory KeycloakConfig(
          {required String redirectUrl,
          required String clientId,
          required String frontendUrl,
          required String realm}) =>
      instance
        ..redirectUrl = redirectUrl
        ..clientId = clientId
        ..frontendUrl = frontendUrl
        ..realm = realm;

  String? _redirectUrl;

  String? _clientId;

  String? _frontendUrl;

  String? _realm;

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUrl => _redirectUrl ?? '';

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  String get clientId => _clientId ?? '';

  /// The fixed base URL for frontend requests.
  String get frontendUrl => _frontendUrl ?? '';

  /// The realm name.
  String get realm => _realm ?? '';

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  set redirectUrl(String? value) {
    if (value == null) return;
    redirectUrl = value;
    _secureStorage.write(key: _redirectUrlKey, value: value);
  }

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

  /// Initializes Keycloak local configuration.
  Future<void> initialize() async {
    redirectUrl = await _secureStorage.read(key: _redirectUrlKey);
    clientId = await _secureStorage.read(key: _clientIdKey);
    frontendUrl = await _secureStorage.read(key: _frontendUrlKey);
    realm = await _secureStorage.read(key: _realmKey);
  }
}
