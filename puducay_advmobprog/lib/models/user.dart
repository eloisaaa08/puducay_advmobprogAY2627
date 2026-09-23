// ============================================================================
// LAB ACTIVITY 4 — ENHANCEMENT 3
// User model used across the app (typed replacement for the raw
// Map<String, dynamic> the API/SharedPreferences return).
//
//   UserService.loginUser()   -> Map from the API  -> User.fromJson()
//   UserService.saveUserData()-> writes each User field into SharedPreferences
//   UserService.getUser()     -> reads SharedPreferences -> User.fromJson()
//   ProfileScreen             -> receives a User and renders it directly
//
// Keeping this as a model (instead of passing Maps around) is what lets
// ProfileScreen, HomeScreen, and CartScreen share one typed, compile-time
// checked object for "who is signed in right now".
// ============================================================================
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
