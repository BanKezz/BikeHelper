class MotorModel {
  final String? id;
  final String namaMotor;
  final String tahun;
  final String odometer;
  final String? platNomor;
  final String? fotoPath;

  MotorModel({
    this.id,
    required this.namaMotor,
    required this.tahun,
    required this.odometer,
    this.platNomor,
    this.fotoPath,
  });

  MotorModel copyWith({
    String? id,
    String? namaMotor,
    String? tahun,
    String? odometer,
    String? platNomor,
    String? fotoPath,
  }) {
    return MotorModel(
      id: id ?? this.id,
      namaMotor: namaMotor ?? this.namaMotor,
      tahun: tahun ?? this.tahun,
      odometer: odometer ?? this.odometer,
      platNomor: platNomor ?? this.platNomor,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaMotor': namaMotor,
      'tahun': tahun,
      'odometer': odometer,
      'platNomor': platNomor,
      'fotoPath': fotoPath,
    };
  }

  factory MotorModel.fromMap(Map<String, dynamic> map) {
    return MotorModel(
      id: map['id']?.toString(),
      namaMotor: map['namaMotor'] ?? map['nama_motor'] ?? '',
      tahun: map['tahun'] ?? '',
      odometer: map['odometer'] ?? '',
      platNomor: map['platNomor'] ?? map['plat_nomor'],
      fotoPath: map['fotoPath'] ?? map['foto_path'],
    );
  }
}
