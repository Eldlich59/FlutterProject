import 'package:flutter/material.dart';
import 'package:patient_application/models/patient.dart';
import 'package:patient_application/models/health_metrics.dart';
import 'package:patient_application/models/article.dart';
import 'package:patient_application/screens/health_metrics_screen.dart';
import 'package:patient_application/screens/articles_screen.dart';
import 'package:patient_application/screens/medical_records_screen.dart';
import 'package:patient_application/screens/chat_screen.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        // Xử lý chưa đăng nhập
        return;
      }

      // Tải thông tin bệnh nhân
      final patientData =
          await supabase.from('patients').select().eq('id', userId).single();

      setState(() => _patient = Patient.fromJson(patientData));

      // Tải chỉ số sức khỏe gần đây
      final healthData = await supabase
          .from('health_metrics')
          .select()
          .eq('patient_id', userId)
          .order('timestamp', ascending: false)
          .limit(3);

      setState(() {
        _recentMetrics =
            healthData
                .map<HealthMetrics>((json) => HealthMetrics.fromJson(json))
                .toList();
      });

      // Tải bài viết nổi bật
      final articleData = await supabase
          .from('articles')
          .select()
          .eq('is_featured', true)
          .order('publish_date', ascending: false)
          .limit(3);

      setState(() {
        _featuredArticles =
            articleData.map<Article>((json) => Article.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chỉ số sức khỏe gần đây',
              style: Theme.of(context).textTheme.titleLarge,
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
            ),
          ],
        ),
        const SizedBox(height: 16),
        _recentMetrics.isEmpty
            ? _buildEmptyState(
              'Chưa có dữ liệu sức khỏe',
              'Thêm chỉ số mới để theo dõi sức khỏe của bạn',
              Icons.monitor_heart_outlined,
            )
            : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _recentMetrics.length,
              itemBuilder: (context, index) {
                final metric = _recentMetrics[index];
                return _buildHealthMetricCard(metric);
              },
            ),
      ],
    );
  }

  Widget _buildHealthMetricCard(HealthMetrics metric) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${metric.timestamp.day}/${metric.timestamp.month}/${metric.timestamp.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            if (metric.bmi != null)
              _buildMetricItem('BMI', metric.bmi!.toStringAsFixed(1)),
            if (metric.heartRate != null)
              _buildMetricItem('Nhịp tim', '${metric.heartRate} bpm'),
            if (metric.bloodPressure != null)
              _buildMetricItem('Huyết áp', metric.bloodPressure.toString()),
            if (metric.spo2 != null)
              _buildMetricItem('SpO2', '${metric.spo2}%'),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticlesSection(BuildContext context) {
    return Column(
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
                  ),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _featuredArticles.isEmpty
            ? _buildEmptyState(
              'Chưa có bài viết',
              'Hãy quay lại sau để xem các bài viết mới nhất',
              Icons.description_outlined,
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _featuredArticles.length,
              itemBuilder: (context, index) {
                final article = _featuredArticles[index];
                return _buildArticleCard(article);
              },
            ),
      ],
    );
  }

  Widget _buildArticleCard(Article article) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Chuyển đến trang chi tiết bài viết
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) =>
                          const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.briefContent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        article.timeAgo,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
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
        Text('Lịch hẹn sắp tới', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildEmptyState(
          'Không có lịch hẹn',
          'Bạn chưa có lịch hẹn nào sắp tới',
          Icons.event_busy,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
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

// Màn hình chi tiết bài viết
class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                article.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background:
                  article.thumbnailUrl != null
                      ? CachedNetworkImage(
                        imageUrl: article.thumbnailUrl!,
                        fit: BoxFit.cover,
                      )
                      : Container(color: Theme.of(context).primaryColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(article.authorName[0])),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(article.timeAgo),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.content,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
