import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motor_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';

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

  // Key SharedPreferences untuk motor list per user
  Future<String> _motorListKey() async {
    final username = await AuthService().getCurrentUsername();
    return 'motor_list_$username';
  }

  // Generate ID unik sederhana
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ==========================================
  // DATA MOTOR — MULTI MOTOR
  // ==========================================

  /// Ambil semua motor milik user
  Future<List<MotorModel>> getAllMotors() async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('motors')
            .select()
            .eq('user_id', _currentUserId!)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response)
            .map((m) => MotorModel.fromMap(m))
            .toList();
      } catch (e) {
        debugPrint('Error getAllMotors dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final key = await _motorListKey();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final List decoded = json.decode(raw);
      return decoded.map((e) => MotorModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Ambil motor pertama (motor aktif default)
  Future<MotorModel?> getMotor() async {
    final motors = await getAllMotors();
    return motors.isNotEmpty ? motors.first : null;
  }

  /// Tambah motor baru
  Future<bool> addMotor(MotorModel motor) async {
    final newMotor = motor.copyWith(id: _generateId());

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase.from('motors').insert({
          'user_id': _currentUserId,
          'nama_motor': newMotor.namaMotor,
          'tahun': newMotor.tahun,
          'odometer': newMotor.odometer,
          'plat_nomor': newMotor.platNomor,
          'foto_path': newMotor.fotoPath,
        });
        // Refresh local cache
        await _syncMotorsToLocal();
        return true;
      } catch (e) {
        debugPrint('Error addMotor ke Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final key = await _motorListKey();
    final prefs = await SharedPreferences.getInstance();
    final motors = await getAllMotors();
    motors.insert(0, newMotor);
    await prefs.setString(key, json.encode(motors.map((m) => m.toMap()).toList()));
    return true;
  }

  /// Simpan/update motor berdasarkan ID
  Future<bool> saveMotor(MotorModel motor) async {
    // Jika belum punya ID, anggap sebagai tambah baru
    if (motor.id == null || motor.id!.isEmpty) {
      return addMotor(motor);
    }

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase
            .from('motors')
            .update({
              'nama_motor': motor.namaMotor,
              'tahun': motor.tahun,
              'odometer': motor.odometer,
              'plat_nomor': motor.platNomor,
              'foto_path': motor.fotoPath,
            })
            .eq('user_id', _currentUserId!)
            .eq('id', motor.id!);
        await _syncMotorsToLocal();
        return true;
      } catch (e) {
        debugPrint('Error saveMotor ke Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final key = await _motorListKey();
    final prefs = await SharedPreferences.getInstance();
    final motors = await getAllMotors();
    final idx = motors.indexWhere((m) => m.id == motor.id);
    if (idx >= 0) {
      motors[idx] = motor;
    } else {
      motors.insert(0, motor);
    }
    await prefs.setString(key, json.encode(motors.map((m) => m.toMap()).toList()));
    return true;
  }

  /// Hapus motor berdasarkan ID
  Future<bool> deleteMotor(String motorId) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase
            .from('motors')
            .delete()
            .eq('user_id', _currentUserId!)
            .eq('id', motorId);
        await _syncMotorsToLocal();
        return true;
      } catch (e) {
        debugPrint('Error deleteMotor dari Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final key = await _motorListKey();
    final prefs = await SharedPreferences.getInstance();
    final motors = await getAllMotors();
    motors.removeWhere((m) => m.id == motorId);
    await prefs.setString(key, json.encode(motors.map((m) => m.toMap()).toList()));
    return true;
  }

  Future<void> _syncMotorsToLocal() async {
    try {
      if (_currentUserId == null) return;
      final response = await _supabase
          .from('motors')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      final motors = List<Map<String, dynamic>>.from(response)
          .map((m) => MotorModel.fromMap(m))
          .toList();
      final key = await _motorListKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(motors.map((m) => m.toMap()).toList()));
    } catch (_) {}
  }

  // ==========================================
  // JADWAL SERVIS
  // ==========================================

  Future<List<Map<String, dynamic>>> getJadwalServis(String motorId) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('jadwal_servis')
            .select()
            .eq('user_id', _currentUserId!)
            .eq('motor_id', motorId)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error getJadwalServis dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_jadwal_servis');
    List<Map<String, dynamic>> list = [];
    if (dataStr != null) {
      list = List<Map<String, dynamic>>.from(json.decode(dataStr));
    } else {
      // Data default bawaan aplikasi jika kosong
      list = [
        {'id': '1', 'motorId': motorId, 'komponen': 'Ganti Oli', 'sisaKm': '250', 'tanggal': '25 Jul 2025'},
        {'id': '2', 'motorId': motorId, 'komponen': 'Servis Berkala', 'sisaKm': '1.500', 'tanggal': '10 Ags 2025'},
        {'id': '3', 'motorId': motorId, 'komponen': 'Ganti Ban Belakang', 'sisaKm': '3.000', 'tanggal': '01 Sep 2025'},
      ];
      await prefs.setString('local_jadwal_servis', json.encode(list));
      return list;
    }

    // Self-healing: pastikan setiap item memiliki id dan motorId
    bool changed = false;
    for (int i = 0; i < list.length; i++) {
      if (list[i]['id'] == null) {
        list[i]['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
        changed = true;
      }
      if (list[i]['motorId'] == null) {
        list[i]['motorId'] = motorId;
        changed = true;
      }
    }
    if (changed) {
      await prefs.setString('local_jadwal_servis', json.encode(list));
    }
    return list.where((item) => item['motorId'] == motorId).toList();
  }

  Future<bool> addJadwalServis(String motorId, String komponen, String sisaKm, String tanggal) async {
    final newItem = {
      'id': _generateId(),
      'motorId': motorId,
      'komponen': komponen,
      'sisaKm': sisaKm,
      'tanggal': tanggal,
    };

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase.from('jadwal_servis').insert({
          'user_id': _currentUserId,
          'motor_id': motorId,
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
    final dataStr = prefs.getString('local_jadwal_servis');
    List<Map<String, dynamic>> fullList = [];
    if (dataStr != null) {
      fullList = List<Map<String, dynamic>>.from(json.decode(dataStr));
    }
    fullList.insert(0, newItem);
    await prefs.setString('local_jadwal_servis', json.encode(fullList));
    return true;
  }

  Future<bool> updateJadwalServis(String id, String komponen, String sisaKm, String tanggal) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase
            .from('jadwal_servis')
            .update({
              'komponen': komponen,
              'sisa_km': sisaKm,
              'tanggal': tanggal,
            })
            .eq('user_id', _currentUserId!)
            .eq('id', id);
        return true;
      } catch (e) {
        debugPrint('Error updateJadwalServis dari Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_jadwal_servis');
    if (dataStr != null) {
      final List<Map<String, dynamic>> fullList = List<Map<String, dynamic>>.from(json.decode(dataStr));
      final idx = fullList.indexWhere((item) => item['id']?.toString() == id);
      if (idx >= 0) {
        fullList[idx] = {
          ...fullList[idx],
          'komponen': komponen,
          'sisaKm': sisaKm,
          'tanggal': tanggal,
        };
        await prefs.setString('local_jadwal_servis', json.encode(fullList));
        return true;
      }
    }
    return false;
  }

  Future<bool> deleteJadwalServis(String id) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase
            .from('jadwal_servis')
            .delete()
            .eq('user_id', _currentUserId!)
            .eq('id', id);
        return true;
      } catch (e) {
        debugPrint('Error deleteJadwalServis dari Supabase: $e');
        return false;
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_jadwal_servis');
    if (dataStr != null) {
      final List<Map<String, dynamic>> fullList = List<Map<String, dynamic>>.from(json.decode(dataStr));
      fullList.removeWhere((item) => item['id']?.toString() == id);
      await prefs.setString('local_jadwal_servis', json.encode(fullList));
    }
    return true;
  }

  // ==========================================
  // CATATAN SERVIS
  // ==========================================

  Future<List<Map<String, dynamic>>> getCatatanServis(String motorId) async {
    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        final response = await _supabase
            .from('catatan_servis')
            .select()
            .eq('user_id', _currentUserId!)
            .eq('motor_id', motorId)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error getCatatanServis dari Supabase: $e');
      }
    }

    // Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('local_catatan_servis');
    List<Map<String, dynamic>> list = [];
    if (dataStr != null) {
      list = List<Map<String, dynamic>>.from(json.decode(dataStr));
    } else {
      // Data default bawaan aplikasi jika kosong
      list = [
        {'id': '1', 'motorId': motorId, 'komponen': 'Ganti Oli', 'tanggal': '10 Jan 2025', 'odometer': '12.500 km'},
        {'id': '2', 'motorId': motorId, 'komponen': 'Servis Berkala', 'tanggal': '05 Okt 2024', 'odometer': '10.000 km'},
        {'id': '3', 'motorId': motorId, 'komponen': 'Ganti Ban Depan', 'tanggal': '12 Jul 2024', 'odometer': '8.500 km'},
      ];
      await prefs.setString('local_catatan_servis', json.encode(list));
      return list;
    }

    // Self-healing: pastikan setiap item memiliki id dan motorId
    bool changed = false;
    for (int i = 0; i < list.length; i++) {
      if (list[i]['id'] == null) {
        list[i]['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
        changed = true;
      }
      if (list[i]['motorId'] == null) {
        list[i]['motorId'] = motorId;
        changed = true;
      }
    }
    if (changed) {
      await prefs.setString('local_catatan_servis', json.encode(list));
    }

    return list.where((item) => item['motorId'] == motorId).toList();
  }

  Future<bool> addCatatanServis(String motorId, String komponen, String tanggal, String odometer) async {
    final newItem = {
      'id': _generateId(),
      'motorId': motorId,
      'komponen': komponen,
      'tanggal': tanggal,
      'odometer': odometer,
    };

    if (SupabaseConfig.isValid && _currentUserId != null) {
      try {
        await _supabase.from('catatan_servis').insert({
          'user_id': _currentUserId,
          'motor_id': motorId,
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
    final dataStr = prefs.getString('local_catatan_servis');
    List<Map<String, dynamic>> fullList = [];
    if (dataStr != null) {
      fullList = List<Map<String, dynamic>>.from(json.decode(dataStr));
    }
    fullList.insert(0, newItem);
    await prefs.setString('local_catatan_servis', json.encode(fullList));
    return true;
  }
}
