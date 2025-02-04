import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/inventory/medicine.dart';
import '../../../services/inventory_service.dart';

class InventoryStatusScreen extends StatefulWidget {
  const InventoryStatusScreen({super.key});

  @override
  State<InventoryStatusScreen> createState() => _InventoryStatusScreenState();
}

class _InventoryStatusScreenState extends State<InventoryStatusScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  List<Medicine>? medicines;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final service = InventoryService(Supabase.instance.client);
      final response = await service.getInventoryStatus();
      medicines = response.map((data) => Medicine.fromJson(data)).toList();
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tồn kho'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMedicineList(),
    );
  }

  Widget _buildMedicineList() {
    if (medicines == null || medicines!.isEmpty) {
      return const Center(child: Text('Không có dữ liệu tồn kho'));
    }

    return ListView.builder(
      itemCount: medicines!.length,
      itemBuilder: (context, index) {
        final medicine = medicines![index];
        return Card(
          child: ListTile(
            title: Text(medicine.name),
            subtitle: Text('Số lượng: ${medicine.stock} ${medicine.unit}'),
          ),
        );
      },
    );
  }
}
