class Bill {
  final String id;
  final String prescriptionId;
  final DateTime saleDate;
  final double medicineCost;
  final String patientName;
  final double? examinationCost;
  final String? examinationId;

  Bill({
    required this.id,
    required this.prescriptionId,
    required this.saleDate,
    required this.medicineCost,
    required this.patientName,
    this.examinationCost,
    this.examinationId,
  });

  double get totalCost => medicineCost + (examinationCost ?? 0);

  factory Bill.fromJson(Map<String, dynamic> json) {
    final prescription = json['TOATHUOC'] as Map<String, dynamic>;
    final patient = prescription['BENHNHAN'] as Map<String, dynamic>;
    final examination = prescription['PHIEUKHAM'] as Map<String, dynamic>?;

    // Helper function to safely convert numeric values to double
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return null;
    }

    return Bill(
      id: json['MaHD'].toString(), // Convert int to String
      prescriptionId: json['MaToa'].toString(), // Convert int to String
      saleDate: DateTime.parse(json['Ngaylap']),
      medicineCost: toDouble(json['TienThuoc']) ?? 0.0,
      patientName: patient['TenBN'],
      examinationCost: toDouble(examination?['TienKham']),
      examinationId: examination?['MaPK']?.toString(), // Convert int to String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaHD': int.parse(id), // Convert String back to int
      'Ngaylap': saleDate.toIso8601String(),
      'TongTien': totalCost,
      'MaToa': int.parse(prescriptionId), // Convert String back to int
    };
  }
}
