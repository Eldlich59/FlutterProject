class Bill {
  final String id;
  final List<String> prescriptionIds; // Changed from single prescriptionId
  final String? prescriptionId;
  final DateTime saleDate;
  final double medicineCost;
  final String patientName;
  final double? examinationCost;
  final String? examinationId;

  Bill({
    required this.id,
    required this.prescriptionIds, // Changed
    required this.prescriptionId,
    required this.saleDate,
    required this.medicineCost,
    required this.patientName,
    this.examinationCost,
    this.examinationId,
  });

  double get totalCost => medicineCost + (examinationCost ?? 0);

  factory Bill.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return null;
    }

    // Parse prescriptions data
    List<dynamic> prescriptions = [];
    if (json['prescriptions'] != null) {
      prescriptions = json['prescriptions'] is List
          ? json['prescriptions'] as List
          : [json['prescriptions']];
    }

    // Get patient and examination data from first prescription
    final firstPrescription =
        prescriptions.isNotEmpty ? prescriptions.first : null;
    final patient = firstPrescription?['BENHNHAN'] as Map<String, dynamic>?;
    final examination =
        firstPrescription?['PHIEUKHAM'] as Map<String, dynamic>?;

    // Calculate costs
    final totalCost = toDouble(json['TongTien']) ?? 0.0;
    final examinationCost = toDouble(examination?['TienKham']);
    final medicineCost = totalCost - (examinationCost ?? 0.0);

    // Parse MaToa array
    List<String> prescriptionIds = [];
    if (prescriptions.isNotEmpty) {
      prescriptionIds = prescriptions
          .map((p) => p['MaToa'].toString())
          .where((id) => id.isNotEmpty)
          .toList();
    }

    return Bill(
      id: json['MaHD']?.toString() ?? '',
      prescriptionIds: prescriptionIds,
      prescriptionId: prescriptionIds.isNotEmpty ? prescriptionIds.first : null,
      saleDate: DateTime.parse(json['Ngaylap']),
      medicineCost: medicineCost,
      patientName: patient?['TenBN'] ?? '',
      examinationCost: examinationCost,
      examinationId: examination?['MaPK']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaHD': id,
      'Ngaylap': saleDate.toIso8601String(),
      'TongTien': totalCost,
      'MaToa': prescriptionIds, // Changed
    };
  }
}
