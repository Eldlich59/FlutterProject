import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineProvider>();
    Future.microtask(() {
      if (mounted) {
        provider.loadMedicines();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditMedicineDialog(context),
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.medicines.isEmpty) {
            return const Center(child: Text('Chưa có thuốc nào'));
          }

          return ListView.builder(
            itemCount: provider.medicines.length,
            itemBuilder: (context, index) {
              final medicine = provider.medicines[index];
              return ListTile(
                title: Text(medicine.name),
                subtitle: Text(
                  'Đơn vị: ${medicine.unit} - Giá: ${medicine.price}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditMedicineDialog(
                        context,
                        medicine: medicine,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteMedicine(medicine),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddEditMedicineDialog(
    BuildContext context, {
    Medicine? medicine,
  }) async {
    final nameController = TextEditingController(text: medicine?.name);
    final unitController = TextEditingController(text: medicine?.unit);
    final priceController =
        TextEditingController(text: medicine?.price.toString());
    final manufacturingDateController = TextEditingController(
        text: medicine?.manufacturingDate.toString().split(' ')[0]);
    final expiryDateController = TextEditingController(
        text: medicine?.expiryDate.toString().split(' ')[0]);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine == null ? 'Thêm thuốc' : 'Cập nhật thuốc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên thuốc'),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Đơn vị'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Giá'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: manufacturingDateController,
              decoration: const InputDecoration(
                  labelText: 'Ngày sản xuất (YYYY-MM-DD)'),
            ),
            TextField(
              controller: expiryDateController,
              decoration:
                  const InputDecoration(labelText: 'Ngày hết hạn (YYYY-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final newMedicine = Medicine(
                id: medicine?.id ?? DateTime.now().toString(),
                name: nameController.text,
                unit: unitController.text,
                price: double.tryParse(priceController.text) ?? 0,
                manufacturingDate:
                    DateTime.parse(manufacturingDateController.text),
                expiryDate: DateTime.parse(expiryDateController.text),
              );

              if (medicine == null) {
                context.read<MedicineProvider>().addMedicine(newMedicine);
              } else {
                context.read<MedicineProvider>().updateMedicine(newMedicine);
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(Medicine medicine) {
    context.read<MedicineProvider>().deleteMedicine(medicine.id);
  }
}
