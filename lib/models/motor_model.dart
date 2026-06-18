class MotorModel {
  final String namaMotor;
  final String tahun;
  final String odometer;
  final String? fotoPath;

  MotorModel({
    required this.namaMotor,
    required this.tahun,
    required this.odometer,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'namaMotor': namaMotor,
      'tahun': tahun,
      'odometer': odometer,
      'fotoPath': fotoPath,
    };
  }

  factory MotorModel.fromMap(Map<String, dynamic> map) {
    return MotorModel(
      namaMotor: map['namaMotor'] ?? '',
      tahun: map['tahun'] ?? '',
      odometer: map['odometer'] ?? '',
      fotoPath: map['fotoPath'],
    );
  }
}
