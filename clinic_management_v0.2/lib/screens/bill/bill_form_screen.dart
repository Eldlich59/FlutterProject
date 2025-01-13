import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/bill.dart';
import 'package:clinic_management/services/supabase_service.dart';

class BillFormScreen extends StatefulWidget {
  final Bill? bill;

  const BillFormScreen({super.key, this.bill});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService1 = SupabaseService().billService;
  final _supabaseService2 = SupabaseService().prescriptionService;
  List<Map<String, dynamic>> _availablePrescriptions = [];
  Map<String, dynamic>? _selectedPrescription;
  late DateTime _selectedDate;
  late double _medicineCost;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _medicineCost = 0;
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final prescriptions = await _supabaseService2.getAvailablePrescriptions();
      setState(() {
        _availablePrescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách toa thuốc: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateMedicineCost(String prescriptionId) async {
    try {
      final medicines =
          await _supabaseService2.getPrescriptionMedicines(prescriptionId);

      double total = 0;
      for (var medicine in medicines) {
        total += (medicine['Sluong'] * medicine['THUOC']['DonGia']);
      }

      setState(() {
        _medicineCost = total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tính tổng tiền: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo hóa đơn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: 'Chọn toa thuốc',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPrescription,
                    items: _availablePrescriptions.map((prescription) {
                      return DropdownMenuItem(
                        value: prescription,
                        child: Text(
                          'Toa thuốc #${prescription['MaToa']} - ${prescription['BENHNHAN']['TenBN']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrescription = value;
                      });
                      if (value != null) {
                        _calculateMedicineCost(value['MaToa']);
                      }
                    },
                    validator: (value) {
                      if (value == null) return 'Vui lòng chọn toa thuốc';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày bán',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tiền cần thanh toán:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: 'đ',
                            decimalDigits: 0,
                          ).format(_medicineCost),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBill,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Lưu hóa đơn'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _supabaseService1.createBill(
        prescriptionId: _selectedPrescription!['MaToa'],
        saleDate: _selectedDate,
        medicineCost: _medicineCost,
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu hóa đơn: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
