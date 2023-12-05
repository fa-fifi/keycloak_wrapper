part of '../keycloak_wrapper.dart';

// TODO: Implement custom exception

/// Thrown whenever an error occurs during authentication process.
class KeycloakException implements Exception {
  final String message;
  final Uri? uri;

  const KeycloakException(this.message, [this.uri]);
}
