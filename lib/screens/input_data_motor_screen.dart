import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/motor_model.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';

class InputDataMotorScreen extends StatefulWidget {
  final bool isFirstTime;
  final bool isAddNew; // mode tambah motor baru
  final MotorModel? existingData;

  const InputDataMotorScreen({
    super.key,
    this.isFirstTime = true,
    this.isAddNew = false,
    this.existingData,
  });

  @override
  State<InputDataMotorScreen> createState() => _InputDataMotorScreenState();
}

class _InputDataMotorScreenState extends State<InputDataMotorScreen>
    with SingleTickerProviderStateMixin {
  final _namaController = TextEditingController();
  final _tahunController = TextEditingController();
  final _odometerController = TextEditingController();
  final _platController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isEditMode => widget.existingData != null && !widget.isAddNew;

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
    _animController.forward();

    if (widget.existingData != null) {
      _namaController.text = widget.existingData!.namaMotor;
      _tahunController.text = widget.existingData!.tahun;
      _odometerController.text = widget.existingData!.odometer;
      _platController.text = widget.existingData!.platNomor ?? '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tahunController.dispose();
    _odometerController.dispose();
    _platController.dispose();
    _animController.dispose();
    super.dispose();
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

  void _handleSimpan() async {
    FocusScope.of(context).unfocus();
    if (_namaController.text.isEmpty ||
        _tahunController.text.isEmpty ||
        _odometerController.text.isEmpty) {
      _showSnackBar('Nama motor, tahun, dan odometer wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    final motor = MotorModel(
      id: _isEditMode ? widget.existingData!.id : null,
      namaMotor: _namaController.text.trim(),
      tahun: _tahunController.text.trim(),
      odometer: _odometerController.text.trim(),
      platNomor: _platController.text.trim().isEmpty
          ? null
          : _platController.text.trim(),
    );

    bool success;
    if (_isEditMode) {
      success = await DatabaseService().saveMotor(motor);
    } else {
      // Tambah motor baru
      success = await DatabaseService().addMotor(motor);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (widget.isFirstTime || widget.isAddNew) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DashboardScreen(motor: motor),
            ),
          );
        } else {
          Navigator.of(context).pop(motor);
        }
      } else {
        _showSnackBar('Gagal menyimpan data motor. Silakan coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode
        ? 'Edit Data Motor'
        : widget.isAddNew
            ? 'Tambah Motor Baru'
            : 'Data Motor Kamu';

    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGray,
        elevation: 0,
        leading: (widget.isFirstTime && !widget.isAddNew)
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                if (widget.isFirstTime && !widget.isAddNew) ...[
                  Text(
                    'Lengkapi Data Motormu',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kami butuh info ini untuk melacak\nperawatan motormu',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                ],

                // Foto placeholder
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.subtleShadow,
                    border: Border.all(color: AppTheme.borderGray),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bike_rounded,
                          size: 44, color: AppTheme.textHint),
                      const SizedBox(height: 4),
                      Text(
                        'Foto Motor',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Form card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelField(
                        label: 'Nama Motor',
                        controller: _namaController,
                        hint: 'cth: Honda Beat, Yamaha NMAX',
                        icon: Icons.directions_bike_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildLabelField(
                        label: 'Plat Nomor',
                        controller: _platController,
                        hint: 'cth: B 1234 ABC (opsional)',
                        icon: Icons.credit_card_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildLabelField(
                        label: 'Tahun',
                        controller: _tahunController,
                        hint: 'cth: 2022',
                        icon: Icons.calendar_month_outlined,
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabelField(
                        label: 'Odometer Saat Ini',
                        controller: _odometerController,
                        hint: 'cth: 12500',
                        icon: Icons.speed_outlined,
                        inputType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        suffix: 'km',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSimpan,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Tambahkan Motor',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
