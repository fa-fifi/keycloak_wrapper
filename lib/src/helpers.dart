part of '../keycloak_wrapper.dart';

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

/// Extension of the [TokenResponse] class from flutter_appauth package.
extension TokenResponseHelper on TokenResponse? {
  /// Checks the validity of the token response.
  bool get isValid =>
      this != null && this?.accessToken != null && this?.idToken != null;
}
