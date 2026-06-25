import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const _keyAccounts = 'accounts'; // List<Map> semua akun terdaftar
  static const _keyCurrentUser = 'current_username';
  static const _keyIsLoggedIn = 'is_logged_in';

  // Helper untuk membuat virtual email dari username
  String _getVirtualEmail(String username) {
    final cleanUsername =
        username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return '$cleanUsername@bikehelpers.local';
  }

  // Ambil semua akun tersimpan di SharedPreferences
  Future<List<Map<String, String>>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAccounts);
    if (raw == null) return [];
    try {
      final List decoded = json.decode(raw);
      return decoded
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAccounts(List<Map<String, String>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccounts, json.encode(accounts));
  }

  // Daftarkan akun baru
  Future<bool> register(String username, String password) async {
    if (SupabaseConfig.isValid) {
      try {
        final email = _getVirtualEmail(username);
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // Simpan username lokal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyCurrentUser, username);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Error register Supabase: $e');
        return false;
      }
    }

    // Fallback: simpan ke List akun di SharedPreferences
    final accounts = await _getAccounts();

    // Cek username sudah ada
    final exists = accounts.any((acc) =>
        acc['username']?.toLowerCase() == username.trim().toLowerCase());
    if (exists) return false;

    accounts.add({'username': username.trim(), 'password': password});
    await _saveAccounts(accounts);

    // Set sebagai current user dan mark logged in
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, username.trim());
    await prefs.setBool(_keyIsLoggedIn, true);
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
          await prefs.setString(_keyCurrentUser, username);
          await prefs.setBool(_keyIsLoggedIn, true);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Error login Supabase: $e');
        return false;
      }
    }

    // Fallback: cek dari List akun
    final accounts = await _getAccounts();
    final match = accounts.firstWhere(
      (acc) =>
          acc['username']?.toLowerCase() == username.trim().toLowerCase() &&
          acc['password'] == password,
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, username.trim());
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

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Mendapatkan username saat ini
  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUser) ?? 'User';
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
    await prefs.remove(_keyCurrentUser);
  }
}