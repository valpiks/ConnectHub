import 'package:connecthub_app/core/enums/app_enums.dart';

class Tag {
  final int id;
  final String name;

  const Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class User {
  final String uuid;
  final String tag;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final String specialization;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<Tag> ownTags;
  final List<Tag> seekingTags;

  User({
    required this.uuid,
    required this.tag,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.specialization,
    this.city,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.ownTags,
    required this.seekingTags,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String,
      tag: json['tag'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'ROLE_USER'),
      status:
          UserStatus.fromString(json['status'] as String? ?? 'just_networking'),
      specialization: json['specialization'] as String? ?? '',
      city: json['city'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? "2025-12-18"),
      ownTags: (json['ownTags'] as List? ?? [])
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seekingTags: (json['seekingTags'] as List? ?? [])
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'tag': tag,
      'name': name,
      'email': email,
      'role': role.value,
      'status': status.value,
      'specialization': specialization,
      'city': city,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'ownTags': ownTags.map((tag) => tag.toJson()).toList(),
      'seekingTags': seekingTags.map((tag) => tag.toJson()).toList(),
    };
  }

  User copyWith({
    String? uuid,
    String? tag,
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? specialization,
    String? city,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    List<Tag>? ownTags,
    List<Tag>? seekingTags,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      tag: tag ?? this.tag,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      specialization: specialization ?? this.specialization,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      ownTags: ownTags ?? this.ownTags,
      seekingTags: seekingTags ?? this.seekingTags,
    );
  }

  @override
  String toString() {
    return 'User(uuid: $uuid, name: $name, email: $email, role: $role, status: $status)';
  }
}
