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

    final totalCost = toDouble(json['TongTien']) ?? 0.0;
    final examinationCost = toDouble(examination?['TienKham']);

    // Calculate medicine cost by subtracting examination cost from total
    final medicineCost = totalCost - (examinationCost ?? 0.0);

    return Bill(
      id: json['MaHD']?.toString() ?? '',
      prescriptionId: json['MaToa']?.toString() ?? '',
      saleDate: DateTime.parse(json['Ngaylap']),
      medicineCost: medicineCost,
      patientName: patient['TenBN'],
      examinationCost: examinationCost,
      examinationId: examination?['MaPK']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaHD': id, // Don't parse to int, let database handle it
      'Ngaylap': saleDate.toIso8601String(),
      'TongTien': totalCost,
      'MaToa': prescriptionId,
    };
  }
}
