import 'package:flutter/material.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// Các model cần thiết
class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorName;
  final String hospitalName;
  final String specialty;
  final DateTime visitDate;
  final String diagnosis;
  final String reason;
  final String conclusion;
  final String? instructions;
  final String? notes;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.hospitalName,
    required this.specialty,
    required this.visitDate,
    required this.diagnosis,
    required this.reason,
    required this.conclusion,
    this.instructions,
    this.notes,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patient_id'],
      doctorName: json['doctor_name'],
      hospitalName: json['hospital_name'],
      specialty: json['specialty'],
      visitDate: DateTime.parse(json['visit_date']),
      diagnosis: json['diagnosis'],
      reason: json['reason'],
      conclusion: json['conclusion'],
      instructions: json['instructions'],
      notes: json['notes'],
    );
  }
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
    );
  }
}

class Prescription {
  final String id;
  final String patientId;
  final String doctorName;
  final DateTime prescribedDate;
  final DateTime expiryDate;
  final String diagnosis;
  final List<Medication> medications;
  final String? notes;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.prescribedDate,
    required this.expiryDate,
    required this.diagnosis,
    required this.medications,
    this.notes,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      patientId: json['patient_id'],
      doctorName: json['doctor_name'],
      prescribedDate: DateTime.parse(json['prescribed_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      diagnosis: json['diagnosis'],
      medications:
          (json['medications'] as List)
              .map((med) => Medication.fromJson(med))
              .toList(),
      notes: json['notes'],
    );
  }
}

class TestResultItem {
  final String name;
  final String value;
  final String referenceRange;
  final String status;

  TestResultItem({
    required this.name,
    required this.value,
    required this.referenceRange,
    required this.status,
  });

  factory TestResultItem.fromJson(Map<String, dynamic> json) {
    return TestResultItem(
      name: json['name'],
      value: json['value'],
      referenceRange: json['reference_range'],
      status: json['status'],
    );
  }
}

class TestResult {
  final String id;
  final String patientId;
  final String testName;
  final String laboratoryName;
  final DateTime testDate;
  final String doctorName;
  final String status;
  final List<TestResultItem> results;
  final String? notes;
  final List<String>? imageUrls;

  TestResult({
    required this.id,
    required this.patientId,
    required this.testName,
    required this.laboratoryName,
    required this.testDate,
    required this.doctorName,
    required this.status,
    required this.results,
    this.notes,
    this.imageUrls,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      patientId: json['patient_id'],
      testName: json['test_name'],
      laboratoryName: json['laboratory_name'],
      testDate: DateTime.parse(json['test_date']),
      doctorName: json['doctor_name'],
      status: json['status'],
      results:
          (json['results'] as List)
              .map((item) => TestResultItem.fromJson(item))
              .toList(),
      notes: json['notes'],
      imageUrls:
          json['image_urls'] != null
              ? List<String>.from(json['image_urls'])
              : null,
    );
  }
}

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<MedicalRecord> _medicalRecords = [];
  List<Prescription> _prescriptions = [];
  List<TestResult> _testResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedicalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalData() async {
    try {
      setState(() => _isLoading = true);

      // Lấy ID người dùng hiện tại
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        // Xử lý chưa đăng nhập
        return;
      }

      // Tải lịch sử khám bệnh
      final medicalRecordsData = await supabase
          .from('medical_records')
          .select()
          .eq('patient_id', userId)
          .order('visit_date', ascending: false);

      // Tải đơn thuốc
      final prescriptionsData = await supabase
          .from('prescriptions')
          .select()
          .eq('patient_id', userId)
          .order('prescribed_date', ascending: false);

      // Tải kết quả xét nghiệm
      final testResultsData = await supabase
          .from('test_results')
          .select()
          .eq('patient_id', userId)
          .order('test_date', ascending: false);

      setState(() {
        _medicalRecords =
            medicalRecordsData
                .map<MedicalRecord>((json) => MedicalRecord.fromJson(json))
                .toList();

        _prescriptions =
            prescriptionsData
                .map<Prescription>((json) => Prescription.fromJson(json))
                .toList();

        _testResults =
            testResultsData
                .map<TestResult>((json) => TestResult.fromJson(json))
                .toList();
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu y bạ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Y bạ điện tử'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lịch sử khám'),
            Tab(text: 'Đơn thuốc'),
            Tab(text: 'Kết quả xét nghiệm'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadMedicalData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMedicalHistoryTab(),
                    _buildPrescriptionsTab(),
                    _buildTestResultsTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    return _medicalRecords.isEmpty
        ? _buildEmptyState(
          'Chưa có lịch sử khám bệnh',
          'Các lần khám bệnh của bạn sẽ được hiển thị ở đây',
          Icons.medical_services_outlined,
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _medicalRecords.length,
          itemBuilder: (context, index) {
            final record = _medicalRecords[index];
            return _buildMedicalRecordCard(record);
          },
        );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showMedicalRecordDetails(record);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.medical_services,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          record.hospitalName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.specialty,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày khám',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(record.visitDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chẩn đoán',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.diagnosis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalRecordDetails(MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Chi tiết lần khám',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem('Bác sĩ:', record.doctorName),
                  _buildDetailItem('Chuyên khoa:', record.specialty),
                  _buildDetailItem(
                    'Bệnh viện/Phòng khám:',
                    record.hospitalName,
                  ),
                  _buildDetailItem(
                    'Ngày khám:',
                    DateFormat('dd/MM/yyyy').format(record.visitDate),
                  ),
                  _buildDetailItem('Chẩn đoán:', record.diagnosis),
                  _buildDetailItem('Lý do khám:', record.reason),
                  _buildDetailItem('Ghi chú:', record.notes ?? 'Không có'),
                  const SizedBox(height: 16),
                  const Text(
                    'Kết luận của bác sĩ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(record.conclusion),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lời dặn:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(record.instructions ?? 'Không có lời dặn'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    return _prescriptions.isEmpty
        ? _buildEmptyState(
          'Chưa có đơn thuốc',
          'Các đơn thuốc của bạn sẽ được hiển thị ở đây',
          Icons.medication_outlined,
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = _prescriptions[index];
            return _buildPrescriptionCard(prescription);
          },
        );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showPrescriptionDetails(prescription);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: const Icon(Icons.medication, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn thuốc - ${DateFormat('dd/MM/yyyy').format(prescription.prescribedDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Bác sĩ: ${prescription.doctorName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${prescription.medications.length} thuốc',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày kê đơn',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(prescription.prescribedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hiệu lực đến',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(prescription.expiryDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Chi tiết đơn thuốc',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem('Bác sĩ:', prescription.doctorName),
                  _buildDetailItem('Chẩn đoán:', prescription.diagnosis),
                  _buildDetailItem(
                    'Ngày kê đơn:',
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(prescription.prescribedDate),
                  ),
                  _buildDetailItem(
                    'Hiệu lực đến:',
                    DateFormat('dd/MM/yyyy').format(prescription.expiryDate),
                  ),
                  _buildDetailItem(
                    'Ghi chú:',
                    prescription.notes ?? 'Không có',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Danh sách thuốc:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...prescription.medications.map(
                    (med) => _buildMedicationItem(med),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicationItem(Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Liều lượng: ${medication.dosage}'),
          Text('Tần suất: ${medication.frequency}'),
          Text('Thời gian dùng: ${medication.duration}'),
          if (medication.instructions != null)
            Text('Hướng dẫn: ${medication.instructions}'),
        ],
      ),
    );
  }

  Widget _buildTestResultsTab() {
    return _testResults.isEmpty
        ? _buildEmptyState(
          'Chưa có kết quả xét nghiệm',
          'Các kết quả xét nghiệm của bạn sẽ được hiển thị ở đây',
          Icons.science_outlined,
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _testResults.length,
          itemBuilder: (context, index) {
            final testResult = _testResults[index];
            return _buildTestResultCard(testResult);
          },
        );
  }

  Widget _buildTestResultCard(TestResult testResult) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showTestResultDetails(testResult);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.science, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testResult.testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          testResult.laboratoryName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        testResult.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      testResult.status,
                      style: TextStyle(
                        color: _getStatusColor(testResult.status),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày xét nghiệm',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(testResult.testDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bác sĩ chỉ định',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          testResult.doctorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'bình thường':
        return Colors.green;
      case 'cao':
        return Colors.orange;
      case 'thấp':
        return Colors.blue;
      case 'nguy hiểm':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getValueColor(String status) {
    switch (status.toLowerCase()) {
      case 'bình thường':
        return Colors.green;
      case 'cao':
        return Colors.orange;
      case 'thấp':
        return Colors.blue;
      case 'nguy hiểm':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  void _showTestResultDetails(TestResult testResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Chi tiết kết quả xét nghiệm',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem('Tên xét nghiệm:', testResult.testName),
                  _buildDetailItem(
                    'Phòng xét nghiệm:',
                    testResult.laboratoryName,
                  ),
                  _buildDetailItem('Bác sĩ chỉ định:', testResult.doctorName),
                  _buildDetailItem(
                    'Ngày xét nghiệm:',
                    DateFormat('dd/MM/yyyy').format(testResult.testDate),
                  ),
                  _buildDetailItem('Trạng thái:', testResult.status),
                  _buildDetailItem('Ghi chú:', testResult.notes ?? 'Không có'),

                  const SizedBox(height: 16),
                  const Text(
                    'Chi tiết kết quả:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Bảng kết quả xét nghiệm
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Chỉ số',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Kết quả',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Tham chiếu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Test result rows
                        ...testResult.results.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(item.name)),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.value,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getValueColor(item.status),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(item.referenceRange),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  if (testResult.imageUrls != null &&
                      testResult.imageUrls!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Hình ảnh xét nghiệm:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: testResult.imageUrls!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => FullScreenImageView(
                                          imageUrl:
                                              testResult.imageUrls![index],
                                        ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: CachedNetworkImage(
                                  imageUrl: testResult.imageUrls![index],
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// Xem hình ảnh xét nghiệm ở kích thước đầy đủ
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder:
                (context, url) =>
                    const Center(child: CircularProgressIndicator()),
            errorWidget:
                (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
