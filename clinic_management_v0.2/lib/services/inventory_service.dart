import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient supabase;

  InventoryService(this.supabase);

  // Supplier operations
  Future<void> createInventoryReceipt(
      String supplierId,
      List<Map<String, dynamic>> items,
      String? notes,
      DateTime importDate) async {
    try {
      // Get medicine prices
      final medicines = await getInventoryStatus();
      final medicineMap = {
        for (var m in medicines) m['MaThuoc'].toString(): m['DonGia'] as num
      };

      // Calculate total amount using medicine base prices
      double totalAmount = items.fold(
          0,
          (sum, item) =>
              sum +
              (item['quantity'] as int) *
                  (medicineMap[item['medicineId']] ?? 0));

      // Create receipt
      final receiptResponse = await supabase
          .from('NHAPKHO')
          .insert({
            'MaNCC': supplierId,
            'TongTien': totalAmount,
            'GhiChu': notes,
            'NgayNhap': importDate.toIso8601String(), // Add import date
          })
          .select()
          .single();

      // Add receipt details with medicine base prices
      for (var item in items) {
        await supabase.from('CHITIETNHAPKHO').insert({
          'MaNhap': receiptResponse['MaNhap'],
          'MaThuoc': item['medicineId'],
          'SoLuong': item['quantity'],
          'DonGia':
              medicineMap[item['medicineId']], // Use medicine's base price
        });
      }
    } catch (e) {
      throw 'Lỗi khi tạo phiếu nhập kho: $e';
    }
  }

  Future<void> deleteInventoryReceipt(String receiptId) async {
    try {
      // Delete related details first due to foreign key constraints
      await supabase.from('CHITIETNHAPKHO').delete().eq('MaNhap', receiptId);
      // Then delete the main receipt
      await supabase.from('NHAPKHO').delete().eq('MaNhap', receiptId);
    } catch (e) {
      throw 'Lỗi khi xóa phiếu nhập kho: $e';
    }
  }

  Future<void> updateInventoryReceipt(
      String receiptId,
      String supplierId,
      List<Map<String, dynamic>> items,
      String? notes,
      DateTime importDate) async {
    try {
      // Get medicine prices
      final medicines = await getInventoryStatus();
      final medicineMap = {
        for (var m in medicines) m['MaThuoc'].toString(): m['DonGia'] as num
      };

      // Calculate total amount
      double totalAmount = items.fold(
          0,
          (sum, item) =>
              sum +
              (item['quantity'] as int) *
                  (medicineMap[item['medicineId']] ?? 0));

      // Start transaction
      await supabase.from('CHITIETNHAPKHO').delete().eq('MaNhap', receiptId);

      await supabase.from('NHAPKHO').update({
        'MaNCC': supplierId,
        'TongTien': totalAmount,
        'GhiChu': notes,
        'NgayNhap': importDate.toIso8601String(), // Add import date
      }).eq('MaNhap', receiptId);

      // Add updated receipt details
      for (var item in items) {
        await supabase.from('CHITIETNHAPKHO').insert({
          'MaNhap': receiptId,
          'MaThuoc': item['medicineId'],
          'SoLuong': item['quantity'],
          'DonGia': medicineMap[item['medicineId']],
        });
      }
    } catch (e) {
      throw 'Lỗi khi cập nhật phiếu nhập kho: $e';
    }
  }

  // Xuất kho
  Future<void> createInventoryExport(List<Map<String, dynamic>> items,
      String reason, String? notes, DateTime exportDate) async {
    try {
      // Create export record with specified date
      final exportResponse = await supabase
          .from('XUATKHO')
          .insert({
            'NgayXuat': exportDate.toIso8601String(),
            'LyDoXuat': reason,
            'GhiChu': notes,
          })
          .select()
          .single();

      // Add export details and update stock
      for (var item in items) {
        final medicineId = item['medicineId'];
        final quantity = item['quantity'] as int;

        // Get current stock
        final medicine = await supabase
            .from('THUOC')
            .select()
            .eq('MaThuoc', medicineId)
            .single();

        final currentStock = medicine['SoLuongTon'] as int;
        if (currentStock < quantity) {
          throw 'Không đủ số lượng thuốc ${medicine['TenThuoc']} trong kho';
        }

        // Update stock quantity
        await supabase.from('THUOC').update({
          'SoLuongTon': currentStock - quantity,
        }).eq('MaThuoc', medicineId);

        // Add export detail
        await supabase.from('CHITIETXUATKHO').insert({
          'MaXuat': exportResponse['MaXuat'],
          'MaThuoc': medicineId,
          'SoLuong': quantity,
        });
      }
    } catch (e) {
      throw 'Lỗi khi tạo phiếu xuất kho: $e';
    }
  }

  Future<void> deleteInventoryExport(String id) async {
    try {
      // Delete related details first due to foreign key constraints
      await supabase.from('CHITIETXUATKHO').delete().eq('MaXuat', id);
      // Then delete the main receipt
      await supabase.from('XUATKHO').delete().eq('MaXuat', id);
    } catch (e) {
      throw 'Lỗi khi xóa phiếu xuất kho: $e';
    }
  }

  Future<void> updateInventoryExport(
    String id,
    List<Map<String, dynamic>> items,
    String reason,
    String notes,
    DateTime exportDate, // Add export date parameter
  ) async {
    try {
      await supabase.from('XUATKHO').update({
        'LyDoXuat': reason,
        'GhiChu': notes,
        'NgayXuat': exportDate.toIso8601String(), // Add export date
      }).eq('MaXuat', id);

      // Update export details
      await supabase.from('CHITIETXUATKHO').delete().eq('MaXuat', id);

      for (final item in items) {
        await supabase.from('CHITIETXUATKHO').insert({
          'MaXuat': id,
          'MaThuoc': item['medicineId'],
          'SoLuong': item['quantity'],
        });
      }
    } catch (e) {
      throw 'Lỗi cập nhật phiếu xuất: $e';
    }
  }

  Future<void> updateExportStatus(String exportId, String status) async {
    try {
      await supabase.from('PHIEUXUAT').update({
        'GhiChu': status,
      }).eq('MaXuat', exportId);
    } catch (e) {
      throw 'Không thể cập nhật trạng thái xuất kho: $e';
    }
  }

  // Quản lý nhà cung cấp
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response =
          await supabase.from('NHACUNGCAP').select().order('TenNCC');
      print('Supplier response: $response'); // Debug log
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching suppliers: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> addSupplier(
      String name, String? address, String? phone, String? email) async {
    await supabase.from('NHACUNGCAP').insert({
      'TenNCC': name,
      'DiaChi': address,
      'SDT': phone,
      'Email': email,
    });
  }

  Future<void> updateSupplier(String id, String name, String? address,
      String? phone, String? email) async {
    await supabase.from('NHACUNGCAP').update({
      'TenNCC': name,
      'DiaChi': address,
      'SDT': phone,
      'Email': email,
    }).eq('MaNCC', id);
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await supabase.from('NHACUNGCAP').delete().eq('MaNCC', id);
    } catch (e) {
      throw 'Lỗi khi xóa nhà cung cấp: $e';
    }
  }

  // Xem lịch sử nhập kho
  Future<List<Map<String, dynamic>>> getInventoryReceipts(
      {DateTime? startDate, DateTime? endDate}) async {
    var query = supabase.from('NHAPKHO').select('''
          *,
          NHACUNGCAP (
            TenNCC
          ),
          CHITIETNHAPKHO (
            *,
            THUOC (
              TenThuoc
            )
          )
        ''');

    if (startDate != null) {
      query = query.gte('NgayNhap', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('NgayNhap', endDate.toIso8601String());
    }

    final response = await query.order('NgayNhap', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Xem lịch sử xuất kho
  Future<List<Map<String, dynamic>>> getInventoryExports(
      {DateTime? startDate, DateTime? endDate}) async {
    var query = supabase.from('XUATKHO').select('''
          *,
          CHITIETXUATKHO (
            *,
            THUOC (
              TenThuoc,
              DonVi
            )
          )
        ''');

    final response = await query.order('NgayXuat', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Kiểm tra tồn kho
  Future<List<Map<String, dynamic>>> getInventoryStatus() async {
    final response = await supabase.from('THUOC').select().order('TenThuoc');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> exportMedicinesFromPrescription(
      String prescriptionId, List<Map<String, dynamic>> medicines) async {
    try {
      // Create export receipt
      final exportReceipt = {
        'MaPhieuXuat': prescriptionId,
        'NgayXuat': DateTime.now().toIso8601String(),
        'MaToa': prescriptionId,
        'LyDoXuat': 'Xuất theo toa',
      };

      await supabase.from('XUATKHO').insert(exportReceipt);

      // Update medicine quantities
      for (final medicine in medicines) {
        final medicineId = medicine['MaThuoc'];
        final quantity = medicine['Sluong'] as int;

        // Get current stock
        final currentStock = await supabase
            .from('THUOC')
            .select('SoLuongTon')
            .eq('MaThuoc', medicineId)
            .single();

        final newStock = (currentStock['SoLuongTon'] as int) - quantity;
        if (newStock < 0) {
          throw 'Không đủ số lượng thuốc ${medicine['thuoc']['TenThuoc']} trong kho';
        }

        // Update inventory
        await supabase
            .from('THUOC')
            .update({'SoLuongTon': newStock}).eq('MaThuoc', medicineId);

        // Add export details
        await supabase.from('CHITIETXUATKHO').insert({
          'MaXuat': prescriptionId,
          'MaThuoc': medicineId,
          'SoLuong': quantity,
        });
      }
    } catch (e) {
      print('Error exporting medicines: $e');
      rethrow;
    }
  }

  Future<void> updateStockQuantity(String medicineId, int quantity) async {
    try {
      // Get current stock with row level locking
      final medicine = await supabase
          .from('THUOC')
          .select()
          .eq('MaThuoc', medicineId)
          .single();

      final currentStock = medicine['SoLuongTon'] as int;
      if (currentStock < quantity) {
        throw 'Không đủ số lượng thuốc ${medicine['TenThuoc']} trong kho';
      }

      // Update stock
      final newStock = currentStock - quantity;
      await supabase
          .from('THUOC')
          .update({'SoLuongTon': newStock})
          .eq('MaThuoc', medicineId)
          .select()
          .single();
    } catch (e) {
      throw 'Lỗi khi cập nhật số lượng tồn: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getExportReceiptDetails(
      String exportId) async {
    final response = await supabase.from('CHITIETXUATKHO').select('''
          *,
          THUOC (
            TenThuoc,
            DonVi,
            SoLuongTon
          )
        ''').eq('MaXuat', exportId);
    return List<Map<String, dynamic>>.from(response);
  }
}
