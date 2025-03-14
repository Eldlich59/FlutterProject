import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/prescription/prescription_form_screen.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chi tiết toa thuốc',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Chỉnh sửa'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _navigateToEdit(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.print),
                  title: Text('In toa thuốc'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _printPrescription(context),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber[100]!.withOpacity(0.7),
              Colors.white,
            ],
          ),
        ),
        child: FutureBuilder<List<PrescriptionDetail>>(
          future: SupabaseService()
              .prescriptionService
              .getPrescriptionDetails(prescription.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Lỗi: ${snapshot.error}'),
              );
            }

            final details = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildMedicinesList(details),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            FutureBuilder<Patient?>(
              future: prescription.patientId != null
                  ? SupabaseService()
                      .patientService
                      .getPatientById(prescription.patientId!)
                  : Future.value(null),
              builder: (context, patientSnapshot) {
                if (patientSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _LoadingCard();
                }

                final patient = patientSnapshot.data;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person,
                                color: Colors.amber[800], size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Thông tin bệnh nhân',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                            'Họ tên', patient?.name ?? 'Không xác định'),
                        _buildInfoRow(
                            'Ngày sinh',
                            patient?.dateOfBirth != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(patient!.dateOfBirth)
                                : 'Không xác định'),
                        _buildInfoRow(
                            'Giới tính', patient?.gender ?? 'Không xác định'),
                        _buildInfoRow(
                            'Địa chỉ', patient?.address ?? 'Không xác định'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<Doctor>(
              future: SupabaseService()
                  .doctorService
                  .getDoctorById(prescription.doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard();
                }

                final doctor = snapshot.data;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medical_services,
                                color: Colors.amber[800], size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bác sĩ kê đơn: ${doctor?.name ?? 'Không xác định'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ),
                            _buildDoctorStatus(doctor?.isActive ?? false),
                          ],
                        ),
                        const Divider(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Object?>(
                              future: prescription.examId != null
                                  ? SupabaseService()
                                      .examinationService
                                      .getExaminationById(prescription.examId!)
                                  : Future.value(null),
                              builder: (context, examSnapshot) {
                                if (examSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildInfoRow(
                                    'Mã phiếu khám',
                                    prescription.examId != null
                                        ? '${prescription.examId!.substring(0, 6)}...'
                                        : 'Không có',
                                    suffix: const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }

                                Examination? examination;
                                if (examSnapshot.data != null) {
                                  try {
                                    final Map<String, dynamic> data =
                                        (examSnapshot.data
                                                as Map<String, dynamic>)['data']
                                            as Map<String, dynamic>;
                                    examination = Examination.fromJson(data);

                                    // Debug print để kiểm tra giá trị
                                    print('Examination data: $data');
                                    print(
                                        'isDoctorActive: ${examination.isDoctorActive}');
                                    print(
                                        'isSpecialtyActive: ${examination.isSpecialtyActive}');
                                    print(
                                        'pricePackage?.isActive: ${examination.pricePackage?.isActive}');
                                    print(
                                        'isValid: ${examination.isValidForPrescription()}');
                                  } catch (e) {
                                    print('Error parsing examination: $e');
                                  }
                                }

                                final isValid =
                                    examination?.isValidForPrescription() ??
                                        false;

                                String tooltipMessage = '';
                                if (examination != null && !isValid) {
                                  tooltipMessage = 'Phiếu khám không hợp lệ: \n'
                                      '${examination.isDoctorActive == false ? '- Bác sĩ không còn hoạt động\n' : ''}'
                                      '${examination.isSpecialtyActive == false ? '- Chuyên khoa không còn hoạt động\n' : ''}'
                                      '${examination.pricePackage?.isActive == false ? '- Gói dịch vụ không còn hiệu lực' : ''}';
                                }

                                return _buildInfoRow(
                                  'Mã phiếu khám',
                                  prescription.examId != null
                                      ? '${prescription.examId!.substring(0, 6)}...'
                                      : 'Không có',
                                  suffix: prescription.examId != null
                                      ? Tooltip(
                                          message: isValid
                                              ? 'Phiếu khám hợp lệ'
                                              : tooltipMessage,
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(left: 24),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isValid
                                                  ? Colors.green[50]
                                                  : Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isValid
                                                    ? Colors.green
                                                    : Colors.red,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isValid
                                                      ? Icons.check_circle
                                                      : Icons.error,
                                                  size: 16,
                                                  color: isValid
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isValid
                                                      ? 'Hợp lệ'
                                                      : 'Không hợp lệ',
                                                  style: TextStyle(
                                                    color: isValid
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            _buildInfoRow(
                                'Ngày kê toa',
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(prescription.prescriptionDate)),
                          ],
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
    );
  }

  Widget _buildMedicinesList(List<PrescriptionDetail> details) {
    double totalCost = 0;
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.medication, color: Colors.amber[800], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách thuốc',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...details.map((detail) {
              final medicineCost =
                  (detail.quantity * (detail.medicine?.price ?? 0)).toDouble();
              totalCost += medicineCost;
              return _buildMedicineCard(detail, medicineCost);
            }),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.amber[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng tiền thuốc:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                          .format(totalCost),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(PrescriptionDetail detail, double totalCost) {
    final medicine = detail.medicine;
    if (medicine == null) {
      return _buildErrorCard(detail.medicineId);
    }

    return AnimationConfiguration.synchronized(
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medication_outlined,
                            color: Colors.amber[800]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildMedicineInfoRow(
                      'Số lượng', '${detail.quantity} ${medicine.unit}'),
                  _buildMedicineInfoRow(
                      'Đơn giá',
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                          .format(medicine.price)),
                  _buildMedicineInfoRow(
                      'Thành tiền',
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                          .format(totalCost)),
                  const Divider(height: 24),
                  Text(
                    'Cách dùng:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(detail.usage),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Changed from 100 to 120
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (suffix != null) suffix,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String medicineId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text('Thuốc không tồn tại (ID: $medicineId)',
                style: TextStyle(color: Colors.red[700])),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(
          prescription: prescription,
          isEditing: true,
        ),
      ),
    );
  }

  void _printPrescription(BuildContext context) {
    // Implement printing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tính năng in toa thuốc đang được phát triển')),
    );
  }

  Widget _buildDoctorStatus(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Đang hoạt động' : 'Không hoạt động',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidStatusRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkExamIdValidity(String? examId) async {
    if (examId == null) return false;
    try {
      final Map<String, dynamic> examinationData = await SupabaseService()
          .prescriptionService
          .getPrescriptionExamination(prescription.id);

      if (examinationData.isEmpty) return false;

      final examInfo = examinationData['PHIEUKHAM'] as Map<String, dynamic>?;
      if (examInfo == null) return false;

      final String fetchedExamId = examInfo['MaPK']?.toString() ?? '';
      return fetchedExamId.isNotEmpty && fetchedExamId == examId;
    } catch (e) {
      return false;
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
