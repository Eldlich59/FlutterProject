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

class _BillFormScreenState extends State<BillFormScreen>
    with SingleTickerProviderStateMixin {
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
      color: const Color(0xFF40E0D0).withOpacity(0.2),
      width: 1.5,
    ),
  );

  // Add these new variables
  List<Map<String, dynamic>> _availablePatients = [];
  Map<String, dynamic>? _selectedPatient;

  // Change from late to direct initialization
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations in initState
    _initializeAnimations();

    _selectedDate = DateTime.now();
    _medicineCost = 0; // Changed this line
    _examinationFee = 0; // Initialize
    _totalCost = 0; // Initialize
    _loadPatients(); // Changed from _loadPrescriptions
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Add new method to load patients
  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await SupabaseService().patientService.getPatients();
      setState(() {
        _availablePatients =
            patients.map((patient) => patient.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách bệnh nhân: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Add method to load prescriptions for selected patient
  Future<void> _loadPatientPrescriptions(String patientId) async {
    setState(() => _isLoading = true);
    try {
      final prescriptions =
          await _supabaseService2.getPrescriptionsByPatient(patientId);
      setState(() {
        _availablePrescriptions = prescriptions;
        _selectedPrescriptions.clear(); // Clear previous selections
        _medicineCost = 0;
        _examinationFee = 0;
        _totalCost = 0;
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
              _turquoiseColor.withOpacity(0.2),
              Colors.white.withOpacity(0.95),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
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
                      _buildInformationCard(),
                      const SizedBox(height: 24),
                      _buildPaymentDetailsCard(), // Use the new method here
                      const SizedBox(height: 32),
                      // Save Button
                      _buildSaveButton(),
                    ],
                  ),
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
    if (_selectedPrescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một toa thuốc')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prescriptionIds = _selectedPrescriptions
          .map((p) => p['MaToa'].toString().trim())
          .where((id) => id.isNotEmpty)
          .toList();

      print('Creating bill with prescriptions: $prescriptionIds');

      await _supabaseService1.createBill(
        prescriptionIds: prescriptionIds,
        saleDate: _selectedDate,
        totalCost: _totalCost,
      );

      if (mounted) {
        // Just pop with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Save bill error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu hóa đơn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Update _buildCard method to handle nullable animations
  Widget _buildCard(String title, IconData icon, Widget content) {
    Widget card = Container(
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
                    color: _turquoiseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _turquoiseColor.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: _turquoiseColor.withOpacity(0.9),
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

    // Only wrap with animations if they are initialized
    if (_fadeAnimation != null && _slideAnimation != null) {
      card = FadeTransition(
        opacity: _fadeAnimation!,
        child: SlideTransition(
          position: _slideAnimation!,
          child: card,
        ),
      );
    }

    return card;
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

  List<Map<String, dynamic>> _selectedPrescriptions =
      []; // Changed from single selection

  // Replace _buildDropdownField with this new method
  Widget _buildPrescriptionSelectionList() {
    if (_selectedPatient == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Chọn toa thuốc',
          style: TextStyle(
            color: _turquoiseColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_availablePrescriptions.isEmpty)
          Center(
            child: Text(
              'Không có toa thuốc nào',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availablePrescriptions.length,
            itemBuilder: (context, index) {
              final prescription = _availablePrescriptions[index];
              final isSelected = _selectedPrescriptions.contains(prescription);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  title: Text(
                      '${prescription['BENHNHAN']['TenBN']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(prescription['Ngayketoa']))}'),
                  subtitle: Text(
                      'Mã toa: ${prescription['MaToa'].toString().substring(0, 6)}...'),
                  onChanged: (bool? value) async {
                    if (value == true) {
                      setState(() {
                        _selectedPrescriptions.add(prescription);
                      });
                    } else {
                      setState(() {
                        _selectedPrescriptions.remove(prescription);
                      });
                    }
                    await _calculateTotalCosts();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // Replace _calculateMedicineCost with this new method
  Future<void> _calculateTotalCosts() async {
    if (!mounted) return;

    double medicineCost = 0;
    double examinationFee = 0;

    final prescriptions =
        List<Map<String, dynamic>>.from(_selectedPrescriptions);

    try {
      for (var prescription in prescriptions) {
        final medicines = await _supabaseService2
            .getPrescriptionMedicines(prescription['MaToa'].toString());
        final examination = await _supabaseService2
            .getPrescriptionExamination(prescription['MaToa'].toString());

        // Calculate medicine costs
        for (var medicine in medicines) {
          final quantity = medicine['Sluong'] ?? 0;
          final price = medicine['THUOC']['DonGia'] ?? 0;
          medicineCost += (quantity * price);
        }

        // Add examination fee
        if (examination['PHIEUKHAM'] != null) {
          final examFee = double.tryParse(
                  examination['PHIEUKHAM']['TienKham'].toString()) ??
              0;
          examinationFee += examFee;
        }
      }

      if (mounted) {
        setState(() {
          _medicineCost = medicineCost;
          _examinationFee = examinationFee;
          _totalCost = medicineCost + examinationFee;
        });
      }
    } catch (e) {
      print('Error calculating costs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tính tổng tiền: $e')),
        );
      }
    }
  }

  Widget _buildPaymentDetailsCard() {
    return _buildCard(
      'Chi tiết thanh toán',
      Icons.payment_outlined,
      Column(
        children: [
          _buildCostRow('Tiền thuốc:', _medicineCost),
          _buildDivider(),
          _buildCostRow('Tiền khám:', _examinationFee),
          _buildDivider(),
          _buildCostRow('Tổng tiền:', _totalCost, isTotal: true),
        ],
      ),
    );
  }

  // Update the build method's form section
  Widget _buildInformationCard() {
    return _buildCard(
      'Thông tin hóa đơn',
      Icons.description_outlined,
      Column(
        children: [
          _buildPatientSelection(),
          _buildPrescriptionSelectionList(),
          const SizedBox(height: 20),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn bệnh nhân',
          style: TextStyle(
            color: _turquoiseColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person, color: _turquoiseColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedPatient,
          items: _availablePatients.map((patient) {
            return DropdownMenuItem(
              value: patient,
              child: Text('${patient['TenBN']} - ${patient['SDT']}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPatient = value;
              _availablePrescriptions = [];
              _selectedPrescriptions = [];
            });
            if (value != null) {
              _loadPatientPrescriptions(value['MaBN'].toString());
            }
          },
          validator: (value) {
            if (value == null) return 'Vui lòng chọn bệnh nhân';
            return null;
          },
        ),
      ],
    );
  }
}
