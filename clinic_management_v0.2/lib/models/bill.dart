class Bill {
  final String id;
  final DateTime saleDate;
  final double medicineCost;
  final String prescriptionId;
  final String patientName; // Add this field

  Bill({
    required this.id,
    required this.saleDate,
    required this.medicineCost,
    required this.prescriptionId,
    required this.patientName,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['MaHD'],
      saleDate: DateTime.parse(json['Ngaylap']),
      medicineCost: json['TienThuoc'].toDouble(),
      prescriptionId: json['MaToa'],
      patientName: json['TOATHUOC']?['BENHNHAN']?['TenBN'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaHD': id,
      'Ngaylap': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
      'MaToa': prescriptionId,
    };
  }
}
