import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserProfileService {
  // In-memory storage for now (will be replaced with SharedPreferences later)
  static UserProfile? _currentProfile;
  static bool _profileCompleted = false;

  // Save user profile to memory
  static Future<bool> saveProfile(UserProfile profile) async {
    try {
      _currentProfile = profile;
      _profileCompleted = true;

      debugPrint('Profile saved successfully: $profile');
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  // Load user profile from memory
  static Future<UserProfile?> loadProfile() async {
    try {
      return _currentProfile;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  // Check if user has completed profile setup
  static Future<bool> isProfileCompleted() async {
    try {
      return _profileCompleted;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  // Clear user profile (for sign out or reset)
  static Future<bool> clearProfile() async {
    try {
      _currentProfile = null;
      _profileCompleted = false;

      debugPrint('Profile cleared successfully');
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
