part of '../keycloak_wrapper.dart';

/// Extension of the [TokenResponse] class from flutter_appauth package.
extension TokenResponseHelper on TokenResponse? {
  /// Checks the validity of the token response.
  bool get isValid =>
      this != null && this?.accessToken != null && this?.idToken != null;
}

/// Parses the JSON Web Token and returns its payload.
@Deprecated('Use `JWT.decode(token).payload` instead. '
    'This feature will be removed in the next minor update.')
Map<String, dynamic>? jwtDecode(String? token) {
  final codeUnits =
      base64Url.decode(base64Url.normalize('$token'.split('.')[1]));

  return jsonDecode(utf8.decode(codeUnits)) as Map<String, dynamic>?;
}

/// Whether there is network connectivity.
Future<bool> hasNetwork() async {
  try {
    final result = await InternetAddress.lookup('example.com');

    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    developer.log(
      'Failed to connect to the internet.',
      name: 'keycloak_wrapper',
    );
    return false;
  }
}
