enum OpportunityKind {
  internship,
  fullTime,
  advisory,
  fellowship,
}

extension OpportunityKindExtension on OpportunityKind {
  String get wire {
    switch (this) {
      case OpportunityKind.internship:
        return 'internship';
      case OpportunityKind.fullTime:
        return 'full_time';
      case OpportunityKind.advisory:
        return 'advisory';
      case OpportunityKind.fellowship:
        return 'fellowship';
    }
  }

  static OpportunityKind fromWire(String? wire) {
    switch (wire) {
      case 'full_time':
        return OpportunityKind.fullTime;
      case 'advisory':
        return OpportunityKind.advisory;
      case 'fellowship':
        return OpportunityKind.fellowship;
      case 'internship':
      default:
        return OpportunityKind.internship;
    }
  }
}

class Opportunity {
  final String id;
  final String title;
  final String company;
  final String location;
  final OpportunityKind kind;
  final String description;
  final DateTime? postedAt;

  const Opportunity({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.kind,
    this.description = '',
    this.postedAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      kind: OpportunityKindExtension.fromWire(json['kind'] as String?),
      description: json['description'] as String? ?? '',
      postedAt: json['postedAt'] != null
          ? DateTime.tryParse(json['postedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'kind': kind.wire,
        'description': description,
        if (postedAt != null) 'postedAt': postedAt!.toIso8601String(),
      };
}

class ApplicationRecord {
  final String id;
  final String opportunityId;
  final String roleTitle;
  final String company;
  final String status;
  final DateTime? appliedAt;

  const ApplicationRecord({
    required this.id,
    required this.opportunityId,
    required this.roleTitle,
    required this.company,
    required this.status,
    this.appliedAt,
  });

  factory ApplicationRecord.fromJson(Map<String, dynamic> json) {
    return ApplicationRecord(
      id: json['id'] as String? ?? '',
      opportunityId: json['opportunityId'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      status: json['status'] as String? ?? 'Submitted',
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'opportunityId': opportunityId,
        'roleTitle': roleTitle,
        'company': company,
        'status': status,
        if (appliedAt != null) 'appliedAt': appliedAt!.toIso8601String(),
      };
}

class AdvisorySession {
  final String id;
  final String mentorName;
  final String topic;
  final DateTime? scheduledAt;
  final String status;

  const AdvisorySession({
    required this.id,
    required this.mentorName,
    required this.topic,
    this.scheduledAt,
    required this.status,
  });

  factory AdvisorySession.fromJson(Map<String, dynamic> json) {
    return AdvisorySession(
      id: json['id'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? json['mentor'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
      status: json['status'] as String? ?? 'Upcoming',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mentorName': mentorName,
        'topic': topic,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
        'status': status,
      };
}

class ConnectionSuggestion {
  final String id;
  final String name;
  final String headline;
  final String? avatarUrl;
  final String reason;

  const ConnectionSuggestion({
    required this.id,
    required this.name,
    required this.headline,
    this.avatarUrl,
    required this.reason,
  });

  factory ConnectionSuggestion.fromJson(Map<String, dynamic> json) {
    return ConnectionSuggestion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'headline': headline,
        'avatarUrl': avatarUrl,
        'reason': reason,
      };
}
