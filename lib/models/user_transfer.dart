class UserModel {
  final int userId;
  final String phoneNumber;

  UserModel({required this.userId, required this.phoneNumber});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['UserID'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
