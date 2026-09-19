import 'package:flutter/foundation.dart';

/// Temporary onboarding state.
///
/// This is NOT a JPA/entity equivalent.
/// It represents the data collected across the member onboarding screens.
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

  /// Local path before the image is uploaded.
  final String? profileImagePath;

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
      specializations: specializations ?? this.specializations,
      openTo: openTo ?? this.openTo,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      headline: headline ?? this.headline,
      city: city ?? this.city,
      country: country ?? this.country,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}