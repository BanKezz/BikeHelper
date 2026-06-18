import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/motor_model.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';

class InputDataMotorScreen extends StatefulWidget {
  final bool isFirstTime;
  final MotorModel? existingData;

  const InputDataMotorScreen({
    super.key,
    this.isFirstTime = true,
    this.existingData,
  });

  @override
  State<InputDataMotorScreen> createState() => _InputDataMotorScreenState();
}

class _InputDataMotorScreenState extends State<InputDataMotorScreen> {
  final _namaController = TextEditingController();
  final _tahunController = TextEditingController();
  final _odometerController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _namaController.text = widget.existingData!.namaMotor;
      _tahunController.text = widget.existingData!.tahun;
      _odometerController.text = widget.existingData!.odometer;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tahunController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _handleSimpan() async {
    if (_namaController.text.isEmpty ||
        _tahunController.text.isEmpty ||
        _odometerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data motor wajib diisi'),
          backgroundColor: AppTheme.primaryBlack,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final motor = MotorModel(
      namaMotor: _namaController.text.trim(),
      tahun: _tahunController.text.trim(),
      odometer: _odometerController.text.trim(),
    );

    final success = await DatabaseService().saveMotor(motor);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (widget.isFirstTime) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DashboardScreen(motor: motor),
            ),
          );
        } else {
          // Jika ini proses edit dari Dashboard, kembali dan berikan data yang baru
          Navigator.of(context).pop(motor);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data motor. Silakan coba lagi.'),
            backgroundColor: AppTheme.primaryBlack,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: widget.isFirstTime
          ? null
          : AppBar(
              backgroundColor: AppTheme.surfaceGray,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Edit Data Motor',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Foto motor placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.cardGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Foto Motor',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              _buildLabelField(
                label: 'Nama Motor',
                controller: _namaController,
                hint: '...',
                inputType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              _buildLabelField(
                label: 'Tahun',
                controller: _tahunController,
                hint: '...',
                inputType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabelField(
                label: 'Jarak Tempuh (Odometer)',
                controller: _odometerController,
                hint: '...',
                inputType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffix: 'km',
              ),
              const SizedBox(height: 32),

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
                    : const Text('Simpan'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
