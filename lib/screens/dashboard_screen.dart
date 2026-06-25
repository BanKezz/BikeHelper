import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/motor_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'motor_list_screen.dart';
import 'input_data_motor_screen.dart';

class DashboardScreen extends StatefulWidget {
  final MotorModel motor;

  const DashboardScreen({super.key, required this.motor});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late MotorModel _currentMotor;
  List<Map<String, dynamic>> _jadwalServis = [];
  List<Map<String, dynamic>> _catatanServis = [];
  bool _isLoadingData = true;
  String _username = 'User';
  late AnimationController _navAnimController;

  final List<Map<String, dynamic>> _statusKomponen = [
    {'nama': 'Oli Mesin', 'status': 'Baik', 'isGood': true},
    {'nama': 'Filter Oli', 'status': 'Baik', 'isGood': true},
    {'nama': 'Ban', 'status': 'Cek Segera', 'isGood': false},
  ];

  @override
  void initState() {
    super.initState();
    _currentMotor = widget.motor;
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadData();
    _loadUsername();
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final name = await AuthService().getCurrentUsername();
    if (mounted) setState(() => _username = name);
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    final db = DatabaseService();
    final jadwal = await db.getJadwalServis();
    final catatan = await db.getCatatanServis();
    if (mounted) {
      setState(() {
        _jadwalServis = jadwal;
        _catatanServis = catatan;
        _isLoadingData = false;
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppTheme.primaryBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildJadwalTab(),
          _buildCatatanTab(),
          _buildFavoriteTab(),
          _buildProfilTab(),
        ],
      ),
      floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: AppTheme.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, size: 28),
              onPressed: () {
                if (_selectedIndex == 1) {
                  _showTambahJadwalDialog();
                } else {
                  _showTambahCatatanDialog();
                }
              },
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Beranda', 'Jadwal Servis', 'Catatan Servis', 'Favorit', 'Profil'];
    return AppBar(
      backgroundColor: AppTheme.surfaceGray,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        _selectedIndex == 0 ? 'BikeHelpers' : titles[_selectedIndex],
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        if (_selectedIndex == 0)
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.textPrimary),
            onPressed: () => _showSnackBar('Belum ada notifikasi baru'),
          ),
      ],
    );
  }

  // =====================
  // HOME TAB
  // =====================

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingCard(),
          const SizedBox(height: 14),
          _buildStatusMotorCard(),
          const SizedBox(height: 14),
          _buildPengingatCard(),
          const SizedBox(height: 14),
          _buildShortcutCard(),
          const SizedBox(height: 14),
          _buildInfoMotorCard(),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_username! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Motor kamu butuh perhatian hari ini?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bike_rounded,
                color: AppTheme.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMotorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Motor',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentMotor.namaMotor,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_bike_rounded,
                    color: AppTheme.primaryBlack, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _statusKomponen.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item['isGood']
                                  ? AppTheme.statusGood
                                  : AppTheme.statusWarning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${item['nama']}:  ',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                          Text(
                            item['status'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item['isGood']
                                  ? AppTheme.statusGood
                                  : AppTheme.statusWarning,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPengingatCard() {
    final sisaKm = _jadwalServis.isNotEmpty
        ? (_jadwalServis[0]['sisaKm'] ?? _jadwalServis[0]['sisa_km'] ?? '...')
        : '...';
    final komponen = _jadwalServis.isNotEmpty
        ? (_jadwalServis[0]['komponen'] ?? 'Servis')
        : 'Servis';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    size: 18, color: AppTheme.statusWarning),
              ),
              const SizedBox(width: 10),
              Text(
                'Pengingat Servis',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _jadwalServis.isNotEmpty
                ? '$komponen dalam $sisaKm Km'
                : 'Tidak ada jadwal servis terdekat',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              child: Text('Lihat Jadwal',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akses Cepat',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildShortcutItem(
                icon: Icons.calendar_today_rounded,
                label: 'Jadwal\nServis',
                onTap: () => setState(() => _selectedIndex = 1),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildShortcutItem(
                icon: Icons.assignment_rounded,
                label: 'Catatan\nServis',
                onTap: () => setState(() => _selectedIndex = 2),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildShortcutItem(
                icon: Icons.directions_bike_rounded,
                label: 'Motor\nSaya',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MotorListScreen(),
                    ),
                  );
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: AppTheme.primaryBlack),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMotorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Info Motor',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              GestureDetector(
                onTap: () async {
                  final updatedMotor =
                      await Navigator.of(context).push<MotorModel>(
                    MaterialPageRoute(
                      builder: (_) => InputDataMotorScreen(
                        isFirstTime: false,
                        existingData: _currentMotor,
                      ),
                    ),
                  );
                  if (updatedMotor != null) {
                    setState(() => _currentMotor = updatedMotor);
                  }
                },
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Nama Motor', _currentMotor.namaMotor),
          if (_currentMotor.platNomor != null && _currentMotor.platNomor!.isNotEmpty)
            _infoRow('Plat Nomor', _currentMotor.platNomor!),
          _infoRow('Tahun', _currentMotor.tahun),
          _infoRow('Odometer', '${_currentMotor.odometer} km'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  // =====================
  // JADWAL TAB
  // =====================

  Widget _buildJadwalTab() {
    if (_isLoadingData) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlack));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (_jadwalServis.isEmpty)
          _buildEmptyListState('Belum ada jadwal servis.',
              'Tambah jadwal dengan tombol + di bawah')
        else
          ..._jadwalServis.asMap().entries.map((e) =>
              _buildJadwalItem(e.value, e.key)),
      ],
    );
  }

  Widget _buildJadwalItem(Map<String, dynamic> item, int index) {
    final sisaKm = item['sisaKm'] ?? item['sisa_km'] ?? '...';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 60),
      curve: Curves.easeOut,
      builder: (_, val, child) =>
          Opacity(opacity: val, child: Transform.translate(
            offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.build_rounded,
                  size: 20, color: AppTheme.primaryBlack),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['komponen'] ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.speed_outlined,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text('Sisa $sisaKm km',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(item['tanggal'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // =====================
  // CATATAN TAB
  // =====================

  Widget _buildCatatanTab() {
    if (_isLoadingData) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlack));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (_catatanServis.isEmpty)
          _buildEmptyListState('Belum ada catatan servis.',
              'Tambah catatan dengan tombol + di bawah')
        else
          ..._catatanServis.asMap().entries.map((e) => _buildCatatanItem(
              e.value['komponen'] ?? '',
              e.value['tanggal'] ?? '',
              e.value['odometer'] ?? '',
              e.key)),
      ],
    );
  }

  Widget _buildCatatanItem(
      String komponen, String tanggal, String odometer, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 60),
      curve: Curves.easeOut,
      builder: (_, val, child) =>
          Opacity(opacity: val, child: Transform.translate(
            offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.statusGood.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppTheme.statusGood),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(komponen,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(tanggal,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.speed_outlined,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(odometer,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.cardGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 32, color: AppTheme.textHint),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // =====================
  // FAVORIT TAB
  // =====================

  Widget _buildFavoriteTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.cardGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 36, color: AppTheme.textHint),
          ),
          const SizedBox(height: 16),
          Text('Belum ada bengkel favorit',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Fitur ini akan segera hadir',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // =====================
  // PROFIL TAB
  // =====================

  Widget _buildProfilTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // Avatar
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlack.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    size: 40, color: AppTheme.white),
              ),
              const SizedBox(height: 12),
              Text(
                _username,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pengguna BikeHelpers',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Divider section
        _buildSectionLabel('Motor'),
        _buildProfilMenuItem(
          icon: Icons.directions_bike_outlined,
          label: 'Daftar Motor Saya',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MotorListScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('Pengaturan'),
        _buildProfilMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Pengaturan Notifikasi',
          onTap: () => _showSnackBar('Fitur dalam pengembangan'),
        ),
        _buildProfilMenuItem(
          icon: Icons.lock_outline,
          label: 'Ubah Password',
          onTap: () => _showSnackBar('Fitur dalam pengembangan'),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('Akun'),
        _buildProfilMenuItem(
          icon: Icons.logout_rounded,
          label: 'Keluar',
          isDestructive: true,
          onTap: () async {
            final konfirmasi = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                content: Text(
                  'Yakin ingin keluar dari akun $_username?',
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Batal',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      backgroundColor: const Color(0xFFB71C1C),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Keluar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );

            if (konfirmasi == true && mounted) {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfilMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFB71C1C) : AppTheme.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDestructive
                ? const Color(0xFFB71C1C).withValues(alpha: 0.08)
                : AppTheme.surfaceGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: color),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textHint, size: 20),
        onTap: onTap,
      ),
    );
  }

  // =====================
  // BOTTOM NAV
  // =====================

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded, 'label': 'Jadwal'},
      {'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment_rounded, 'label': 'Catatan'},
      {'icon': Icons.favorite_border_rounded, 'activeIcon': Icons.favorite_rounded, 'label': 'Favorit'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlack.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isSelected
                              ? items[index]['activeIcon'] as IconData
                              : items[index]['icon'] as IconData,
                          color: isSelected
                              ? AppTheme.primaryBlack
                              : AppTheme.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[index]['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primaryBlack
                              : AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // =====================
  // DIALOGS
  // =====================

  void _showTambahJadwalDialog() {
    final komponenController = TextEditingController();
    final sisaKmController = TextEditingController();
    final tanggalController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Jadwal Servis',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField('Komponen',
                  controller: komponenController,
                  hint: 'cth: Ganti Oli'),
              const SizedBox(height: 12),
              _dialogField('Sisa Kilometer',
                  controller: sisaKmController,
                  hint: 'cth: 500',
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _dialogField('Tanggal Target',
                  controller: tanggalController,
                  hint: 'cth: 25 Jul 2025'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
            onPressed: () async {
              if (komponenController.text.isNotEmpty &&
                  sisaKmController.text.isNotEmpty &&
                  tanggalController.text.isNotEmpty) {
                Navigator.of(ctx).pop();
                setState(() => _isLoadingData = true);
                await DatabaseService().addJadwalServis(
                  komponenController.text.trim(),
                  sisaKmController.text.trim(),
                  tanggalController.text.trim(),
                );
                await _loadData();
              }
            },
            child: Text('Simpan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTambahCatatanDialog() {
    final komponenController = TextEditingController();
    final tanggalController = TextEditingController();
    final odometerController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Catatan Servis',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField('Komponen',
                  controller: komponenController,
                  hint: 'cth: Ganti Oli'),
              const SizedBox(height: 12),
              _dialogField('Tanggal',
                  controller: tanggalController,
                  hint: 'cth: 10 Jan 2025'),
              const SizedBox(height: 12),
              _dialogField('Odometer',
                  controller: odometerController,
                  hint: 'cth: 12.500 km'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
            onPressed: () async {
              if (komponenController.text.isNotEmpty &&
                  tanggalController.text.isNotEmpty &&
                  odometerController.text.isNotEmpty) {
                Navigator.of(ctx).pop();
                setState(() => _isLoadingData = true);
                await DatabaseService().addCatatanServis(
                  komponenController.text.trim(),
                  tanggalController.text.trim(),
                  odometerController.text.trim(),
                );
                await _loadData();
              }
            },
            child: Text('Simpan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    String label, {
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}