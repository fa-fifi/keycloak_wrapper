part of keycloak_wrapper;

class KeycloakUser {
  final String sub;
  final bool emailVerified;
  final String name;
  final String? realm;
  final String preferredUsername;
  final String givenName;
  final String familyName;
  final String email;
  final List<dynamic>? group;

  const KeycloakUser(
      {required this.sub,
      required this.emailVerified,
      required this.name,
      required this.realm,
      required this.preferredUsername,
      required this.givenName,
      required this.familyName,
      required this.email,
      required this.group});

  String get id => sub;

  factory KeycloakUser.fromJson(Map<String, dynamic> json) => KeycloakUser(
      sub: json['sub'],
      emailVerified: json['email_verified'],
      name: json['name'],
      realm: json['realm'],
      preferredUsername: json['preferred_username'],
      givenName: json['given_name'],
      familyName: json['family_name'],
      email: json['email'],
      group: json['group']);

  Map<String, dynamic> toJson() => {
        'sub': sub,
        'email_verified': emailVerified,
        'name': name,
        'realm': realm,
        'preferred_username': preferredUsername,
        'given_name': givenName,
        'family_name': familyName,
        'email': email,
        'group': group,
      };
}
