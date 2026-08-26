import 'package:flutter/foundation.dart';

import '../core/wire_format.dart';
import 'address.dart';

/// Mirrors the backend's `IndustryType` enum on the `Business` entity.
/// (Kept separate from `FinanceSpecialization` for now since that's what's
/// already wired into Business.java/BusinessController — worth considering
/// consolidating the two taxonomies later since a firm's industry and the
/// specializations it hires for usually describe the same thing.)
enum IndustryType {
  investmentBanking('Investment Banking'),
  wealthManagement('Wealth Management'),
  hedgeFund('Hedge Fund'),
  insurance('Insurance'),
  fintech('FinTech'),
  accounting('Accounting'),
  consulting('Consulting'),
  other('Other');

  const IndustryType(this.label);
  final String label;
}

enum CompanySize {
  startup('Startup'),
  small('Small (1-50)'),
  medium('Medium (51-250)'),
  large('Large (251-1000)'),
  enterprise('Enterprise (1000+)');

  const CompanySize(this.label);
  final String label;
}

enum VerificationStatus { pending, verified, rejected }

enum BusinessStatus { active, suspended, deactivated }

/// A verified (or pending) business/firm profile — what `GET /businesses/me`
/// and `GET /businesses/{id}` return.
@immutable
class Business {
  const Business({
    required this.id,
    required this.companyName,
    required this.registrationNumber,
    required this.industryType,
    this.companySize,
    this.website,
    this.description,
    this.logoUrl,
    required this.headquarters,
    required this.contactEmail,
    this.contactPhone,
    required this.verificationStatus,
    this.verifiedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String companyName;
  final String registrationNumber;
  final IndustryType industryType;
  final CompanySize? companySize;
  final String? website;
  final String? description;
  final String? logoUrl;
  final Address headquarters;
  final String contactEmail;
  final String? contactPhone;
  final VerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final BusinessStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Drives the "Post Opportunity" gate client-side — mirrors the exact
  /// check OpportunityController does server-side, so the UI never shows an
  /// action the API would reject anyway.
  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get canPostOpportunities => isVerified && status == BusinessStatus.active;

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: idToInt(json['id']),
        companyName: json['companyName'] as String,
        registrationNumber: json['registrationNumber'] as String,
        industryType: IndustryType.values.byName(fromWireEnum(json['industryType'] as String)),
        companySize: json['companySize'] == null
            ? null
            : CompanySize.values.byName(fromWireEnum(json['companySize'] as String)),
        website: json['website'] as String?,
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        headquarters: Address.fromJson(json['headquarters'] as Map<String, dynamic>),
        contactEmail: json['contactEmail'] as String,
        contactPhone: json['contactPhone'] as String?,
        verificationStatus:
            VerificationStatus.values.byName(fromWireEnum(json['verificationStatus'] as String)),
        verifiedAt:
            json['verifiedAt'] == null ? null : DateTime.parse(json['verifiedAt'] as String),
        status: BusinessStatus.values.byName(fromWireEnum(json['status'] as String)),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// The payload the registration form builds — deliberately separate from
/// [Business], same reasoning as OpportunityDraft: this doesn't know its own
/// id or verificationStatus, the backend assigns those.
@immutable
class BusinessRegistrationDraft {
  const BusinessRegistrationDraft({
    required this.email,
    required this.password,
    required this.companyName,
    required this.registrationNumber,
    required this.industryType,
    this.companySize,
    this.website,
    this.description,
    required this.headquarters,
    required this.contactEmail,
    this.contactPhone,
  });

  final String email;
  final String password;
  final String companyName;
  final String registrationNumber;
  final IndustryType industryType;
  final CompanySize? companySize;
  final String? website;
  final String? description;
  final Address headquarters;
  final String contactEmail;
  final String? contactPhone;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'companyName': companyName,
        'registrationNumber': registrationNumber,
        'industryType': industryType.wire,
        'companySize': companySize?.wire,
        'website': website,
        'description': description,
        'headquarters': headquarters.toJson(),
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
      };
}

/// Partial-update payload for `PATCH /businesses/me`. Every field optional —
/// only the ones the business actually touched get sent, matching
/// BusinessUpdateRequest's null-means-untouched semantics on the backend.
@immutable
class BusinessUpdateDraft {
  const BusinessUpdateDraft({
    this.companyName,
    this.industryType,
    this.companySize,
    this.website,
    this.description,
    this.logoUrl,
    this.headquarters,
    this.contactPhone,
  });

  final String? companyName;
  final IndustryType? industryType;
  final CompanySize? companySize;
  final String? website;
  final String? description;
  final String? logoUrl;
  final Address? headquarters;
  final String? contactPhone;

  Map<String, dynamic> toJson() => {
        if (companyName != null) 'companyName': companyName,
        if (industryType != null) 'industryType': industryType!.wire,
        if (companySize != null) 'companySize': companySize!.wire,
        if (website != null) 'website': website,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (headquarters != null) 'headquarters': headquarters!.toJson(),
        if (contactPhone != null) 'contactPhone': contactPhone,
      };
}