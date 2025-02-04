import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient supabase;

  InventoryService(this.supabase);

  // Supplier operations
  Future<void> createInventoryReceipt(String supplierId,
      List<Map<String, dynamic>> items, String? notes) async {
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

  Future<void> updateInventoryReceipt(String receiptId, String supplierId,
      List<Map<String, dynamic>> items, String? notes) async {
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
  Future<void> createInventoryExport(
      List<Map<String, dynamic>> items, String reason, String? notes) async {
    try {
      // Create export record
      final exportResponse = await supabase
          .from('XUATKHO')
          .insert({
            'LyDoXuat': reason,
            'GhiChu': notes,
          })
          .select()
          .single();

      // Add export details
      for (var item in items) {
        await supabase.from('CHITIETXUATKHO').insert({
          'MaXuat': exportResponse['MaXuat'],
          'MaThuoc': item['medicineId'],
          'SoLuong': item['quantity'],
        });
      }
    } catch (e) {
      throw 'Lỗi khi tạo phiếu xuất kho: $e';
    }
  }

  // Quản lý nhà cung cấp
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final response = await supabase.from('NHACUNGCAP').select().order('TenNCC');
    return List<Map<String, dynamic>>.from(response);
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
              TenThuoc
            )
          )
        ''');

    if (startDate != null) {
      query = query.gte('NgayXuat', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('NgayXuat', endDate.toIso8601String());
    }

    final response = await query.order('NgayXuat', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Kiểm tra tồn kho
  Future<List<Map<String, dynamic>>> getInventoryStatus() async {
    final response = await supabase.from('THUOC').select().order('TenThuoc');
    return List<Map<String, dynamic>>.from(response);
  }
}
