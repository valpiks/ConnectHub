import 'package:connecthub_app/features/auth/domain/user.dart';

class Friend {
  final User user;
  final bool isIncoming;

  Friend({
    required this.user,
    this.isIncoming = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] as Map<String, dynamic>?) ?? json;

    return Friend(
      user: User.fromJson(userJson),
      isIncoming: json['isIncoming'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'isIncoming': isIncoming,
    };
  }

  String get id => user.uuid;
  String get uuid => user.uuid;
  String get name => user.name;

  String? get avatarUrl =>
      (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
          ? user.avatarUrl
          : null;

  String? get tag => user.tag.isNotEmpty ? user.tag : null;

  String? get specialization =>
      user.specialization.isNotEmpty ? user.specialization : null;
}
