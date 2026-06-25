import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/motor_model.dart';
import '../services/database_service.dart';
import 'input_data_motor_screen.dart';
import 'dashboard_screen.dart';

class MotorListScreen extends StatefulWidget {
  final bool isFirstTime;

  const MotorListScreen({super.key, this.isFirstTime = false});

  @override
  State<MotorListScreen> createState() => _MotorListScreenState();
}

class _MotorListScreenState extends State<MotorListScreen>
    with SingleTickerProviderStateMixin {
  List<MotorModel> _motors = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _loadMotors();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMotors() async {
    setState(() => _isLoading = true);
    final motors = await DatabaseService().getAllMotors();
    if (mounted) {
      setState(() {
        _motors = motors;
        _isLoading = false;
      });
      _animController.forward(from: 0);
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

  Future<void> _deleteMotor(MotorModel motor) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Motor',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Yakin ingin menghapus "${motor.namaMotor}"?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 40),
              backgroundColor: const Color(0xFFB71C1C),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Hapus',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (konfirmasi == true && motor.id != null) {
      final success = await DatabaseService().deleteMotor(motor.id!);
      if (success) {
        _showSnackBar('Motor berhasil dihapus');
        await _loadMotors();
      } else {
        _showSnackBar('Gagal menghapus motor');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text(
          widget.isFirstTime ? 'Motor Saya' : 'Daftar Motor',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceGray,
        elevation: 0,
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlack))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _motors.isEmpty
                  ? _buildEmptyState()
                  : _buildMotorList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const InputDataMotorScreen(
                isFirstTime: false,
                isAddNew: true,
              ),
            ),
          );
          await _loadMotors();
        },
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Motor',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.cardGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bike_outlined,
                size: 40, color: AppTheme.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada motor',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan motor pertamamu\nmenggunakan tombol di bawah',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMotorList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _motors.length,
      itemBuilder: (context, i) {
        return _buildMotorCard(_motors[i], i);
      },
    );
  }

  Widget _buildMotorCard(MotorModel motor, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - val)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(motor: motor),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Ikon motor
                Container(
                  width: 56,
                  height: 56,
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
                    children: [
                      Text(
                        motor.namaMotor,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (motor.platNomor != null && motor.platNomor!.isNotEmpty)
                        Text(
                          motor.platNomor!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _infoChip(Icons.calendar_today_outlined,
                              motor.tahun),
                          const SizedBox(width: 8),
                          _infoChip(Icons.speed_outlined,
                              '${motor.odometer} km'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Aksi
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InputDataMotorScreen(
                              isFirstTime: false,
                              existingData: motor,
                            ),
                          ),
                        );
                        await _loadMotors();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.statusWarning, size: 20),
                      onPressed: () => _deleteMotor(motor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
