part of '../keycloak_wrapper.dart';

/// Checks whether there is network connectivity.
///
/// Returns `true` if the device can reach the internet, `false` otherwise.
/// This performs a DNS lookup to verify connectivity.
Future<bool> hasNetwork() async {
  try {
    final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
        onTimeout: () => <InternetAddress>[]);

    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (e) {
    developer.log('Failed to connect to the internet.',
        name: _packageName, error: e);
    return false;
  }
}

/// Extension of the [TokenResponse] class from flutter_appauth package.
extension TokenResponseHelper on TokenResponse? {
  /// Checks whether the token response is valid.
  ///
  /// Returns `true` if the response is non-null and contains both
  /// an access token and an ID token.
  bool get isValid =>
      this != null && this?.accessToken != null && this?.idToken != null;
}
