// Shared User model built from either a DummyJSON response or a Firebase account.
class User {
  final int id;
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String age;
  final String phone;
  final String accessToken;
  final String refreshToken;
  final String loginType;

  User({
    required this.id,
    required this.uid,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.age,
    required this.phone,
    required this.accessToken,
    required this.refreshToken,
    required this.loginType,
  });

  // True when the session came from Firebase Auth instead of DummyJSON.
  bool get isFirebase => loginType == 'firebase';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      loginType: json['loginType']?.toString() ?? 'dummyjson',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'age': age,
      'phone': phone,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType,
    };
  }
}
