enum VerificationState {
  unverified,
  pending,
  verified,
}

class TrackInfo {
  final String tier;
  final String label;

  const TrackInfo({
    required this.tier,
    required this.label,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      tier: json['tier'] as String? ?? 'MEMBER I',
      label: json['label'] as String? ?? 'PROFESSIONAL',
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'label': label,
      };
}

class ExperienceEntry {
  final String role;
  final String organisation;
  final String period;

  const ExperienceEntry({
    required this.role,
    required this.organisation,
    required this.period,
  });

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      role: json['role'] as String? ?? '',
      organisation: json['organisation'] as String? ?? '',
      period: json['period'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'organisation': organisation,
        'period': period,
      };
}

class Credential {
  final String name;
  final String issuer;
  final int? year;

  const Credential({
    required this.name,
    required this.issuer,
    this.year,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'issuer': issuer,
        if (year != null) 'year': year,
      };
}

class UserProfile {
  final String id;
  final String fullName;
  final String headline;
  final String about;
  final String location;
  final String? avatarUrl;
  final bool isVerified;
  final VerificationState verification;
  final TrackInfo track;
  final int connections;
  final int profileViews;
  final bool openToWork;
  final bool openToMentor;
  final List<String> focusAreas;
  final List<ExperienceEntry> experience;
  final List<Credential> credentials;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.headline = '',
    this.about = '',
    this.location = '',
    this.avatarUrl,
    this.isVerified = false,
    this.verification = VerificationState.unverified,
    this.track = const TrackInfo(tier: 'MEMBER I', label: 'PROFESSIONAL'),
    this.connections = 0,
    this.profileViews = 0,
    this.openToWork = false,
    this.openToMentor = false,
    this.focusAreas = const [],
    this.experience = const [],
    this.credentials = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    VerificationState parseVerification(String? val) {
      switch (val) {
        case 'pending':
          return VerificationState.pending;
        case 'verified':
          return VerificationState.verified;
        default:
          return VerificationState.unverified;
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? 'User',
      headline: json['headline'] as String? ?? '',
      about: json['about'] as String? ?? '',
      location: json['location'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verification: parseVerification(json['verification'] as String?),
      track: json['track'] is Map<String, dynamic>
          ? TrackInfo.fromJson(json['track'] as Map<String, dynamic>)
          : const TrackInfo(tier: 'MEMBER I', label: 'PROFESSIONAL'),
      connections: json['connections'] as int? ?? 0,
      profileViews: json['profileViews'] as int? ?? 0,
      openToWork: json['openToWork'] as bool? ?? false,
      openToMentor: json['openToMentor'] as bool? ?? false,
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      experience: (json['experience'] as List<dynamic>?)
              ?.map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      credentials: (json['credentials'] as List<dynamic>?)
              ?.map((e) => Credential.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'headline': headline,
        'about': about,
        'location': location,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'verification': verification.name,
        'track': track.toJson(),
        'connections': connections,
        'profileViews': profileViews,
        'openToWork': openToWork,
        'openToMentor': openToMentor,
        'focusAreas': focusAreas,
        'experience': experience.map((e) => e.toJson()).toList(),
        'credentials': credentials.map((c) => c.toJson()).toList(),
      };

  double get completeness {
    int points = 0;
    int total = 6;
    if (fullName.isNotEmpty) points++;
    if (headline.isNotEmpty) points++;
    if (about.isNotEmpty) points++;
    if (location.isNotEmpty) points++;
    if (experience.isNotEmpty) points++;
    if (credentials.isNotEmpty) points++;
    return points / total;
  }

  String? get nextStep {
    if (headline.isEmpty) return 'Add a headline to describe your role';
    if (about.isEmpty) return 'Write a brief bio in your summary';
    if (location.isEmpty) return 'Add your location';
    if (experience.isEmpty) return 'Add an experience entry';
    if (credentials.isEmpty) return 'Add your credentials or degrees';
    return null;
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? headline,
    String? about,
    String? location,
    String? avatarUrl,
    bool? isVerified,
    VerificationState? verification,
    TrackInfo? track,
    int? connections,
    int? profileViews,
    bool? openToWork,
    bool? openToMentor,
    List<String>? focusAreas,
    List<ExperienceEntry>? experience,
    List<Credential>? credentials,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      headline: headline ?? this.headline,
      about: about ?? this.about,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      verification: verification ?? this.verification,
      track: track ?? this.track,
      connections: connections ?? this.connections,
      profileViews: profileViews ?? this.profileViews,
      openToWork: openToWork ?? this.openToWork,
      openToMentor: openToMentor ?? this.openToMentor,
      focusAreas: focusAreas ?? this.focusAreas,
      experience: experience ?? this.experience,
      credentials: credentials ?? this.credentials,
    );
  }
}
