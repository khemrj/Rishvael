import 'package:flutter/foundation.dart';

/// ---------------------------------------------------------------------------
/// WIRE FORMAT FOR ENUMS
///
/// Dart's `EnumValue.name` gives you camelCase (`corporateFinance`). Java/Spring
/// enum constants are conventionally SCREAMING_SNAKE_CASE (`CORPORATE_FINANCE`)
/// — that's not a bug on either side, it's each language's own convention, and
/// the two were never going to match without an explicit conversion. Every
/// enum on this model goes through these two functions on the way in and out,
/// so there's exactly one place to fix if the backend's convention differs.
/// ---------------------------------------------------------------------------
String _toWireEnum(String dartName) =>
    dartName.replaceAllMapped(RegExp('([A-Z])'), (m) => '_${m[1]}').toUpperCase();
  int _idToInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.parse(v);
  throw FormatException('Unexpected id type: ${v.runtimeType}');
}  

String _fromWireEnum(String wireName) {
  final parts = wireName.toLowerCase().split('_');
  return parts.first + parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}

extension _WireEnum on Enum {
  String get wire => _toWireEnum(name);
}


/// ---------------------------------------------------------------------------
/// OPPORTUNITY — not "vacancy", not "job", not "listing".
/// Rishvael's own copy already calls these "opportunities" (roles, internships,
/// gigs). Keep the vocabulary consistent end-to-end: the model, the repository,
/// the provider, and the page all say "opportunity". Mixed vocabulary is how
/// you end up with a JobRepository writing to an `opportunities` collection.
/// ---------------------------------------------------------------------------

/// Rishvael is finance-only, so "industry" isn't a free-text field — it's a
/// closed set of finance sub-domains. A closed set is filterable and
/// matchable; free text ("djaf", "kdfk"-style typos) is not.
enum FinanceSpecialization {
  investmentBanking('Investment Banking'),
  corporateFinance('Corporate Finance'),
  accountingAudit('Accounting & Audit'),
  assetWealthManagement('Asset & Wealth Management'),
  privateEquityVc('Private Equity & VC'),
  riskCompliance('Risk & Compliance'),
  fintech('FinTech'),
  insurance('Insurance'),
  other('Other Finance');

  const FinanceSpecialization(this.label);
  final String label;
}

enum OpportunityType {
  fullTime('Full-time'),
  partTime('Part-time'),
  internship('Internship'),
  contract('Contract'),
  gig('Gig');

  const OpportunityType(this.label);
  final String label;
}

/// Ranges, not raw years. A business posting doesn't know or care that a
/// candidate has "4.5 years" — they care which bracket. Ranges also make the
/// field usable as a filter facet later without bucketing logic client-side.
enum ExperienceLevel {
  graduate('Graduate / 0 yrs', 0, 0),
  junior('Junior · 1-3 yrs', 1, 3),
  mid('Mid · 3-6 yrs', 3, 6),
  senior('Senior · 6-10 yrs', 6, 10),
  executive('Executive · 10+ yrs', 10, null);

  const ExperienceLevel(this.label, this.minYears, this.maxYears);
  final String label;
  final int minYears;
  final int? maxYears;
}

enum WorkMode {
  onsite('On-site'),
  remote('Remote'),
  hybrid('Hybrid');

  const WorkMode(this.label);
  final String label;
}

enum OpportunityStatus { draft, published, closed }

@immutable
class CompensationRange {
  const CompensationRange({this.min, this.max, this.currency = 'USD', this.disclosed = true});

  final double? min;
  final double? max;
  final String currency;
  final bool disclosed;

  static const undisclosed = CompensationRange(disclosed: false);

  String display() {
    if (!disclosed || (min == null && max == null)) return 'Undisclosed';
    if (min != null && max != null) return '$currency ${min!.toStringAsFixed(0)} – ${max!.toStringAsFixed(0)}';
    return '$currency ${(min ?? max)!.toStringAsFixed(0)}+';
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'currency': currency,
        'disclosed': disclosed,
      };

  factory CompensationRange.fromJson(Map<String, dynamic> json) => CompensationRange(
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        disclosed: json['disclosed'] as bool? ?? true,
      );
}

@immutable
class Opportunity {
  const Opportunity({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.specialization,
    required this.type,
    required this.experienceLevel,
    required this.workMode,
    required this.location,
    required this.description,
    required this.responsibilities,
    required this.requiredSkills,
    required this.qualifications,
    required this.compensation,
    required this.openings,
    required this.status,
    required this.postedAt,
    this.applicationDeadline,
  });

  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final FinanceSpecialization specialization;
  final OpportunityType type;
  final ExperienceLevel experienceLevel;
  final WorkMode workMode;
  final String location;
  final String description;
  final List<String> responsibilities;
  final List<String> requiredSkills;
  final List<String> qualifications;
  final CompensationRange compensation;
  final int openings;
  final OpportunityStatus status;
  final DateTime postedAt;
  final DateTime? applicationDeadline;

  Opportunity copyWith({OpportunityStatus? status}) => Opportunity(
        id: id,
        businessId: businessId,
        businessName: businessName,
        title: title,
        specialization: specialization,
        type: type,
        experienceLevel: experienceLevel,
        workMode: workMode,
        location: location,
        description: description,
        responsibilities: responsibilities,
        requiredSkills: requiredSkills,
        qualifications: qualifications,
        compensation: compensation,
        openings: openings,
        status: status ?? this.status,
        postedAt: postedAt,
        applicationDeadline: applicationDeadline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'businessName': businessName,
        'title': title,
        'specialization': specialization.wire,
        'type': type.wire,
        'experienceLevel': experienceLevel.wire,
        'workMode': workMode.wire,
        'location': location,
        'description': description,
        'responsibilities': responsibilities,
        'requiredSkills': requiredSkills,
        'qualifications': qualifications,
        'compensation': compensation.toJson(),
        'openings': openings,
        'status': status.wire,
        'postedAt': postedAt.toIso8601String(),
        'applicationDeadline': applicationDeadline?.toIso8601String(),
      };

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        id: _idToInt(json['id']),
        businessId: _idToInt(json['businessId']),
        businessName: json['businessName'] as String,
        title: json['title'] as String,
        specialization: FinanceSpecialization.values.byName(_fromWireEnum(json['specialization'] as String)),
        type: OpportunityType.values.byName(_fromWireEnum(json['type'] as String)),
        experienceLevel: ExperienceLevel.values.byName(_fromWireEnum(json['experienceLevel'] as String)),
        workMode: WorkMode.values.byName(_fromWireEnum(json['workMode'] as String)),
        location: json['location'] as String,
        description: json['description'] as String,
        responsibilities: List<String>.from(json['responsibilities'] as List),
        requiredSkills: List<String>.from(json['requiredSkills'] as List),
        qualifications: List<String>.from(json['qualifications'] as List),
       compensation: json['compensation'] == null
    ? CompensationRange.undisclosed
    : CompensationRange.fromJson(json['compensation'] as Map<String, dynamic>),
        openings: json['openings'] as int,
        status: OpportunityStatus.values.byName(_fromWireEnum(json['status'] as String)),
        postedAt: DateTime.parse(json['postedAt'] as String),
        applicationDeadline: json['applicationDeadline'] == null
            ? null
            : DateTime.parse(json['applicationDeadline'] as String),
      );
}

/// The payload the POST form actually builds — deliberately separate from
/// [Opportunity]. The form doesn't know its own id, business identity, or
/// postedAt timestamp; the backend assigns those. Reusing the full entity as
/// the draft type means faking those fields client-side, which is how you
/// get an id collision or a spoofed businessId bug later.
@immutable
class OpportunityDraft {
  const OpportunityDraft({
    required this.title,
    required this.specialization,
    required this.type,
    required this.experienceLevel,
    required this.workMode,
    required this.location,
    required this.description,
    required this.responsibilities,
    required this.requiredSkills,
    required this.qualifications,
    required this.compensation,
    required this.openings,
    this.applicationDeadline,
  });

  final String title;
  final FinanceSpecialization specialization;
  final OpportunityType type;
  final ExperienceLevel experienceLevel;
  final WorkMode workMode;
  final String location;
  final String description;
  final List<String> responsibilities;
  final List<String> requiredSkills;
  final List<String> qualifications;
  final CompensationRange compensation;
  final int openings;
  final DateTime? applicationDeadline;

  Map<String, dynamic> toJson() => {
        'title': title,
        'specialization': specialization.wire,
        'type': type.wire,
        'experienceLevel': experienceLevel.wire,
        'workMode': workMode.wire,
        'location': location,
        'description': description,
        'responsibilities': responsibilities,
        'requiredSkills': requiredSkills,
        'qualifications': qualifications,
        'compensation': compensation.toJson(),
        'openings': openings,
        'applicationDeadline': applicationDeadline?.toIso8601String(),
      };
}