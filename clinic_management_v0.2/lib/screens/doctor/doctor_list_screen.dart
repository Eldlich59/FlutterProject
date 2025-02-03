import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/doctor/doctor_form.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen>
    with TickerProviderStateMixin {
  final _supabaseService = SupabaseService().doctorService;
  final _searchController = TextEditingController();
  List<Doctor> doctors = [];
  List<Doctor> filteredDoctors = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initialize FAB animation controller and animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Load doctors and start animations
    _loadDoctors().then((_) {
      _animationController.forward();
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterDoctors(String query) {
    setState(() {
      filteredDoctors = doctors
          .where((doctor) =>
              doctor.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;

    try {
      setState(() => isLoading = true);
      final updatedDoctors = await _supabaseService.getDoctor();
      if (mounted) {
        setState(() {
          doctors = updatedDoctors;
          filteredDoctors = updatedDoctors;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purpleTheme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF6750A4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        primary: const Color(0xFF6750A4),
        secondary: const Color(0xFFD0BCFF),
      ),
    );

    return Theme(
      data: purpleTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5F7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: purpleTheme.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Trở về trang chủ',
          ),
          title: const Text(
            'Quản lý Bác sĩ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Làm mới danh sách',
                onPressed: () async {
                  // Visual feedback animation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang cập nhật danh sách...'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  // Reset animation controller
                  _animationController.reset();
                  // Load the updated data
                  await _loadDoctors();
                  // Start the animation
                  if (mounted) {
                    _animationController.forward();
                  }
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bác sĩ...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF6750A4)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF6750A4)),
                    onPressed: () {
                      _searchController.clear();
                      _filterDoctors('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _filterDoctors,
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      )),
                      child: child,
                    ),
                  );
                },
                child: filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy bác sĩ nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchController.text.isNotEmpty)
                              Text(
                                'Thử tìm kiếm với từ khóa khác',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = filteredDoctors[index];
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final itemAnimation = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  (index / filteredDoctors.length) * 0.5,
                                  1.0,
                                  curve: Curves.easeOutQuart,
                                ),
                              );
                              return Transform.translate(
                                offset: Offset(
                                  0,
                                  30 * (1 - itemAnimation.value),
                                ),
                                child: Opacity(
                                  opacity: itemAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 200),
                              tween: Tween<double>(begin: 0.95, end: 1.0),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () => _showDoctorDetails(doctor),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.person,
                                              size: 35,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        doctor.name,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: doctor.isActive
                                                            ? Colors.green
                                                                .withOpacity(
                                                                    0.1)
                                                            : Colors.red
                                                                .withOpacity(
                                                                    0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        doctor.isActive
                                                            ? 'Đang hoạt động'
                                                            : 'Ngừng hoạt động',
                                                        style: TextStyle(
                                                          color: doctor.isActive
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    doctor.specialty,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Ngày bắt đầu: ${_formatDate(doctor.startDate)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton(
                                            icon: const Icon(Icons.more_vert),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'details',
                                                child: const ListTile(
                                                  leading: Icon(Icons.info),
                                                  title: Text('Chi tiết'),
                                                  dense: true,
                                                ),
                                                onTap: () => Future.delayed(
                                                  const Duration(seconds: 0),
                                                  () => _showDoctorDetails(
                                                      doctor),
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: const ListTile(
                                                  leading: Icon(Icons.edit),
                                                  title: Text('Sửa'),
                                                  dense: true,
                                                ),
                                                onTap: () => Future.delayed(
                                                  const Duration(seconds: 0),
                                                  () => _showDoctorForm(
                                                      context, doctor),
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: const ListTile(
                                                  leading: Icon(Icons.delete,
                                                      color: Colors.red),
                                                  title: Text('Xóa',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                  dense: true,
                                                ),
                                                onTap: () => Future.delayed(
                                                  const Duration(seconds: 0),
                                                  () => _deleteDoctor(doctor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => _showDoctorForm(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Thêm bác sĩ',
                style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF6750A4),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDoctorDetails(Doctor doctor) {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderSection(doctor),
                      const SizedBox(height: 24),
                      _buildInfoSection(doctor),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, doctor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }

  Widget _buildHeaderSection(Doctor doctor) {
    return Stack(
      children: [
        Column(
          children: [
            Hero(
              tag: 'doctor_avatar_${doctor.id}',
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              doctor.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(doctor.isActive),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailTile(
            Icons.work_rounded,
            'Chuyên khoa',
            doctor.specialty,
            const Color(0xFF5B8FF9),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailTile(
            Icons.phone_rounded,
            'Điện thoại',
            doctor.phone ?? 'N/A',
            const Color(0xFF5AD8A6),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailTile(
            Icons.email_rounded,
            'Email',
            doctor.email ?? 'N/A',
            const Color(0xFFF6BD16),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailTile(
            Icons.cake_rounded,
            'Ngày sinh',
            _formatDate(doctor.dateOfBirth),
            const Color(0xFF5D7092),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailTile(
            Icons.calendar_today_rounded,
            'Ngày bắt đầu',
            _formatDate(doctor.startDate),
            const Color(0xFF6750A4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Doctor doctor) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showDoctorForm(context, doctor);
            },
            child: const Text('Cập nhật'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF5AD8A6) : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDoctorForm(BuildContext context, [Doctor? doctor]) async {
    final result = await Navigator.push<Doctor>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              doctor == null ? 'Thêm Bác sĩ' : 'Cập nhật Bác sĩ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF6750A4),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: DoctorForm(doctor: doctor),
        ),
      ),
    );

    if (result != null) {
      // Reset the animation controller first
      _animationController.reset();

      // Load the updated data
      await _loadDoctors();

      // Add a small delay before starting the animation
      await Future.delayed(const Duration(milliseconds: 100));

      // Start the animation
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  Future<void> _deleteDoctor(Doctor doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bác sĩ ${doctor.name}?'),
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

    if (confirm == true) {
      try {
        await _supabaseService.deleteDoctor(doctor.id);
        await _loadDoctors();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting doctor: $e')),
        );
      }
    }
  }
}
