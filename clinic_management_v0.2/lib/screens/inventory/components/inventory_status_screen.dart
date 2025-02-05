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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Tổng sản phẩm',
                    medicines!.length.toString(),
                    Icons.medication,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Sắp hết hàng',
                    medicines!.where((m) => m.stock < 10).length.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: medicines!.length,
            itemBuilder: (context, index) {
              final medicine = medicines![index];
              final isLowStock = medicine.stock < 10;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Sắp hết'),
                          backgroundColor: Colors.red[100],
                          labelStyle: TextStyle(color: Colors.red[900]),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.inventory_2,
                              size: 16,
                              color: isLowStock ? Colors.red : Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Tồn kho: ${medicine.stock} ${medicine.unit}',
                            style: TextStyle(
                              color: isLowStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
