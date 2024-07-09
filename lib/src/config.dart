part of '../keycloak_wrapper.dart';

/// The configuration class for Keycloak authentication.
///
/// It holds the information that is essential to interact with the Keycloak server.
class KeycloakConfig {
  /// The application unique identifier.
  final String bundleIdentifier;

  /// The alphanumeric ID string that is used in OIDC requests and in the Keycloak database to identify the client.
  final String clientId;

  /// The fixed base URL for frontend requests.
  final String frontendUrl;

  /// The realm name.
  final String realm;

  /// The additional scope values that are used to request Claims.
  final List<String>? additionalScopes;

  KeycloakConfig({
    required this.bundleIdentifier,
    required this.clientId,
    required this.frontendUrl,
    required this.realm,
    this.additionalScopes,
  }) : assert(
          RegExp(r'^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$')
              .hasMatch(bundleIdentifier),
          'Invalid bundle identifier. Must not contain characters that are not allowed inside a hostname, such as spaces, underscores, etc.',
        );

  /// Whether non-HTTPS endpoints are allowed or not.
  bool get allowInsecureConnections => !frontendUrl.startsWith('https://');

  /// The base URI for the authorization server.
  String get issuer => '$frontendUrl/realms/$realm';

  /// The callback URI after the user has been successfully authorized and granted an access token.
  String get redirectUri => '$bundleIdentifier://login-callback';

  /// The identifier for resources that the client wants to access.
  List<String> get scopes => List.from(<String>{
        'openid',
        'profile',
        'offline_access',
        ...?additionalScopes,
      });

  /// The user information endpoint to retrieve user profile data using a valid access token.
  String get userInfoEndpoint => '$issuer/protocol/openid-connect/userinfo';
}
