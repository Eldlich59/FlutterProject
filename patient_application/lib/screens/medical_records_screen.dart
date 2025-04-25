import 'package:flutter/material.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:patient_application/models/medical_records/medical_record.dart';
import 'package:patient_application/models/medical_records/prescription.dart';
import 'package:patient_application/models/medical_records/test_result.dart';

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

  // Flags to track if tables exist
  bool _medicalRecordsTableExists = true;
  bool _prescriptionsTableExists = true;
  bool _testResultsTableExists = true;

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
      try {
        final medicalRecordsData = await supabase
            .from('medical_records')
            .select()
            .eq('patient_id', userId)
            .order('visit_date', ascending: false);

        setState(() {
          _medicalRecords =
              medicalRecordsData
                  .map<MedicalRecord>((json) => MedicalRecord.fromJson(json))
                  .toList();
          _medicalRecordsTableExists = true;
        });
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu lịch sử khám bệnh: $e');
        // Kiểm tra xem lỗi có phải do bảng không tồn tại
        if (e.toString().contains("relation") &&
            e.toString().contains("does not exist")) {
          setState(() {
            _medicalRecords = [];
            _medicalRecordsTableExists = false;
          });
        }
      }

      // Tải đơn thuốc
      try {
        final prescriptionsData = await supabase
            .from('prescriptions')
            .select()
            .eq('patient_id', userId)
            .order('prescribed_date', ascending: false);

        setState(() {
          _prescriptions =
              prescriptionsData
                  .map<Prescription>((json) => Prescription.fromJson(json))
                  .toList();
          _prescriptionsTableExists = true;
        });
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu đơn thuốc: $e');
        if (e.toString().contains("relation") &&
            e.toString().contains("does not exist")) {
          setState(() {
            _prescriptions = [];
            _prescriptionsTableExists = false;
          });
        }
      }

      // Tải kết quả xét nghiệm
      try {
        final testResultsData = await supabase
            .from('test_results')
            .select()
            .eq('patient_id', userId)
            .order('test_date', ascending: false);

        setState(() {
          _testResults =
              testResultsData
                  .map<TestResult>((json) => TestResult.fromJson(json))
                  .toList();
          _testResultsTableExists = true;
        });
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu kết quả xét nghiệm: $e');
        if (e.toString().contains("relation") &&
            e.toString().contains("does not exist")) {
          setState(() {
            _testResults = [];
            _testResultsTableExists = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi chung khi tải dữ liệu y bạ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar without AppBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Lịch sử khám'),
              Tab(text: 'Đơn thuốc'),
              Tab(text: 'Kết quả xét nghiệm'),
            ],
          ),
          // Content area
          Expanded(
            child: _isLoading
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
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_medicalRecordsTableExists) {
      return _buildFeatureInDevelopment(
        'Tính năng đang được phát triển',
        'Lịch sử khám bệnh sẽ sớm được kích hoạt. Xin vui lòng thử lại sau.',
        Icons.engineering,
      );
    }

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_prescriptionsTableExists) {
      return _buildFeatureInDevelopment(
        'Tính năng đang được phát triển',
        'Đơn thuốc sẽ sớm được kích hoạt. Xin vui lòng thử lại sau.',
        Icons.engineering,
      );
    }

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_testResultsTableExists) {
      return _buildFeatureInDevelopment(
        'Tính năng đang được phát triển',
        'Kết quả xét nghiệm sẽ sớm được kích hoạt. Xin vui lòng thử lại sau.',
        Icons.engineering,
      );
    }

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

  Widget _buildFeatureInDevelopment(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMedicalData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
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
