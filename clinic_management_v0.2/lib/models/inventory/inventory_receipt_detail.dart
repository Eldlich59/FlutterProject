class InventoryReceiptDetail {
  final String receiptId;
  final String medicineId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? supplierName;
  final String? medicineName;

  InventoryReceiptDetail({
    required this.receiptId,
    required this.medicineId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.supplierName,
    this.medicineName,
  });

  factory InventoryReceiptDetail.fromJson(Map<String, dynamic> json) {
    return InventoryReceiptDetail(
      receiptId: json['MaNhap'].toString(),
      medicineId: json['MaThuoc'].toString(),
      quantity: json['SoLuong'],
      unitPrice: (json['DonGia'] as num).toDouble(),
      totalPrice:
          ((json['SoLuong'] as num) * (json['DonGia'] as num)).toDouble(),
      medicineName: json['THUOC']?['TenThuoc'],
      supplierName: json['NHAPKHO']?['NHACUNGCAP']?['TenNCC'],
    );
  }
}
