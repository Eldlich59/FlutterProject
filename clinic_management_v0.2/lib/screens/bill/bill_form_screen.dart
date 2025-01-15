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
  late double _examinationFee; // Add this
  late double _totalCost; // Add this
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _medicineCost = 0; // Changed this line
    _examinationFee = 0; // Initialize
    _totalCost = 0; // Initialize
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
      final examination =
          await _supabaseService2.getPrescriptionExamination(prescriptionId);

      double medicineTotal = 0;
      for (var medicine in medicines) {
        medicineTotal +=
            (medicine['Sluong'] ?? 0) * (medicine['THUOC']['DonGia'] ?? 0);
      }

      // Changed this section to properly get TienKham
      double examFee = 0;
      if (examination['PHIEUKHAM'] != null) {
        examFee =
            double.tryParse(examination['PHIEUKHAM']['TienKham'].toString()) ??
                0;
      }

      double total = medicineTotal + examFee;

      setState(() {
        _medicineCost = medicineTotal;
        _examinationFee = examFee;
        _totalCost = total;
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
                          '${prescription['BENHNHAN']['TenBN']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(prescription['Ngayketoa']))}',
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
                        labelText: 'Ngày lập hóa đơn',
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
                        _buildCostRow('Tiền thuốc:', _medicineCost),
                        const Divider(),
                        _buildCostRow('Tiền khám:', _examinationFee),
                        const Divider(),
                        _buildCostRow('Tổng tiền:', _totalCost, isTotal: true),
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
    if (_selectedPrescription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn toa thuốc hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prescriptionId = _selectedPrescription!['MaToa'].toString();

      await _supabaseService1.createBill(
        prescriptionId: prescriptionId,
        saleDate: _selectedDate,
        totalCost: _totalCost,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo hóa đơn thành công')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu hóa đơn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color:
                  isTotal ? Theme.of(context).primaryColor : Colors.grey[700],
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'đ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
