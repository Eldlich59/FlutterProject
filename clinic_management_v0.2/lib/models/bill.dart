class Bill {
  final String id;
  final DateTime saleDate;
  final double medicineCost;
  final String prescriptionId;

  Bill({
    required this.id,
    required this.saleDate,
    required this.medicineCost,
    required this.prescriptionId,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['MaHD'],
      saleDate: DateTime.parse(
          json['Ngayban']), // Changed from 'NgayBan' to 'Ngayban'
      medicineCost: json['TienThuoc'].toDouble(),
      prescriptionId: json['MaToa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaHD': id,
      'Ngayban':
          saleDate.toIso8601String(), // Changed from 'NgayBan' to 'Ngayban'
      'TienThuoc': medicineCost,
      'MaToa': prescriptionId,
    };
  }
}
