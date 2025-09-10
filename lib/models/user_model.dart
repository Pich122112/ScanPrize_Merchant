class Users {
  final int userId;
  final String phoneNumber;
  final String userType;

  Users({
    required this.userId,
    required this.phoneNumber,
    required this.userType,
  });

  // Factory for parsing API response!
  factory Users.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {}; // Get the 'data' map from the root
    return Users(
      userId: data['userId'] ?? 0,
      phoneNumber: data['phoneNumber'] ?? '',
      userType: data['userType']?.toString() ?? '1', // Default to '1' if missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'user_type': userType,
    };
  }
}

//Correct with 31 line code changes
