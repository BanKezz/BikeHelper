import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/motor_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'input_data_motor_screen.dart';

class DashboardScreen extends StatefulWidget {
  final MotorModel motor;

  const DashboardScreen({super.key, required this.motor});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late MotorModel _currentMotor;
  List<Map<String, dynamic>> _jadwalServis = [];
  List<Map<String, dynamic>> _catatanServis = [];
  bool _isLoadingData = true;

  final List<Map<String, dynamic>> _statusKomponen = [
    {'nama': 'Oli Mesin', 'status': 'Baik', 'isGood': true},
    {'nama': 'Filter Oli', 'status': 'Baik', 'isGood': true},
    {'nama': 'Ban', 'status': 'Cek Segera', 'isGood': false},
  ];

  @override
  void initState() {
    super.initState();
    _currentMotor = widget.motor;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    final db = DatabaseService();
    final jadwal = await db.getJadwalServis();
    final catatan = await db.getCatatanServis();
    setState(() {
      _jadwalServis = jadwal;
      _catatanServis = catatan;
      _isLoadingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGray,
        elevation: 0,
        title: const Text(
          'BikeHelpers',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
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
              elevation: 2,
              child: const Icon(Icons.add),
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

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusMotorCard(),
          const SizedBox(height: 14),
          _buildPengingatCard(),
          const SizedBox(height: 14),
          _buildShortcutCard(),
          const SizedBox(height: 14),
          _buildInfoMotorCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusMotorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Motor Anda',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.borderGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined, color: AppTheme.textHint, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _statusKomponen.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Text('${item['nama']}: ',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            item['status'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item['isGood'] ? AppTheme.statusGood : AppTheme.statusWarning,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengingat Penting',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            _jadwalServis.isNotEmpty
                ? '$komponen dalam $sisaKm Km'
                : 'Tidak ada jadwal servis terdekat',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 42)),
              child: const Text('Lihat Selengkapnya'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.borderGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, size: 24, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text('Jadwal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.borderGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_outlined, size: 24, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text('Catatan\nServis',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 42)),
              child: const Text('Lihat Jadwal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMotorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Info Motor',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _infoRow('Nama Motor', _currentMotor.namaMotor),
          _infoRow('Tahun', _currentMotor.tahun),
          _infoRow('Odometer', '${_currentMotor.odometer} km'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildJadwalTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlack));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Jadwal Servis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        if (_jadwalServis.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Belum ada jadwal servis.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          )
        else
          ..._jadwalServis.map((item) => _buildJadwalItem(item)),
      ],
    );
  }

  Widget _buildJadwalItem(Map<String, dynamic> item) {
    final sisaKm = item['sisaKm'] ?? item['sisa_km'] ?? '...';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardGray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.borderGray, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.build_outlined, size: 22, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['komponen'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Sisa $sisaKm km  •  ${item['tanggal'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _buildCatatanTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlack));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Catatan Servis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        if (_catatanServis.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Belum ada catatan servis.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          )
        else
          ..._catatanServis.map((item) => _buildCatatanItem(
                item['komponen'] ?? '',
                item['tanggal'] ?? '',
                item['odometer'] ?? '',
              )),
      ],
    );
  }

  Widget _buildCatatanItem(String komponen, String tanggal, String odometer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardGray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.borderGray, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_outline, size: 22, color: AppTheme.statusGood),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(komponen,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('$tanggal  •  $odometer',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTab() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 48, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Belum ada bengkel favorit',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfilTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppTheme.cardGray, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, size: 40, color: AppTheme.textHint),
          ),
        ),
        const SizedBox(height: 20),
        _buildProfilMenuItem(
          icon: Icons.directions_bike_outlined,
          label: 'Data Motor',
          onTap: () async {
            final updatedMotor = await Navigator.of(context).push<MotorModel>(
              MaterialPageRoute(
                builder: (_) => InputDataMotorScreen(
                  isFirstTime: false,
                  existingData: _currentMotor,
                ),
              ),
            );
            if (updatedMotor != null) {
              setState(() {
                _currentMotor = updatedMotor;
              });
            }
          },
        ),
        _buildProfilMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Pengaturan Notifikasi',
          onTap: () {},
        ),
        _buildProfilMenuItem(
          icon: Icons.lock_outline,
          label: 'Ubah Password',
          onTap: () {},
        ),
        // ====================================
        // LOGOUT -- memanggil AuthService
        // ====================================
        _buildProfilMenuItem(
          icon: Icons.logout,
          label: 'Keluar',
          onTap: () async {
            // Tampilkan dialog konfirmasi dulu
            final konfirmasi = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.white,
                title: const Text(
                  'Keluar',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                content: const Text(
                  'Yakin ingin keluar dari akun?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );

            if (konfirmasi == true && mounted) {
              await AuthService().logout();
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

  Widget _buildProfilMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppTheme.cardGray, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textPrimary, size: 22),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today},
      {'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment},
      {'icon': Icons.favorite_border, 'activeIcon': Icons.favorite},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 48,
                  height: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected
                            ? items[index]['activeIcon'] as IconData
                            : items[index]['icon'] as IconData,
                        color: isSelected ? AppTheme.primaryBlack : AppTheme.textHint,
                        size: 24,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlack,
                            shape: BoxShape.circle,
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

  void _showTambahJadwalDialog() {
    final komponenController = TextEditingController();
    final sisaKmController = TextEditingController();
    final tanggalController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.white,
        title: const Text('Tambah Jadwal Servis', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: komponenController,
                decoration: const InputDecoration(hintText: 'Komponen (cth: Ganti Oli)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sisaKmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Sisa Kilometer (cth: 500)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tanggalController,
                decoration: const InputDecoration(hintText: 'Tanggal Target (cth: 25 Jul 2025)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
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
            child: const Text('Simpan'),
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
        title: const Text('Tambah Catatan Servis', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: komponenController,
                decoration: const InputDecoration(hintText: 'Komponen (cth: Ganti Oli)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tanggalController,
                decoration: const InputDecoration(hintText: 'Tanggal (cth: 10 Jan 2025)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: odometerController,
                decoration: const InputDecoration(hintText: 'Odometer saat servis (cth: 12.500 km)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}