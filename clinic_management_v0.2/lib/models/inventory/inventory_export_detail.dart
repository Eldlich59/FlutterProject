class InventoryExportDetail {
  final String exportId;
  final String medicineId;
  final int quantity;
  String? medicineName; // Thêm tên thuốc để hiển thị trong UI

  InventoryExportDetail({
    required this.exportId,
    required this.medicineId,
    required this.quantity,
    this.medicineName,
  });

  factory InventoryExportDetail.fromJson(Map<String, dynamic> json) {
    return InventoryExportDetail(
      exportId: json['MaXuat'],
      medicineId: json['MaThuoc'],
      quantity: json['SoLuong'],
      medicineName: json['THUOC']?['TenThuoc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaXuat': exportId,
      'MaThuoc': medicineId,
      'SoLuong': quantity,
    };
  }
}
