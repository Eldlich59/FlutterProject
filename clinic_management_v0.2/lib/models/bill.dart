class Bill {
  final String id;
  final List<String> prescriptionIds;
  final String? prescriptionId;
  final DateTime saleDate;
  final double medicineCost;
  final List<String> patientNames;
  final double? examinationCost;
  final String? examinationId;

  Bill({
    required this.id,
    this.prescriptionIds = const [], // Make optional with default empty list
    this.prescriptionId,
    required this.saleDate,
    required this.medicineCost,
    List<String>? patientNames, // Make optional
    this.examinationCost,
    this.examinationId,
  }) : this.patientNames =
            patientNames ?? []; // Initialize with empty list if null

  String get patientName =>
      patientNames.isNotEmpty ? patientNames.join(', ') : 'Không có tên';

  double get totalCost => medicineCost + (examinationCost ?? 0);

  factory Bill.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return null;
    }

    // Safely handle bill ID
    String getBillId(dynamic value) {
      if (value == null) return '';
      if (value is int) return value.toString();
      if (value is String) return value;
      return value.toString();
    }

    List<dynamic> billDetails = json['bill_details'] ?? [];
    List<String> prescriptionIds = [];
    List<String> patientNames = [];

    for (var detail in billDetails) {
      var prescription = detail['prescriptions'];
      if (prescription != null) {
        var prescriptionId = prescription['MaToa']?.toString();
        if (prescriptionId != null) {
          prescriptionIds.add(prescriptionId);
        }

        var patient = prescription['BENHNHAN'];
        if (patient != null) {
          String? patientName = patient['TenBN']?.toString();
          if (patientName != null &&
              patientName.isNotEmpty &&
              !patientNames.contains(patientName)) {
            patientNames.add(patientName);
          }
        }
      }
    }

    final firstDetail = billDetails.isNotEmpty ? billDetails.first : null;
    final firstPrescription = firstDetail?['prescriptions'];
    final examination = firstPrescription?['PHIEUKHAM'];

    // Calculate costs
    final totalCost = toDouble(json['TongTien']) ?? 0.0;
    final examinationCost = toDouble(examination?['TienKham']);
    final medicineCost = totalCost - (examinationCost ?? 0.0);

    return Bill(
      id: getBillId(json['MaHD']),
      prescriptionIds: prescriptionIds,
      prescriptionId: prescriptionIds.isNotEmpty ? prescriptionIds.first : null,
      saleDate:
          DateTime.parse(json['Ngaylap'] ?? DateTime.now().toIso8601String()),
      medicineCost: medicineCost,
      patientNames: patientNames,
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
