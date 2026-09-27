/// Mirrors the backend `UserResponse` record.
class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.subscriptionStatus,
    required this.pro,
  });

  final int id;
  final String email;
  final String fullName;

  /// `USER` or `ADMIN`.
  final String role;

  /// `NONE`, `ACTIVE`, `CANCELED` or `PAST_DUE`.
  final String subscriptionStatus;
  final bool pro;

  bool get isAdmin => role == 'ADMIN';

  /// Same rule as the backend `ProAccessService` and the web `proGuard`.
  bool get hasProAccess => pro || isAdmin;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        subscriptionStatus: json['subscriptionStatus'] as String,
        pro: json['pro'] as bool? ?? false,
      );
}
