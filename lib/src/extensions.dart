part of keycloak_wrapper;

extension TokenResponseHelper on TokenResponse? {
  /// Checks the validation of the token response.
  bool get isValid =>
      this == null ? false : this?.accessToken != null && this?.idToken != null;
}

/// Parses the JSON web token and returns its payload.
Map<String, dynamic>? jwtDecode(String? source) => jsonDecode(utf8
    .decode(base64Url.decode(base64Url.normalize('$source'.split('.')[1]))));
