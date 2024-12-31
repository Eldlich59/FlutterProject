class Invoice {
  final String id; // MaHD
  final DateTime date; // Ngayban
  final double amount; // TienThuoc
  final String prescriptionId; // MaToa
  final List<InvoiceDetail>? details; // Optional details of the invoice

  Invoice({
    required this.id,
    required this.date,
    required this.amount,
    required this.prescriptionId,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'MaHD': id,
        'Ngayban': date.toIso8601String(),
        'TienThuoc': amount,
        'MaToa': prescriptionId,
        if (details != null)
          'details': details!.map((detail) => detail.toJson()).toList(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['MaHD'],
        date: DateTime.parse(json['Ngayban']),
        amount: json['TienThuoc']?.toDouble() ?? 0.0,
        prescriptionId: json['MaToa'],
        details: json['details'] != null
            ? (json['details'] as List)
                .map((detail) => InvoiceDetail.fromJson(detail))
                .toList()
            : null,
      );

  Invoice copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? prescriptionId,
    List<InvoiceDetail>? details,
  }) {
    return Invoice(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      details: details ?? this.details,
    );
  }

  @override
  String toString() {
    return 'Invoice{id: $id, date: $date, amount: $amount, prescriptionId: $prescriptionId}';
  }
}

class InvoiceDetail {
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceDetail({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
        'medicineId': medicineId,
        'medicineName': medicineName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
        medicineId: json['medicineId'],
        medicineName: json['medicineName'],
        quantity: json['quantity'],
        unitPrice: json['unitPrice']?.toDouble() ?? 0.0,
        totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      );

  InvoiceDetail copyWith({
    String? medicineId,
    String? medicineName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return InvoiceDetail(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
