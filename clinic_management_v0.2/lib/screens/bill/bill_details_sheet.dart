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

      // Load prescription details
      final prescription = await supabaseService
          .getPrescriptionDetails(widget.bill.prescriptionId);

      // Load medicine details for this prescription
      final medicines = await supabaseService
          .getPrescriptionMedicines(widget.bill.prescriptionId);

      setState(() {
        _prescriptionDetails = prescription;
        _medicineDetails = medicines;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải chi tiết hóa đơn: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      // Take up 80% of screen height
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết hóa đơn',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      _buildInfoSection(
                        'Thông tin hóa đơn',
                        [
                          'Mã hóa đơn: ${widget.bill.id}',
                          'Ngày bán: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.bill.saleDate)}',
                          'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.bill.medicineCost)}',
                        ],
                      ),
                      if (_prescriptionDetails != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection(
                          'Thông tin toa thuốc',
                          [
                            'Mã toa: ${_prescriptionDetails![0].prescriptionId}',
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Danh sách thuốc',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _medicineDetails.length,
                        itemBuilder: (context, index) {
                          final medicine = _medicineDetails[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                medicine['THUOC']['TenThuoc'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Số lượng: ${medicine['Sluong']} ${medicine['THUOC']['DonVi']}'),
                                  Text('Cách dùng: ${medicine['Cdung']}'),
                                  Text(
                                    'Thành tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(medicine['THUOC']['DonGia'] * medicine['Sluong'])}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(detail),
            )),
      ],
    );
  }
}
