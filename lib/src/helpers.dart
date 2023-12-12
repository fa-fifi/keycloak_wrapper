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

/// Whether there is network connectivity.
Future<bool> hasNetwork() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  }
}

/// Sends a GET request with Bearer Token authorization header.
Future<dynamic> getWithBearerAuthentication(
    Uri uri, String? accessToken) async {
  final client = HttpClient();
  final request = await client.getUrl(uri)
    ..headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  client.close();

  return jsonDecode(responseBody);
}
