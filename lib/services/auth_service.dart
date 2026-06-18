import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const _keyUsername = 'username';
  static const _keyPassword = 'password';
  static const _keyIsLoggedIn = 'is_logged_in';

  // Helper untuk membuat virtual email dari username
  String _getVirtualEmail(String username) {
    final cleanUsername = username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return '$cleanUsername@bikehelpers.local';
  }

  // Simpan akun saat register
  Future<bool> register(String username, String password) async {
    if (SupabaseConfig.isValid) {
      try {
        final email = _getVirtualEmail(username);
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        // Register berhasil jika user tidak null
        if (response.user != null) {
          // Simpan username lokal untuk kebutuhan profile UI
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUsername, username);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Error register Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Cek apakah username sudah dipakai
    final existing = prefs.getString(_keyUsername);
    if (existing != null && existing == username) {
      return false; // username sudah ada
    }

    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    return true;
  }

  // Validasi login
  Future<bool> login(String username, String password) async {
    if (SupabaseConfig.isValid) {
      try {
        final email = _getVirtualEmail(username);
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUsername, username);
          await prefs.setBool(_keyIsLoggedIn, true);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Error login Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(_keyUsername);
    final savedPassword = prefs.getString(_keyPassword);

    if (savedUsername == username && savedPassword == password) {
      await prefs.setBool(_keyIsLoggedIn, true);
      return true;
    }
    return false;
  }

  // Cek status login
  Future<bool> isLoggedIn() async {
    if (SupabaseConfig.isValid) {
      try {
        final session = _supabase.auth.currentSession;
        return session != null;
      } catch (_) {
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Mendapatkan username saat ini
  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? 'User';
  }

  // Logout
  Future<void> logout() async {
    if (SupabaseConfig.isValid) {
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        debugPrint('Error logout Supabase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}