class SupabaseConfig {
  // Ganti dengan URL proyek Supabase Anda
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  // Ganti dengan Anon Key proyek Supabase Anda
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Cek apakah kredensial sudah diisi dengan benar
  static bool get isValid {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('YOUR_PROJECT_ID') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}
