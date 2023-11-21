part of keycloak_wrapper;

// TODO: Implement custom exception
class KeycloakException implements Exception {
  final String message;
  final Uri? uri;

  const KeycloakException(this.message, [this.uri]);
}
