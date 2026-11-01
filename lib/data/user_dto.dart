class UserDto {
  const UserDto({
    required this.id,
    required this.username,
    this.userProfileUrl,
  });

  final int id;
  final String username;
  final String? userProfileUrl;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      userProfileUrl: json['user_profile_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'user_profile_url': userProfileUrl,
    };
  }
}