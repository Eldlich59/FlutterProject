import 'package:flutter/material.dart';
import 'package:patient_application/config/supabase_config.dart';
import 'package:patient_application/screens/article/articles_screen.dart';
import 'package:patient_application/screens/chat_screen.dart';
import 'package:patient_application/screens/health_metrics_screen.dart';
import 'package:patient_application/screens/home_screen.dart';
import 'package:patient_application/screens/login_screen.dart';
import 'package:patient_application/screens/medical_records_screen.dart';
import 'package:patient_application/screens/profile_screen.dart';

// Export supabase instance for use in other files
export 'package:patient_application/config/supabase_config.dart' show supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await initializeSupabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 101, 54, 182),
        ),
        useMaterial3: true,
      ),
      home: _handleAuthState(),
    );
  }

  Widget _handleAuthState() {
    // Check if user is logged in
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(title: '', hideAppBar: true),
    const ProfileScreen(),
    const HealthMetricsScreen(),
    const ArticlesScreen(),
    const MedicalRecordsScreen(),
    const ChatListScreen(),
  ];

  final List<String> _titles = [
    'Trang chủ',
    'Hồ sơ',
    'Chỉ số sức khỏe',
    'Bản tin sức khỏe',
    'Hồ sơ y tế',
    'Chat với bác sĩ',
  ];

  final PageStorageBucket _bucket = PageStorageBucket();

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _signOut() async {
    // Store context before async operation
    final navigatorContext = context;

    try {
      await supabase.auth.signOut();

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Use the stored context for navigation
      Navigator.of(navigatorContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(
        navigatorContext,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  void _showNotifications() {
    // Only proceed if widget is still mounted
    if (!mounted) return;

    // Capture the context to use consistently
    final scaffoldContext = context;

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(
        content: Text('Bạn không có thông báo mới'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Call super.build for AutomaticKeepAliveClientMixin
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading:
            _selectedIndex == 0
                ? IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _showNotifications,
                  tooltip: 'Thông báo',
                )
                : null,
        actions: [
          // Hiển thị nút đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Capture the context to use in the dialog
              final dialogContext = context;

              // Hiển thị dialog xác nhận đăng xuất
              showDialog(
                context: dialogContext,
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
                          onPressed: () {
                            // Close dialog first
                            Navigator.pop(context);
                            // Then perform sign out
                            _signOut();
                          },
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
              );
            },
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      // Use PageStorage to maintain scroll position and state
      body: SafeArea(
        child: PageStorage(
          bucket: _bucket,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Needed for more than 3 items
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        // Reduce label font size to avoid overflow on smaller devices
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Sức khỏe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Bản tin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Y bạ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
