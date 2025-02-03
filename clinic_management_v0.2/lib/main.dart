import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('Initializing Supabase...'); // Debug log

    await Supabase.initialize(
      url: 'https://cfznidhevnxqobcllsnt.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmem5pZGhldm54cW9iY2xsc250Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1NTI5MzQsImV4cCI6MjA1NDEyODkzNH0.dWrSeHwSEDhc10-8_GElCDVYEvN0aAjhgj_-uHIs1Uw',
    );

    print('Supabase initialized successfully'); // Debug log

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error initializing app: $e'); // Debug log
    print('Stack trace: $stackTrace'); // Debug log
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phòng Khám',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const HomeScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}
