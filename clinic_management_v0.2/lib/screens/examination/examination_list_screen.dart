import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/examination.dart';
import '../../services/supabase_service.dart';
import 'examination_form_screen.dart';
import '../prescription/prescription_form_screen.dart';
import '../examination/examination_details_screen.dart';

class ExaminationListScreen extends StatefulWidget {
  final String?
      patientId; // Optional: to show examinations for specific patient

  const ExaminationListScreen({super.key, this.patientId});

  @override
  State<ExaminationListScreen> createState() => _ExaminationListScreenState();
}

class _ExaminationListScreenState extends State<ExaminationListScreen> {
  final _supabaseService = SupabaseService().examinationService;
  List<Examination> _examinations = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExaminations();
  }

  Future<void> _loadExaminations() async {
    try {
      setState(() => _isLoading = true);
      // Use the new method from SupabaseService
      final examinations =
          await _supabaseService.getExaminations(patientId: widget.patientId);
      if (mounted) {
        setState(() {
          _examinations = examinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách khám: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Examination> get _filteredExaminations {
    if (_searchQuery.isEmpty) return _examinations;
    return _examinations.where((exam) {
      final searchLower = _searchQuery.toLowerCase();
      return exam.patientName?.toLowerCase().contains(searchLower) ??
          false || exam.diagnosis.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientId != null
            ? 'Lịch sử khám bệnh'
            : 'Danh sách phiếu khám'),
      ),
      body: Column(
        children: [
          if (widget.patientId == null) // Only show search for full list
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Tìm kiếm phiếu khám',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadExaminations,
                    child: _buildExaminationList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToExaminationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExaminationList() {
    if (_filteredExaminations.isEmpty) {
      return const Center(
        child: Text('Không có phiếu khám'),
      );
    }

    return ListView.builder(
      itemCount: _filteredExaminations.length,
      itemBuilder: (context, index) {
        final examination = _filteredExaminations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(examination.patientName ?? 'Bệnh nhân'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Ngày khám: ${_dateFormat.format(examination.examinationDate)}'),
                Text('Chẩn đoán: ${examination.diagnosis}'),
                Text(
                    'Phí khám: ${_currencyFormat.format(examination.examinationFee)}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    _showExaminationDetails(examination);
                    break;
                  case 'edit':
                    _navigateToExaminationForm(context, examination);
                    break;
                  case 'delete':
                    _confirmDelete(examination);
                    break;
                  case 'prescription':
                    _navigateToPrescription(examination);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Xem chi tiết'),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Sửa phiếu khám'),
                ),
                const PopupMenuItem(
                  value: 'prescription',
                  child: Text('Kê đơn thuốc'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa'),
                ),
              ],
            ),
            onTap: () => _showExaminationDetails(examination),
            // Add visual feedback for tap
            tileColor: Colors.grey[50],
            hoverColor: Colors.blue[50],
          ),
        );
      },
    );
  }

  void _showExaminationDetails(Examination examination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExaminationDetailsScreen(
          examination: examination,
          onExaminationUpdated: _loadExaminations,
        ),
      ),
    );
  }

  Future<void> _navigateToExaminationForm(BuildContext context,
      [Examination? examination]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExaminationFormScreen(
          patientId: widget.patientId,
          examination: examination,
        ),
      ),
    );

    if (result == true) {
      _loadExaminations();
    }
  }

  void _navigateToPrescription(Examination examination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(
          examination: examination,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Examination examination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phiếu khám này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteExamination(examination.id);
        _loadExaminations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa phiếu khám')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }
}
