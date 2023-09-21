part of keycloak_wrapper;

class KeycloakToken {
  final int exp;
  final int iat;
  final int? authTime;
  final String jti;
  final String iss;
  final String aud;
  final String sub;
  final String typ;
  final String azp;
  final String nonce;
  final String sessionState;
  final String atHash;
  final String acr;
  final String sid;
  final bool emailVerified;
  final String name;
  final String? realm;
  final String preferredUsername;
  final String givenName;
  final String familyName;
  final String email;
  final List<dynamic>? group;

  const KeycloakToken({
    required this.exp,
    required this.iat,
    this.authTime,
    required this.jti,
    required this.iss,
    required this.aud,
    required this.sub,
    required this.typ,
    required this.azp,
    required this.nonce,
    required this.sessionState,
    required this.atHash,
    required this.acr,
    required this.sid,
    required this.emailVerified,
    required this.name,
    required this.realm,
    required this.preferredUsername,
    required this.givenName,
    required this.familyName,
    required this.email,
    required this.group,
  });

  factory KeycloakToken.fromJson(Map<String, dynamic> json) => KeycloakToken(
        exp: json['exp'],
        iat: json['iat'],
        authTime: json['auth_time'],
        jti: json['jti'],
        iss: json['iss'],
        aud: json['aud'],
        sub: json['sub'],
        typ: json['typ'],
        azp: json['azp'],
        nonce: json['nonce'],
        sessionState: json['session_state'],
        atHash: json['at_hash'],
        acr: json['acr'],
        sid: json['sid'],
        emailVerified: json['email_verified'],
        name: json['name'],
        realm: json['realm'],
        preferredUsername: json['preferred_username'],
        givenName: json['given_name'],
        familyName: json['family_name'],
        email: json['email'],
        group: json['group'],
      );

  Map<String, dynamic> toJson() => {
        'exp': exp,
        'iat': iat,
        'auth_time': authTime,
        'jti': jti,
        'iss': iss,
        'aud': aud,
        'sub': sub,
        'typ': typ,
        'azp': azp,
        'nonce': nonce,
        'session_state': sessionState,
        'at_hash': atHash,
        'acr': acr,
        'sid': sid,
        'email_verified': emailVerified,
        'name': name,
        'realm': realm,
        'preferred_username': preferredUsername,
        'given_name': givenName,
        'family_name': familyName,
        'email': email,
        'group': group
      };
}
