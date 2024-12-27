class Patient {
  final String maBN;
  final String tenBN;
  final DateTime ngaySinh;
  final String gioiTinh;
  final String? diaChi;
  final String? sdt;

  Patient({
    required this.maBN,
    required this.tenBN,
    required this.ngaySinh,
    required this.gioiTinh,
    this.diaChi,
    this.sdt,
  });

  Map<String, dynamic> toMap() {
    return {
      'MaBN': maBN,
      'TenBN': tenBN,
      'NgaySinh': ngaySinh.toIso8601String(),
      'GioiTinh': gioiTinh,
      'DiaChi': diaChi,
      'SDT': sdt,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      maBN: map['MaBN'] as String,
      tenBN: map['TenBN'] as String,
      ngaySinh: DateTime.parse(map['NgaySinh'] as String),
      gioiTinh: map['GioiTinh'] as String,
      diaChi: map['DiaChi'] as String?,
      sdt: map['SDT'] as String?,
    );
  }

  Patient copyWith({
    String? maBN,
    String? tenBN,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? diaChi,
    String? sdt,
  }) =>
      Patient(
        maBN: maBN ?? this.maBN,
        tenBN: tenBN ?? this.tenBN,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        diaChi: diaChi ?? this.diaChi,
        sdt: sdt ?? this.sdt,
      );

  @override
  String toString() =>
      'Patient{maBN: $maBN, tenBN: $tenBN, ngaySinh: $ngaySinh, gioiTinh: $gioiTinh, diaChi: $diaChi, sdt: $sdt}';
}
