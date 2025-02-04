import 'package:clinic_management/models/inventory/inventory_receipt_detail.dart';

class InventoryReceipt {
  final String id;
  final DateTime importDate;
  final String supplierId;
  final double totalAmount;
  final String? notes;
  final List<InventoryReceiptDetail> details;

  InventoryReceipt({
    required this.id,
    required this.importDate,
    required this.supplierId,
    required this.totalAmount,
    this.notes,
    required this.details,
  });

  factory InventoryReceipt.fromJson(Map<String, dynamic> json) {
    return InventoryReceipt(
      id: json['MaNhap'].toString(),
      importDate: DateTime.parse(json['NgayNhap']),
      supplierId: json['MaNCC'],
      totalAmount: (json['TongTien'] as num).toDouble(),
      notes: json['GhiChu'],
      details: (json['CHITIETNHAPKHO'] as List?)
              ?.map((detail) => InventoryReceiptDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  String? get supplierName =>
      (details.isNotEmpty && details.first.supplierName != null)
          ? details.first.supplierName
          : null;
}
