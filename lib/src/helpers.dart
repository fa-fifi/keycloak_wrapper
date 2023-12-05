part of '../keycloak_wrapper.dart';

/// Extension of the [TokenResponse] class from flutter_appauth package.
extension TokenResponseHelper on TokenResponse? {
  /// Checks the validity of the token response.
  bool get isValid =>
      this == null ? false : this?.accessToken != null && this?.idToken != null;
}

/// Parses the JSON Web Token and returns its payload.
Map<String, dynamic>? jwtDecode(String? source) => jsonDecode(utf8
    .decode(base64Url.decode(base64Url.normalize('$source'.split('.')[1]))));
