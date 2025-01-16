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

  final Color _turquoiseColor =
      const Color(0xFF40E0D0).withOpacity(0.85); // Turquoise color

  final BoxDecoration _cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: Colors.white.withOpacity(0.95),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 3,
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: const Color(0xFF40E0D0).withOpacity(0.08),
        spreadRadius: 2,
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(
      color: Colors.white.withOpacity(0.8),
      width: 1.5,
    ),
  );

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
        title: const Text(
          'Tạo hóa đơn',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _turquoiseColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _turquoiseColor.withOpacity(0.15),
              Colors.white.withOpacity(0.95),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_turquoiseColor),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        color: _turquoiseColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  children: [
                    // Information Card
                    _buildCard(
                      'Thông tin hóa đơn',
                      Icons.description_outlined,
                      Column(
                        children: [
                          _buildDropdownField(),
                          const SizedBox(height: 20),
                          _buildDateField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Payment Details Card
                    _buildCard(
                      'Chi tiết thanh toán',
                      Icons.payment_outlined,
                      Column(
                        children: [
                          _buildCostRow('Tiền thuốc:', _medicineCost),
                          _buildDivider(),
                          _buildCostRow('Tiền khám:', _examinationFee),
                          _buildDivider(),
                          _buildCostRow('Tổng tiền:', _totalCost,
                              isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
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

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Container(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _turquoiseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: _turquoiseColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              _turquoiseColor.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBill,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: _turquoiseColor,
          elevation: _isLoading ? 0 : 8,
          shadowColor: _turquoiseColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    children: [
                      Icon(
                        Icons.save_outlined,
                        size: 26,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Lưu hóa đơn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 19 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? _turquoiseColor : Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'đ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: isTotal ? 21 : 17,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? _turquoiseColor : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      decoration: InputDecoration(
        labelText: 'Chọn toa thuốc',
        labelStyle: TextStyle(color: _turquoiseColor),
        prefixIcon: Icon(
          Icons.medical_services,
          color: _turquoiseColor,
        ),
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
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày lập hóa đơn',
          labelStyle: TextStyle(color: _turquoiseColor),
          prefixIcon: Icon(
            Icons.calendar_today,
            color: _turquoiseColor,
          ),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
