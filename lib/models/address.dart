import 'package:flutter/foundation.dart';

/// Headquarters / mailing address for a [Business].
///
/// `country`, `state`, and `city` are expected to come from a real
/// Country → State → City picker (e.g. the `csc_picker` package) rather than
/// free typing or a hand-maintained list — see BusinessRegistrationPage.
/// `street` and `postalCode` stay plain free text: formats vary too much
/// by country to validate meaningfully on either side of the wire.
@immutable
class Address {
  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  static const empty = Address(street: '', city: '', state: '', postalCode: '', country: '');

  /// Used to gate form submission — country/state/city are required,
  /// street/postal are encouraged but not blocking.
  bool get isComplete =>
      street.isNotEmpty && city.isNotEmpty && state.isNotEmpty && country.isNotEmpty;

  Address copyWith({
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) =>
      Address(
        street: street ?? this.street,
        city: city ?? this.city,
        state: state ?? this.state,
        postalCode: postalCode ?? this.postalCode,
        country: country ?? this.country,
      );

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: json['street'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        postalCode: json['postalCode'] as String? ?? '',
        country: json['country'] as String? ?? '',
      );
}