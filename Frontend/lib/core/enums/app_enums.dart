
// ignore_for_file: constant_identifier_names

enum UserRole {
  ROLE_USER,
  ROLE_ADMIN;

  String get value => toString().split('.').last;
  static UserRole fromString(String value) =>
      UserRole.values.firstWhere((e) => e.value == value, orElse: () => ROLE_USER);
}

enum UserStatus {
  looking_for_team,
  looking_for_project,
  looking_for_hackathon,
  looking_for_mentor,
  looking_for_mentee,
  freelance,
  open_to_offers,
  just_networking;

  String get value => toString().split('.').last;
  static UserStatus fromString(String value) =>
      UserStatus.values.firstWhere((e) => e.value == value, orElse: () => just_networking);
}

enum TagStatus {
  PENDING,
  APPROVED,
  REJECTED,
  AUTO_APPROVED;

  String get value => toString().split('.').last;
  static TagStatus fromString(String value) =>
      TagStatus.values.firstWhere((e) => e.value == value, orElse: () => PENDING);
}

enum FriendStatus {
  PENDING,
  ACCEPTED,
  BLOCKED,
  REJECT;

  String get value => toString().split('.').last;
  static FriendStatus fromString(String value) =>
      FriendStatus.values.firstWhere((e) => e.value == value, orElse: () => PENDING);
}

enum EventStatus {
  PLANNED,
  ACTIVE,
  COMPLETED,
  CANCELLED;

  String get value => toString().split('.').last;
  static EventStatus fromString(String value) =>
      EventStatus.values.firstWhere((e) => e.value == value, orElse: () => PLANNED);
}

enum EventCategory {
  HACKATHON,
  MEETUP,
  CONFERENCE,
  WORKSHOP,
  OTHER;

  String get value => toString().split('.').last;
  static EventCategory fromString(String value) =>
      EventCategory.values.firstWhere((e) => e.value == value, orElse: () => OTHER);
}
