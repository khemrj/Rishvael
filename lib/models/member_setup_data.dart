import 'package:flutter/foundation.dart';

/// Temporary onboarding state.
///
/// This represents the minimum information collected during
/// member onboarding.
///
/// It is NOT a JPA/entity equivalent.
@immutable
class MemberSetupData {
  const MemberSetupData({
    this.specializations = const {},
    this.openTo = const {},
    this.firstName,
    this.lastName,
    this.headline,
    this.city,
    this.country,
    this.profileImagePath,
  });

  final Set<String> specializations;
  final Set<String> openTo;

  final String? firstName;
  final String? lastName;
  final String? headline;

  final String? city;
  final String? country;

  /// Local device path before the image is uploaded.
  final String? profileImagePath;

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'specializations': specializations.toList(),
      'openTo': openTo.toList(),
      'firstName': firstName,
      'lastName': lastName,
      'headline': headline,
      'city': city,
      'country': country,
      'profileImagePath': profileImagePath,
    };
  }

  factory MemberSetupData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MemberSetupData(
      specializations: _stringSet(
        json['specializations'],
      ),
      openTo: _stringSet(
        json['openTo'],
      ),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      headline: json['headline'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      profileImagePath:
          json['profileImagePath'] as String?,
    );
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) {
      return const {};
    }

    return value
        .whereType<String>()
        .toSet();
  }

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------

  MemberSetupData copyWith({
    Set<String>? specializations,
    Set<String>? openTo,
    String? firstName,
    String? lastName,
    String? headline,
    String? city,
    String? country,
    String? profileImagePath,
  }) {
    return MemberSetupData(
      specializations:
          specializations ?? this.specializations,
      openTo: openTo ?? this.openTo,
      firstName:
          firstName ?? this.firstName,
      lastName:
          lastName ?? this.lastName,
      headline:
          headline ?? this.headline,
      city:
          city ?? this.city,
      country:
          country ?? this.country,
      profileImagePath:
          profileImagePath ?? this.profileImagePath,
    );
  }
}