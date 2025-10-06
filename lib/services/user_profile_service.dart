import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _profileKey = 'user_profile';
  static const String _profileCompletedKey = 'profile_completed';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhotoKey = 'user_photo';
  static const String _manualSignOutKey = 'manual_sign_out';

  // In-memory cache
  static UserProfile? _currentProfile;
  static bool? _profileCompleted;

  // Save user profile to persistent storage
  static Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save profile as JSON
      final profileJson = jsonEncode(profile.toMap());
      await prefs.setString(_profileKey, profileJson);
      await prefs.setBool(_profileCompletedKey, true);

      // Update cache
      _currentProfile = profile;
      _profileCompleted = true;

      debugPrint('Profile saved successfully: $profile');
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  // Load user profile from persistent storage
  static Future<UserProfile?> loadProfile() async {
    try {
      // Return cached version if available
      if (_currentProfile != null) {
        return _currentProfile;
      }

      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        _currentProfile = UserProfile.fromMap(profileMap);
        return _currentProfile;
      }

      return null;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  // Check if user has completed profile setup
  static Future<bool> isProfileCompleted() async {
    try {
      // Return cached version if available
      if (_profileCompleted != null) {
        return _profileCompleted!;
      }

      final prefs = await SharedPreferences.getInstance();
      _profileCompleted = prefs.getBool(_profileCompletedKey) ?? false;
      return _profileCompleted!;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  // Save user session info for auto-login
  static Future<bool> saveUserSession({
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);
      await prefs.setString(_userNameKey, displayName);
      if (photoUrl != null) {
        await prefs.setString(_userPhotoKey, photoUrl);
      }

      // Clear manual sign-out flag when user signs in
      await prefs.setBool(_manualSignOutKey, false);

      debugPrint('User session saved: $email');
      return true;
    } catch (e) {
      debugPrint('Error saving user session: $e');
      return false;
    }
  }

  // Load saved user session
  static Future<Map<String, String?>> loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'email': prefs.getString(_userEmailKey),
        'displayName': prefs.getString(_userNameKey),
        'photoUrl': prefs.getString(_userPhotoKey),
      };
    } catch (e) {
      debugPrint('Error loading user session: $e');
      return {};
    }
  }

  // Check if user session exists
  static Future<bool> hasUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userEmailKey);
    } catch (e) {
      debugPrint('Error checking user session: $e');
      return false;
    }
  }

  // Set manual sign-out flag
  static Future<bool> setManualSignOut(bool signedOut) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_manualSignOutKey, signedOut);
      return true;
    } catch (e) {
      debugPrint('Error setting manual sign-out flag: $e');
      return false;
    }
  }

  // Check if user manually signed out
  static Future<bool> wasManuallySignedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_manualSignOutKey) ?? false;
    } catch (e) {
      debugPrint('Error checking manual sign-out flag: $e');
      return false;
    }
  }

  // Clear user profile and session (for sign out or reset)
  static Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_profileCompletedKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userPhotoKey);

      // Set manual sign-out flag
      await prefs.setBool(_manualSignOutKey, true);

      // Clear cache
      _currentProfile = null;
      _profileCompleted = null;

      debugPrint('Profile and session cleared successfully');
      return true;
    } catch (e) {
      debugPrint('Error clearing profile: $e');
      return false;
    }
  }

  // Update existing profile
  static Future<bool> updateProfile(UserProfile profile) async {
    return await saveProfile(profile);
  }

  // Check if profile setup should be shown for first-time users
  static Future<bool> shouldShowProfileSetup() async {
    return !(await isProfileCompleted());
  }
}
