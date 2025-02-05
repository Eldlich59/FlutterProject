import 'package:clinic_management/models/inventory/inventory_export_detail.dart';

class InventoryExport {
  final String id;
  final DateTime exportDate;
  final String exportReason;
  final String? notes;
  final List<InventoryExportDetail> details;

  InventoryExport({
    required this.id,
    required this.exportDate,
    required this.exportReason,
    this.notes,
    required this.details,
  });

  factory InventoryExport.fromJson(Map<String, dynamic> json) {
    return InventoryExport(
      id: json['MaXuat'],
      exportDate: DateTime.parse(json['NgayXuat']),
      exportReason: json['LyDoXuat'],
      notes: json['GhiChu'],
      details: (json['CHITIETXUATKHO'] as List?)
              ?.map((detail) => InventoryExportDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaXuat': id,
      'NgayXuat': exportDate.toIso8601String(),
      'LyDoXuat': exportReason,
      'GhiChu': notes,
    };
  }
}
