part of '../keycloak_wrapper.dart';

/// Your Keycloak client configuration class.
///
/// Holds essential details required for integrating with a Keycloak server.
class KeycloakConfig {
  /// The application unique identifier.
  final String bundleIdentifier;

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  final String clientId;

  /// The fixed base URL for frontend requests.
  final String frontendUrl;

  /// The realm name.
  final String realm;

  /// The client's password to prove its identity to the Keycloak server.
  final String? clientSecret;

  /// The optional scope values that are used to request claims.
  final List<String>? _additionalScopes;

  /// Whether non-HTTPS endpoints are allowed or not.
  final bool allowInsecureConnections;

  /// The external user-agent to use on iOS and macOS.
  final ExternalUserAgent externalUserAgent;

  KeycloakConfig({
    required this.bundleIdentifier,
    required this.clientId,
    required this.frontendUrl,
    required this.realm,
    this.clientSecret,
    List<String>? additionalScopes,
    bool? allowInsecureConnections,
    this.externalUserAgent = ExternalUserAgent.asWebAuthenticationSession,
  })  : _additionalScopes = additionalScopes != null
            ? List.unmodifiable(additionalScopes)
            : null,
        allowInsecureConnections =
            allowInsecureConnections ?? !frontendUrl.startsWith('https://'),
        assert(
          RegExp(r'^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*$')
              .hasMatch(bundleIdentifier),
          'Invalid bundle identifier: must be a valid hostname (no spaces, underscores, etc.).',
        );

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUri => '$bundleIdentifier://login-callback';

  /// The identifier for resources that the client wants to access.
  List<String> get scopes => List.unmodifiable(<String>{
        'openid',
        ...?_additionalScopes,
      });

  /// The user information endpoint to retrieve user profile data using a valid access token.
  String get userInfoEndpoint => '$issuer/protocol/openid-connect/userinfo';
}
