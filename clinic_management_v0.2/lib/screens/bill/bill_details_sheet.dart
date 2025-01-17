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

class _BillDetailsSheetState extends State<BillDetailsSheet> {
  bool _isLoading = true;
  List<PrescriptionDetail>? _prescriptionDetails;
  List<Map<String, dynamic>> _medicineDetails = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptionDetails();
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
          final prescription =
              await supabaseService.getPrescriptionDetails(prescriptionId);
          final medicines =
              await supabaseService.getPrescriptionMedicines(prescriptionId);

          allPrescriptionDetails.addAll(prescription);
          allMedicineDetails.addAll(medicines);
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
    final turquoiseColor = Color(0xFF40E0D0); // Màu lục bích
    final lightTurquoise = Color(0xFFE0F7F5); // Màu lục bích nhạt
    final darkTurquoise = Color(0xFF20B2AA); // Màu lục bích đậm

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: turquoiseColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: darkTurquoise))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết hóa đơn',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: darkTurquoise,
                              ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
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
                          if (widget.bill.examinationId != null)
                            'Mã phiếu khám: ${widget.bill.examinationId?.substring(0, 6)}...',
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
                        _buildInfoSection(
                          'Thông tin toa thuốc',
                          [
                            'Mã toa: ${_prescriptionDetails![0].prescriptionId.substring(0, 6)}...',
                            'Danh sách thuốc:',
                          ],
                          Icons.medical_information,
                          additionalContent: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _medicineDetails.length,
                            itemBuilder: (context, index) {
                              final medicine = _medicineDetails[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
