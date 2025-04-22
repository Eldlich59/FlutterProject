import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:patient_application/models/patient.dart';
import 'package:patient_application/models/health_metrics.dart';
import 'package:patient_application/models/article.dart';
import 'package:patient_application/models/appointment.dart';
import 'package:patient_application/screens/health_metrics_screen.dart';
import 'package:patient_application/screens/article/articles_screen.dart';
import 'package:patient_application/screens/medical_records_screen.dart';
import 'package:patient_application/screens/chat_screen.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patient_application/config/supabase_config.dart';
import 'package:patient_application/screens/appointment/appointments_screen.dart'; // Add this line
import 'package:patient_application/screens/appointment/book_appointment_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  final bool hideAppBar; // Thêm tham số mới để ẩn AppBar

  const HomeScreen({
    super.key,
    required this.title,
    this.hideAppBar = false, // Mặc định không ẩn
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Patient? _patient;
  List<HealthMetrics> _recentMetrics = [];
  List<Article> _featuredArticles = [];
  List<Appointment> _upcomingAppointments = []; // Add this line
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Lấy thông tin người dùng
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Không thể tải dữ liệu: Người dùng chưa đăng nhập');
        return;
      }

      // Tải thông tin bệnh nhân - với xử lý lỗi
      try {
        final patientData =
            await supabase.from('patients').select().eq('id', userId).single();
        setState(() => _patient = Patient.fromJson(patientData));
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu bệnh nhân: $e');
        // Xử lý trường hợp bảng patients không tồn tại hoặc không có dữ liệu
        // Tạo đối tượng Patient mặc định chỉ với ID
        setState(() {
          _patient = Patient(
            id: userId,
            fullName: 'Bệnh nhân',
            email: supabase.auth.currentUser?.email ?? 'Unknown',
            dateOfBirth: DateTime(
              1900,
              1,
              1,
            ), // Using default date instead of null
            gender: '',
            bloodType: '',
            address: '',
            phoneNumber: '',
          );
        });

        // Tạo bản ghi patient nếu bảng tồn tại
        _createPatientRecord(userId);
      }

      // Tải chỉ số sức khỏe gần đây
      try {
        final healthData = await supabase
            .from('health_metrics')
            .select()
            .eq('patient_id', userId)
            .order('timestamp', ascending: false)
            .limit(3);

        debugPrint('Đã tải dữ liệu sức khỏe: ${healthData.length} bản ghi');

        setState(() {
          _recentMetrics =
              healthData
                  .map<HealthMetrics>((json) => HealthMetrics.fromJson(json))
                  .toList();
        });
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu sức khỏe: $e');
        setState(() => _recentMetrics = []);
      }

      // Tải bài viết nổi bật
      try {
        // First try to get featured articles
        final featuredData = await supabase
            .from('articles')
            .select()
            .eq('is_featured', true)
            .order('publish_date', ascending: false)
            .limit(3);

        List<Article> featuredArticles = List<Article>.from(
          featuredData.map((json) => Article.fromJson(json)),
        );

        // If we don't have enough featured articles, get some regular ones too
        if (featuredArticles.length < 3) {
          final regularData = await supabase
              .from('articles')
              .select()
              .eq('is_featured', false)
              .order('publish_date', ascending: false)
              .limit(3 - featuredArticles.length);

          featuredArticles.addAll(
            List<Article>.from(
              regularData.map((json) => Article.fromJson(json)),
            ),
          );
        }

        setState(() {
          _featuredArticles = featuredArticles;
        });
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu bài viết: $e');
        setState(() => _featuredArticles = []);
      }

      // Load upcoming appointments
      try {
        final appointmentsData = await supabase
            .from('appointments')
            .select()
            .eq('patient_id', userId)
            .eq('status', 'scheduled')
            .gte('date_time', DateTime.now().toIso8601String())
            .order('date_time')
            .limit(5);

        debugPrint('Đã tải lịch hẹn: ${appointmentsData.length} lịch hẹn');

        setState(() {
          _upcomingAppointments =
              appointmentsData
                  .map<Appointment>((json) => Appointment.fromJson(json))
                  .toList();
        });
      } catch (e) {
        debugPrint('Lỗi khi tải lịch hẹn: $e');
        setState(() => _upcomingAppointments = []);
      }
    } catch (e) {
      debugPrint('Lỗi chung khi tải dữ liệu dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Phương thức tạo bản ghi bệnh nhân nếu chưa tồn tại
  Future<void> _createPatientRecord(String userId) async {
    try {
      // Kiểm tra xem bảng đã tồn tại chưa bằng cách thử lấy một bản ghi
      await supabase.from('patients').select('id').limit(1);

      // Nếu bảng tồn tại, thử tạo bản ghi mới
      final email = supabase.auth.currentUser?.email;
      if (email != null) {
        await supabase.from('patients').insert({
          'id': userId,
          'full_name': 'Bệnh nhân',
          'email': email,
        });
        debugPrint('Đã tạo bản ghi bệnh nhân mới');
      }
    } catch (e) {
      // Có thể bảng không tồn tại hoặc lỗi khác
      debugPrint('Không thể tạo bản ghi bệnh nhân: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chỉ hiển thị AppBar nếu không yêu cầu ẩn
      appBar:
          widget.hideAppBar
              ? null
              : AppBar(
                // Thêm tiêu đề ở giữa để cân đối
                title: Text(widget.title, style: const TextStyle(fontSize: 18)),
                centerTitle: true,
                // Điều chỉnh thứ tự và kiểu icon
                leading: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bạn không có thông báo mới'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                actions: [
                  // Thêm nút debug nếu đang ở chế độ debug
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: () => _testHealthMetricsLoad(),
                      tooltip: 'Test Load Data',
                    ),
                  // Nút đăng xuất ở bên phải
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Đăng xuất'),
                              content: const Text(
                                'Bạn có chắc chắn muốn đăng xuất không?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await supabase.auth.signOut();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    }
                                  },
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildHealthMetricsSection(context),
                      const SizedBox(height: 24),
                      _buildFeaturedArticlesSection(context),
                      const SizedBox(height: 24),
                      _buildUpcomingAppointmentsSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildWelcomeCard() {
    final greeting = _getGreeting();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  _patient?.avatarUrl != null
                      ? CachedNetworkImageProvider(_patient!.avatarUrl!)
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _patient?.fullName ?? 'Bệnh nhân',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chúc bạn một ngày tốt lành!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour < 18) {
      return 'Chào buổi chiều';
    } else {
      return 'Chào buổi tối';
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Truy cập nhanh', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              icon: Icons.monitor_heart,
              color: Colors.redAccent,
              label: 'Chỉ số\nsức khỏe',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthMetricsScreen(),
                    ),
                  ),
            ),
            _buildQuickActionItem(
              icon: Icons.event_available,
              color: Colors.blueAccent,
              label: 'Đặt lịch\nkhám',
              onTap: () {
                // Chuyển đến màn hình đặt lịch (có thể thêm sau)
              },
            ),
            _buildQuickActionItem(
              icon: Icons.message,
              color: Colors.greenAccent,
              label: 'Chat với\nbác sĩ',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  ),
            ),
            _buildQuickActionItem(
              icon: Icons.assignment_outlined,
              color: Colors.purpleAccent,
              label: 'Y bạ\nđiện tử',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicalRecordsScreen(),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Chỉ số sức khỏe gần đây',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthMetricsScreen(),
                    ),
                  ),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Xem tất cả'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _recentMetrics.isEmpty
            ? _buildEmptyState(
              'Chưa có dữ liệu sức khỏe',
              'Thêm chỉ số mới để theo dõi sức khỏe của bạn',
              Icons.monitor_heart_outlined,
              onAction:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthMetricsScreen(),
                    ),
                  ),
              actionLabel: 'Thêm chỉ số mới',
            )
            : _buildCompactHealthMetricsGrid(),
      ],
    );
  }

  Widget _buildCompactHealthMetricsGrid() {
    // Limit to max 2 cards to keep the home screen compact
    final metrics = _recentMetrics.take(2).toList();

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthMetricsScreen(),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${metric.timestamp.day}/${metric.timestamp.month}/${metric.timestamp.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Metrics row with Wrap for better flow
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (metric.bmi != null)
                        _buildCompactMetricChip(
                          'BMI',
                          metric.bmi!.toStringAsFixed(1),
                          Icons.monitor_weight,
                        ),
                      if (metric.heartRate != null)
                        _buildCompactMetricChip(
                          'Nhịp tim',
                          '${metric.heartRate} bpm',
                          Icons.favorite,
                        ),
                      if (metric.bloodPressure != null)
                        _buildCompactMetricChip(
                          'Huyết áp',
                          metric.bloodPressure.toString(),
                          Icons.favorite_border,
                        ),
                      if (metric.spo2 != null)
                        _buildCompactMetricChip(
                          'SpO2',
                          '${metric.spo2}%',
                          Icons.air,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticlesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bản tin sức khỏe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArticlesScreen(),
                      ),
                    ).then(
                      (_) => _loadDashboardData(),
                    ), // Refresh when returning
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _featuredArticles.isEmpty
              ? _buildEmptySection(
                'Không có bài viết nổi bật',
                Icons.article_outlined,
              )
              : Column(
                children:
                    _featuredArticles
                        .map(
                          (article) => _buildHomeArticleCard(context, article),
                        )
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildHomeArticleCard(BuildContext context, Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );

          // Refresh dashboard if article was modified or deleted
          if (result == true) {
            _loadDashboardData();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image
            if (article.thumbnailUrl != null)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured badge if applicable
                  if (article.isFeatured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Nổi bật',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Brief content/summary
                  Text(
                    article.briefContent,
                    style: TextStyle(color: Colors.grey[700], height: 1.3),
                    maxLines:
                        3, // Increase from 2 to 3 lines for slightly more preview content
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Author and date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Author info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.8),
                            child: Text(
                              article.authorName[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.authorName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      // Date info
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            article.timeAgo,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Categories
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        article.categories.map((category) {
                          return Chip(
                            label: Text(category),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lịch hẹn sắp tới',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentsScreen(),
                    ),
                  ).then((_) => _loadDashboardData()),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _upcomingAppointments.isEmpty
            ? _buildEmptyState(
              'Không có lịch hẹn',
              'Bạn chưa có lịch hẹn nào sắp tới',
              Icons.event_busy,
              onAction: () => _showAppointmentForm(),
              actionLabel: 'Đặt lịch khám',
            )
            : Column(
              children:
                  _upcomingAppointments
                      .map((appointment) => _buildAppointmentCard(appointment))
                      .toList(),
            ),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor avatar or placeholder
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    appointment.doctorAvatarUrl != null
                        ? CachedNetworkImageProvider(
                          appointment.doctorAvatarUrl!,
                        )
                        : null,
                child:
                    appointment.doctorAvatarUrl == null
                        ? Icon(Icons.person, size: 24, color: Colors.grey[300])
                        : null,
              ),
              const SizedBox(width: 16),
              // Appointment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date and time with icon
                        Row(
                          children: [
                            const Icon(Icons.event, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              appointment.formattedDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 14),
                            const SizedBox(width: 4),
                            Text(appointment.formattedTime),
                          ],
                        ),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appointment.getStatusColor().withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            appointment.getStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: appointment.getStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Doctor name and specialty
                    Text(
                      'BS. ${appointment.doctorName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      appointment.doctorSpecialty,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum size needed
          children: [
            Icon(icon, size: 36, color: Colors.grey[400]), // Smaller icon
            const SizedBox(height: 8), // Reduced spacing
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ), // Smaller text
            ),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ), // Smaller text
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 8), // Reduced spacing
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ), // Compact button
                  minimumSize: const Size(0, 32), // Smaller button height
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 12),
                ), // Smaller text
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Thêm hàm để kiểm tra và tải dữ liệu sức khỏe
  Future<void> _testHealthMetricsLoad() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy ID người dùng')),
        );
        return;
      }

      // Hiển thị thông báo tải dữ liệu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải dữ liệu sức khỏe...')),
      );

      // Gọi API để lấy dữ liệu
      final healthData = await supabase
          .from('health_metrics')
          .select()
          .eq('patient_id', userId)
          .order('timestamp', ascending: false);

      // Hiển thị thông tin debug
      debugPrint('TEST: Số lượng bản ghi: ${healthData.length}');
      if (healthData.isNotEmpty) {
        debugPrint('TEST: Bản ghi đầu tiên: ${healthData[0]}');
      }

      // Hiển thị dialog với thông tin chi tiết
      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Kết quả kiểm tra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số lượng bản ghi: ${healthData.length}'),
                    const SizedBox(height: 8),
                    if (healthData.isEmpty)
                      const Text('Không có dữ liệu sức khỏe cho người dùng này')
                    else ...[
                      const Text('Dữ liệu mẫu:'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          healthData[0].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadDashboardData(); // Refresh dashboard data
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    } catch (e) {
      debugPrint('Lỗi khi test tải dữ liệu: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and status
                Row(
                  children: [
                    const Text(
                      'Chi tiết lịch hẹn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appointment.getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        appointment.getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: appointment.getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Doctor info
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage:
                        appointment.doctorAvatarUrl != null
                            ? CachedNetworkImageProvider(
                              appointment.doctorAvatarUrl!,
                            )
                            : null,
                    child:
                        appointment.doctorAvatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                  ),
                  title: Text('BS. ${appointment.doctorName}'),
                  subtitle: Text(appointment.doctorSpecialty),
                ),

                const Divider(height: 24),

                // Date and time
                _detailRow(Icons.event, 'Ngày', appointment.formattedDate),
                const SizedBox(height: 12),
                _detailRow(Icons.access_time, 'Giờ', appointment.formattedTime),
                const SizedBox(height: 12),
                _detailRow(Icons.location_on, 'Địa điểm', appointment.location),

                // Notes if available
                if (appointment.notes != null &&
                    appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailRow(Icons.note, 'Ghi chú', appointment.notes!),
                ],

                const SizedBox(height: 24),

                // Action buttons
                if (appointment.status == 'scheduled') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Hủy lịch hẹn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rescheduleAppointment(appointment),
                          icon: const Icon(Icons.edit_calendar),
                          label: const Text('Đổi lịch hẹn'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  void _showAppointmentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
    ).then((_) => _loadDashboardData());
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hủy lịch hẹn'),
            content: Text(
              'Bạn có chắc chắn muốn hủy lịch hẹn với BS. ${appointment.doctorName} vào ${appointment.formattedDateTime}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Không'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Có, hủy lịch'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await supabase
            .from('appointments')
            .update({'status': 'cancelled'})
            .eq('id', appointment.id);

        _loadDashboardData(); // Reload data

        if (mounted) {
          Navigator.pop(context); // Close details sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy lịch hẹn thành công')),
          );
        }
      } catch (e) {
        debugPrint('Lỗi khi hủy lịch hẹn: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy lịch hẹn: $e')));
        }
      }
    }
  }

  void _rescheduleAppointment(Appointment appointment) {
    // Placeholder for reschedule functionality
    // Would normally navigate to reschedule screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đổi lịch đang được phát triển')),
    );
  }
}
