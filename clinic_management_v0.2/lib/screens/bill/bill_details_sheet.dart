import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/bill.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/models/prescription.dart';

class BillDetailsSheet extends StatefulWidget {
  final Bill bill;

  const BillDetailsSheet({
    super.key,
    required this.bill,
  });

  @override
  State<BillDetailsSheet> createState() => _BillDetailsSheetState();
}

class _BillDetailsSheetState extends State<BillDetailsSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<PrescriptionDetail>? _prescriptionDetails;
  List<Map<String, dynamic>> _medicineDetails = [];
  List<String> _selectedPrescriptionIds = [];
  bool _isVisible = false; // Add this line
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPrescriptionIds = List.from(widget.bill.prescriptionIds);
    _loadPrescriptionDetails();
    // Add animation trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(
      begin: 100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptionDetails() async {
    try {
      final supabaseService = SupabaseService().prescriptionService;
      List<PrescriptionDetail> allPrescriptionDetails = [];
      List<Map<String, dynamic>> allMedicineDetails = [];

      if (widget.bill.prescriptionIds.isEmpty) {
        setState(() {
          _prescriptionDetails = [];
          _medicineDetails = [];
          _isLoading = false;
        });
        return;
      }

      // Load details for each prescription
      for (String prescriptionId in widget.bill.prescriptionIds) {
        try {
          print('Loading prescription: $prescriptionId'); // Debug print
          final prescription =
              await supabaseService.getPrescriptionDetails(prescriptionId);
          final medicines =
              await supabaseService.getPrescriptionMedicines(prescriptionId);

          print(
              'Medicines for $prescriptionId: ${medicines.length}'); // Debug print

          // Add prescription ID to each medicine detail
          final medicinesWithPrescriptionId = medicines
              .map((medicine) => {
                    ...medicine,
                    'prescriptionId': prescriptionId,
                  })
              .toList();

          allPrescriptionDetails.addAll(prescription);
          allMedicineDetails.addAll(medicinesWithPrescriptionId);
        } catch (e) {
          print('Error loading details for prescription $prescriptionId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _prescriptionDetails = allPrescriptionDetails;
          _medicineDetails = allMedicineDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadPrescriptionDetails: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải chi tiết hóa đơn: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTurquoise = Color(0xFFE0F7F5); // Màu lục bích nhạt
    final darkTurquoise = Color(0xFF20B2AA); // Màu lục bích đậm

    return Hero(
      tag: 'bill-${widget.bill.id}',
      child: Scaffold(
        // Changed to Scaffold
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top +
                        20, // Add safe area padding
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  height:
                      MediaQuery.of(context).size.height, // Full screen height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // Remove border radius for full screen
                  ),
                  child: _isLoading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: darkTurquoise))
                      : AnimatedOpacity(
                          opacity: _isVisible ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Chi tiết hóa đơn',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: darkTurquoise,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: Colors.grey.shade600),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                              Divider(color: lightTurquoise, thickness: 2),
                              Expanded(
                                child: ListView(
                                  children: [
                                    _buildInfoSection(
                                      'Thông tin hóa đơn',
                                      [
                                        'Tên bệnh nhân: ${widget.bill.patientName}',
                                        'Mã hóa đơn: ${widget.bill.id.substring(0, 6)}...',
                                        'Ngày tạo hóa đơn: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.bill.saleDate)}',
                                        'Tiền thuốc: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.bill.medicineCost)}',
                                        if (widget.bill.examinationCost != null)
                                          'Tiền khám: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.bill.examinationCost)}',
                                        'Tổng thanh toán: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.bill.totalCost)}',
                                      ],
                                      Icons.receipt_long,
                                    ),
                                    if (_prescriptionDetails != null) ...[
                                      const SizedBox(height: 20),
                                      // Show selected prescriptions as chips
                                      if (_selectedPrescriptionIds.isNotEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _selectedPrescriptionIds
                                              .map((id) {
                                            return Chip(
                                              backgroundColor:
                                                  Color(0xFFE0F7F5),
                                              label: Text(
                                                  'Toa ${widget.bill.prescriptionIds.indexOf(id) + 1}'),
                                              deleteIcon:
                                                  Icon(Icons.close, size: 18),
                                              onDeleted: () {
                                                setState(() {
                                                  _selectedPrescriptionIds
                                                      .remove(id);
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      const SizedBox(height: 12),
                                      // Only show dropdown if there are unselected prescriptions
                                      if (_selectedPrescriptionIds.length <
                                          widget.bill.prescriptionIds.length)
                                        DropdownButton<String>(
                                          hint: Text('Chọn toa thuốc'),
                                          value: null,
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                _selectedPrescriptionIds
                                                    .add(newValue);
                                              });
                                            }
                                          },
                                          items: widget.bill.prescriptionIds
                                              .where((id) =>
                                                  !_selectedPrescriptionIds
                                                      .contains(id))
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                  'Toa thuốc ${widget.bill.prescriptionIds.indexOf(value) + 1}'),
                                            );
                                          }).toList(),
                                        ),
                                      if (_selectedPrescriptionIds
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        ..._selectedPrescriptionIds
                                            .map((prescriptionId) {
                                          return _buildPrescriptionDetails(
                                              prescriptionId);
                                        }),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetails(String prescriptionId) {
    final lightTurquoise = Color(0xFFE0F7F5);
    final darkTurquoise = Color(0xFF20B2AA);

    // Filter medicines for this prescription
    final prescriptionMedicines = _medicineDetails
        .where((medicine) => medicine['prescriptionId'] == prescriptionId)
        .toList();

    return Column(
      children: [
        _buildInfoSection(
          'Toa thuốc ${widget.bill.prescriptionIds.indexOf(prescriptionId) + 1}',
          [
            'Mã toa: ${prescriptionId.substring(0, 6)}...',
            'Số lượng thuốc: ${prescriptionMedicines.length}',
            'Danh sách thuốc:',
          ],
          Icons.medical_information,
          additionalContent: prescriptionMedicines.isEmpty
              ? Text('Không có thuốc trong toa này',
                  style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: prescriptionMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = prescriptionMedicines[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: lightTurquoise),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine['THUOC']['TenThuoc'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: darkTurquoise,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildMedicineDetail(
                              Icons.numbers,
                              'Số lượng: ${medicine['Sluong']} ${medicine['THUOC']['DonVi']}',
                            ),
                            _buildMedicineDetail(
                              Icons.info_outline,
                              'Cách dùng: ${medicine['Cdung']}',
                            ),
                            _buildMedicineDetail(
                              Icons.attach_money,
                              'Thành tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(medicine['THUOC']['DonGia'] * medicine['Sluong'])}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<String> details, IconData icon,
      {Widget? additionalContent}) {
    final turquoiseColor = Color(0xFF40E0D0);
    final lightTurquoise = Color(0xFFE0F7F5);
    final darkTurquoise = Color(0xFF20B2AA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightTurquoise,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: turquoiseColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: darkTurquoise),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkTurquoise,
                    ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 20, color: darkTurquoise),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          detail,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (additionalContent != null) ...[
            const SizedBox(height: 12),
            additionalContent,
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF20B2AA)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
