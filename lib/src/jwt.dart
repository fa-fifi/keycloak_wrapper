part of '../keycloak_wrapper.dart';

/// A JSON Web Token class.
///
/// The industry standard method for representing claims securely between two parties.
class JWT {
  /// The encoded JSON Web Token string.
  final String token;

  /// Cached decoded payload to avoid repeated parsing.
  Map<String, dynamic>? _cachedPayload;

  /// Decodes a JSON Web Token string.
  ///
  /// Throws [ArgumentError] if the token format is invalid.
  JWT.decode(this.token) {
    if (token.split('.').length != 3) {
      throw ArgumentError(
          'Invalid token: JWT consists of 3 parts (header, payload, signature) separated by dots.');
    }
  }

  /// Returns the token payload.
  ///
  /// Throws [FormatException] if the payload cannot be encoded.
  Map<String, dynamic> get payload {
    if (_cachedPayload != null) return _cachedPayload!;

    try {
      final payloadBase64 = token.split('.')[1];
      final normalizedPayload = base64Url.normalize(payloadBase64);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final decodedPayload = jsonDecode(payloadString) as Map<String, dynamic>;

      _cachedPayload = decodedPayload;
      return decodedPayload;
    } catch (e) {
      throw FormatException('Invalid payload: $e');
    }
  }

  /// Returns the token expiration date.
  ///
  /// Returns `null` if the 'exp' claim is not present.
  /// Throws [FormatException] if the payload is invalid.
  DateTime? get expirationDate {
    final exp = payload['exp'];

    if (exp == null) return null;

    // Handle both int and double (some JWT libraries use double)
    final expSeconds = exp is int ? exp : (exp as num).toInt();
    return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
  }

  /// Returns the token issuing date.
  ///
  /// Returns `null` if the 'iat' claim is not present.
  /// Throws [FormatException] if the payload is invalid.
  DateTime? get issuedAt {
    final iat = payload['iat'];

    if (iat == null) return null;

    final iatSeconds = iat is int ? iat : (iat as num).toInt();
    return DateTime.fromMillisecondsSinceEpoch(iatSeconds * 1000, isUtc: true);
  }

  /// Whether the token has expired.
  ///
  /// Returns `false` if there is no expiration date.
  /// Throws [FormatException] if the payload is invalid.
  bool get isExpired => hasExpired();

  /// Returns the remaining time until expiry date.
  ///
  /// Returns `null` if there is no expiration date.
  /// Returns negative duration if already expired.
  /// Throws [FormatException] if the payload is invalid.
  Duration? get remainingTime {
    if (expirationDate == null) return null;
    return expirationDate?.difference(DateTime.now());
  }

  /// Checks whether the token has expired or will expire within the given duration.
  ///
  /// Example:
  /// ```dart
  /// jwt.hasExpired(); // Check if already expired
  /// jwt.hasExpired(Duration(minutes: 5)); // Check if expires within 5 minutes
  /// ```
  ///
  /// Throws [FormatException] if the payload is invalid.
  bool hasExpired([Duration buffer = Duration.zero]) {
    if (expirationDate == null) return false;

    return DateTime.now().toUtc().isAfter(expirationDate!.subtract(buffer));
  }
}
