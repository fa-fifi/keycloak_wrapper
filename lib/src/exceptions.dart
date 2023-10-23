part of keycloak_wrapper;

// TODO: Implements custom exception.
class KeycloakException implements Exception {
  final String message;
  final Uri? uri;

  const KeycloakException(this.message, [this.uri]);
}
