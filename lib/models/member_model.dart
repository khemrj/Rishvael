import 'package:flutter/foundation.dart';

import '../core/wire_format.dart';
import 'address.dart';

/// A member profile — what `GET /members/me` and
/// `GET /members/{profileSlug}` return.
@immutable
class Member {
  const Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profileSlug,
    required this.headline,
    required this.bio,
    required this.profilePictureUrl,
    required this.coverPhotoUrl,
    required this.industry,
    required this.openToWork,
    required this.websiteUrl,
    required this.linkedinUrl,
    required this.githubUrl,
    required this.resumeUrl,
    required this.location,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String profileSlug;
  final String headline;
  final String bio;
  final String profilePictureUrl;
  final String coverPhotoUrl;
  final String industry;
  final bool openToWork;
  final String websiteUrl;
  final String linkedinUrl;
  final String githubUrl;
  final String resumeUrl;
  final Address location;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: idToInt(json['id']),
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        profileSlug: json['profileSlug'] as String,
        headline: json['headline'] as String,
        bio: json['bio'] as String,
        profilePictureUrl: json['profilePictureUrl'] as String,
        coverPhotoUrl: json['coverPhotoUrl'] as String,
        industry: json['industry'] as String,
        openToWork: json['openToWork'] as bool,
        websiteUrl: json['websiteUrl'] as String,
        linkedinUrl: json['linkedinUrl'] as String,
        githubUrl: json['githubUrl'] as String,
        resumeUrl: json['resumeUrl'] as String,
        location: Address.fromJson(
          json['location'] as Map<String, dynamic>,
        ),
      );
}

/// Partial-update payload for `PATCH /members/me`.
///
/// Every field is optional — only the fields the member actually
/// wants to update are included in the request.
///
/// This matches the backend's null-means-untouched semantics.
@immutable
class MemberUpdateDraft {
  const MemberUpdateDraft({
    this.firstName,
    this.lastName,
    this.headline,
    this.bio,
    this.profilePictureUrl,
    this.coverPhotoUrl,
    this.industry,
    this.openToWork,
    this.websiteUrl,
    this.linkedinUrl,
    this.githubUrl,
    this.resumeUrl,
    this.location,
  });

  final String? firstName;
  final String? lastName;
  final String? headline;
  final String? bio;
  final String? profilePictureUrl;
  final String? coverPhotoUrl;
  final String? industry;
  final bool? openToWork;
  final String? websiteUrl;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? resumeUrl;
  final Address? location;

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (headline != null) 'headline': headline,
        if (bio != null) 'bio': bio,
        if (profilePictureUrl != null)
          'profilePictureUrl': profilePictureUrl,
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
        if (industry != null) 'industry': industry,
        if (openToWork != null) 'openToWork': openToWork,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
        if (githubUrl != null) 'githubUrl': githubUrl,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (location != null) 'location': location!.toJson(),
      };
}