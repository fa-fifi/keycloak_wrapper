part of keycloak_wrapper;

final class KeycloakConfig {
  final String bundleIdentifier;
  final String clientId;
  final String domain;
  final String realm;

  const KeycloakConfig(
      {required this.bundleIdentifier,
      required this.clientId,
      required this.domain,
      required this.realm});

  String get issuer => 'http://$domain/realms/$realm';

  String get redirectUrl => '$bundleIdentifier://login-callback';
}
