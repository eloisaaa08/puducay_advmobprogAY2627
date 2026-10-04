import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

// Global notifier so any screen can listen to the shared UserService instance.
ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Tells the app which backend the current session came from.
enum LoginType { dummyjson, firebase }

class UserService {
  Map<String, dynamic> data = {};

  // Session keys removed on logout, while saved Firebase profiles are kept.
  static const List<String> _sessionKeys = [
    'id',
    'uid',
    'username',
    'email',
    'firstName',
    'lastName',
    'gender',
    'image',
    'age',
    'phone',
    'accessToken',
    'refreshToken',
    'token',
    'loginType',
  ];

  // DummyJSON functions from the previous lab.

  // Enhancement 2: logs in through the DummyJSON API and saves the session.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);

      // DummyJSON login only returns basic fields, so the full user is fetched for age and phone.
      try {
        final details = await get(Uri.parse('$host/users/${data['id']}'));
        if (details.statusCode == 200) {
          final extra = jsonDecode(details.body) as Map<String, dynamic>;
          data['age'] = extra['age'];
          data['phone'] = extra['phone'];
        }
      } catch (_) {}

      data['loginType'] = LoginType.dummyjson.name;
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // Enhancement 2: refreshes the DummyJSON access token using the saved refresh token.
  Future<void> refreshDummyToken() async {
    final prefs = await SharedPreferences.getInstance();
    final response = await post(
      Uri.parse('$host/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': prefs.getString('refreshToken') ?? '',
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      final tokens = jsonDecode(response.body) as Map<String, dynamic>;
      await prefs.setString('accessToken', tokens['accessToken'] ?? '');
      await prefs.setString('refreshToken', tokens['refreshToken'] ?? '');
      await prefs.setString('token', tokens['accessToken'] ?? '');
    } else {
      throw Exception(response.body);
    }
  }

  // Enhancement 3: updates the username on DummyJSON (simulated) and in the saved session.
  Future<void> updateDummyUsername({
    required int id,
    required String username,
  }) async {
    final response = await put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode != 200) throw Exception(response.body);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // Enhancement 3: changes the password on DummyJSON (simulated) after checking the current one.
  Future<void> updateDummyPassword({
    required int id,
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    // Re-login confirms the current password is correct before changing it.
    final check = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': currentPassword}),
    );
    if (check.statusCode != 200) throw Exception('Current password is wrong.');

    final response = await put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  // Enhancement 3: deletes the DummyJSON user (simulated) and clears the session.
  Future<void> deleteDummyAccount({required int id}) async {
    final response = await delete(Uri.parse('$host/users/$id'));
    if (response.statusCode != 200) throw Exception(response.body);
    await logout();
  }

  // Saves the user data from the API response into SharedPreferences.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('uid', user.uid);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('age', user.age);
    await prefs.setString('phone', user.phone);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', user.loginType);

    // Supports a generic token key if the API response has one.
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // Returns which backend the saved session belongs to.
  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyjson;
  }

  // Enhancement 3: returns the signed-in user's data depending on the LoginType.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (await getLoginType() == LoginType.firebase && currentUser != null) {
      final fbUser = currentUser!;
      final profile = await _getFirebaseProfile(fbUser.uid);

      return {
        // Firebase has no numeric ID, so the demo DummyJSON ID is used for the cart.
        'id': currentUserId,
        'uid': fbUser.uid,
        'username': fbUser.displayName ?? profile['username'] ?? '',
        'email': fbUser.email ?? '',
        'firstName': profile['firstName'] ?? '',
        'lastName': profile['lastName'] ?? '',
        'gender': profile['gender'] ?? '',
        'image': fbUser.photoURL ?? '',
        'age': profile['age'] ?? '',
        'phone': profile['phone'] ?? '',
        'accessToken': prefs.getString('accessToken') ?? '',
        'refreshToken': fbUser.refreshToken ?? '',
        'loginType': LoginType.firebase.name,
      };
    }

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'age': prefs.getString('age') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? LoginType.dummyjson.name,
    };
  }

  // Returns the saved user data as a User model.
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  // Checks for a saved session from either DummyJSON or Firebase.
  Future<bool> isLoggedIn() async {
    if (await getLoginType() == LoginType.firebase) {
      // Waits for Firebase to restore its saved user since currentUser can be null right at startup.
      return await authStateChanges.first != null;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Enhancement 1: clears the session/token of both DummyJSON and Firebase.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _sessionKeys) {
        await prefs.remove(key);
      }
      if (currentUser != null) await signOut();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // Firebase Auth functions for Lab Activity 5.

  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;

  fb.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb.User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Enhancement 1: signs in with Firebase email and password.
  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession();
    return credential;
  }

  // Enhancement 1: creates a Firebase account with email and password.
  Future<fb.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Enhancement 2: creates the Firebase account and saves the signup details.
  Future<fb.UserCredential> signUp({
    required String firstName,
    required String lastName,
    required String age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await createAccount(email: email, password: password);
    await credential.user!.updateDisplayName(username);

    await _saveFirebaseProfile(credential.user!.uid, {
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'phone': contactNo,
      'username': username,
    });

    await _saveFirebaseSession();
    return credential;
  }

  // Enhancement 1: signs out of Firebase.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // Enhancement 1: updates the Firebase display name used as the username.
  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    await currentUser!.reload();

    final profile = await _getFirebaseProfile(currentUser!.uid);
    profile['username'] = username;
    await _saveFirebaseProfile(currentUser!.uid, profile);
  }

  // Enhancement 1: re-authenticates then deletes the Firebase account.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    fb.AuthCredential credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final uid = currentUser!.uid;
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_$uid');
    await logout();
  }

  // Enhancement 1: re-authenticates then changes the Firebase password.
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    fb.AuthCredential credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // Enhancement 2: forces a Firebase ID token refresh and saves the new token.
  Future<String?> refreshFirebaseToken() async {
    final token = await currentUser?.getIdToken(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token ?? '');
    await prefs.setString('token', token ?? '');
    return token;
  }

  // Saves the Firebase login type and ID token so the splash screen can restore the session.
  Future<void> _saveFirebaseSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', LoginType.firebase.name);
    await refreshFirebaseToken();
  }

  // Stores the extra signup fields per Firebase UID since Firebase Auth only keeps email and display name.
  Future<void> _saveFirebaseProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_$uid', jsonEncode(profile));
  }

  // Reads the extra signup fields saved for a Firebase UID.
  Future<Map<String, dynamic>> _getFirebaseProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('profile_$uid');
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }
}
