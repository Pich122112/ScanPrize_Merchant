class Users {
  final String fullName;
  final String address;
  final String phoneNumber;
  final String password;

  Users({
    required this.fullName,
    required this.address,
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'address': address,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }
}

//Correct with 24 line code changes
