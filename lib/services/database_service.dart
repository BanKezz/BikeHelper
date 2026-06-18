import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motor_model.dart';
import 'supabase_config.dart';

class DatabaseService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Mendapatkan ID pengguna saat ini (Supabase Auth)
  String? get _currentUserId {
    if (!SupabaseConfig.isValid) return null;
    try {
      return _supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // DATA MOTOR
  // ==========================================

  // Mendapatkan data motor
  Future<MotorModel?> getMotor() async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('motors')
            .select()
            .eq('user_id', _currentUserId!)
            .maybeSingle();

        if (response != null) {
          return MotorModel(
            namaMotor: response['nama_motor'] ?? '',
            tahun: response['tahun'] ?? '',
            odometer: response['odometer'] ?? '',
            fotoPath: response['foto_path'],
          );
        }
      } catch (e) {
        debugPrint('Error getMotor dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final motorJson = prefs.getString('local_motor_data');
    if (motorJson != null) {
      try {
        return MotorModel.fromMap(json.decode(motorJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Menyimpan atau memperbarui data motor
  Future<bool> saveMotor(MotorModel motor) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final data = {
          'user_id': _currentUserId,
          'nama_motor': motor.namaMotor,
          'tahun': motor.tahun,
          'odometer': motor.odometer,
          'foto_path': motor.fotoPath,
        };

        // Menggunakan upsert (update if exists, insert if not)
        await _supabase.from('motors').upsert(
              data,
              onConflict: 'user_id', // Menjamin 1 user hanya punya 1 motor
            );
        
        // Simpan juga ke local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_motor_data', json.encode(motor.toMap()));
        return true;
      } catch (e) {
        debugPrint('Error saveMotor ke Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString('local_motor_data', json.encode(motor.toMap()));
  }

  // ==========================================
  // JADWAL SERVIS
  // ==========================================

  Future<List<Map<String, dynamic>>> getJadwalServis() async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('jadwal_servis')
            .select()
            .eq('user_id', _currentUserId!)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error getJadwalServis dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_jadwal_servis');
    if (dataStr != null) {
      return List<Map<String, dynamic>>.from(json.decode(dataStr));
    }

    // Data default bawaan aplikasi jika kosong
    final defaultJadwal = [
      {'komponen': 'Ganti Oli', 'sisaKm': '250', 'tanggal': '25 Jul 2025'},
      {'komponen': 'Servis Berkala', 'sisaKm': '1.500', 'tanggal': '10 Ags 2025'},
      {'komponen': 'Ganti Ban Belakang', 'sisaKm': '3.000', 'tanggal': '01 Sep 2025'},
    ];
    await prefs.setString('local_jadwal_servis', json.encode(defaultJadwal));
    return defaultJadwal;
  }

  Future<bool> addJadwalServis(String komponen, String sisaKm, String tanggal) async {
    final newItem = {
      'komponen': komponen,
      'sisaKm': sisaKm,
      'tanggal': tanggal,
    };

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase.from('jadwal_servis').insert({
          'user_id': _currentUserId,
          'komponen': komponen,
          'sisa_km': sisaKm,
          'tanggal': tanggal,
        });
      } catch (e) {
        debugPrint('Error addJadwalServis ke Supabase: $e');
        return false;
      }
    }

    // Update local cache
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getJadwalServis();
    currentList.insert(0, newItem);
    await prefs.setString('local_jadwal_servis', json.encode(currentList));
    return true;
  }

  // ==========================================
  // CATATAN SERVIS
  // ==========================================

  Future<List<Map<String, dynamic>>> getCatatanServis() async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('catatan_servis')
            .select()
            .eq('user_id', _currentUserId!)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error getCatatanServis dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_catatan_servis');
    if (dataStr != null) {
      return List<Map<String, dynamic>>.from(json.decode(dataStr));
    }

    // Data default bawaan aplikasi jika kosong
    final defaultCatatan = [
      {'komponen': 'Ganti Oli', 'tanggal': '10 Jan 2025', 'odometer': '12.500 km'},
      {'komponen': 'Servis Berkala', 'tanggal': '05 Okt 2024', 'odometer': '10.000 km'},
      {'komponen': 'Ganti Ban Depan', 'tanggal': '12 Jul 2024', 'odometer': '8.500 km'},
    ];
    await prefs.setString('local_catatan_servis', json.encode(defaultCatatan));
    return defaultCatatan;
  }

  Future<bool> addCatatanServis(String komponen, String tanggal, String odometer) async {
    final newItem = {
      'komponen': komponen,
      'tanggal': tanggal,
      'odometer': odometer,
    };

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase.from('catatan_servis').insert({
          'user_id': _currentUserId,
          'komponen': komponen,
          'tanggal': tanggal,
          'odometer': odometer,
        });
      } catch (e) {
        debugPrint('Error addCatatanServis ke Supabase: $e');
        return false;
      }
    }

    // Update local cache
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getCatatanServis();
    currentList.insert(0, newItem);
    await prefs.setString('local_catatan_servis', json.encode(currentList));
    return true;
  }
}
