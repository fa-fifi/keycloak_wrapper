part of '../keycloak_wrapper.dart';

/// An open, industry standard method for representing claims securely between two parties.
class JWT {
  /// The encoded JSON Web Token string.
  final String token;

  /// Decodes a JSON Web Token string.
  JWT.decode(this.token)
      : assert(token.split('.').length == 3, 'Invalid token.');

  /// Returns the token expiration date.
  ///
  /// Throws [FormatException] if the payload is invalid.
  DateTime? get expirationDate {
    final exp = payload['exp'] as int?;

    if (exp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Whether the token has expired or not.
  ///
  /// Throws [FormatException] if the payload is invalid.
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Returns the token issuing date.
  ///
  /// Throws [FormatException] if the payload is invalid.
  DateTime? get issuedAt {
    final iat = payload['iat'] as int?;

    if (iat == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
  }

  /// Returns the token payload.
  ///
  /// Throws [FormatException] if the payload is invalid.
  Map<String, dynamic> get payload {
    try {
      final payloadBase64 = token.split('.')[1];
      final normalizedPayload = base64Url.normalize(payloadBase64);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final decodedPayload = jsonDecode(payloadString) as Map<String, dynamic>;

      return decodedPayload;
    } catch (_) {
      throw const FormatException('Invalid payload.');
    }
  }

  /// Returns the remaining time until expiry date.
  ///
  /// Throws [FormatException] if the payload is invalid.
  Duration? get remainingTime {
    if (expirationDate == null) return null;
    return expirationDate?.difference(DateTime.now());
  }
}
