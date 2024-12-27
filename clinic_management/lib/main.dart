import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database/database_service.dart';

import 'repositories/patient_repository.dart';
import 'repositories/medicine_repository.dart';
import 'repositories/medical_record_repository.dart';
import 'repositories/prescription_repository.dart';
import 'repositories/invoice_repository.dart';

import 'providers/patient_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/medical_record_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/invoice_provider.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  try {
    // Platform-specific database configuration
    if (!kIsWeb) {
      // Native platform initialization
      final dbService = DatabaseService.instance;
      await dbService.database;

      runApp(
        MultiProvider(
          providers: [
            Provider<DatabaseService>.value(value: dbService),
            Provider<PatientRepository>(
              create: (_) => PatientRepository(dbService),
            ),
            Provider<MedicineRepository>(
              create: (_) => MedicineRepository(dbService),
            ),
            Provider<MedicalRecordRepository>(
              create: (_) => MedicalRecordRepository(dbService),
            ),
            Provider<PrescriptionRepository>(
              create: (_) => PrescriptionRepository(dbService),
            ),
            Provider<InvoiceRepository>(
              create: (_) => InvoiceRepository(dbService),
            ),
            ChangeNotifierProvider<PatientProvider>(
              create: (context) => PatientProvider(
                repository: context.read<PatientRepository>(),
              ),
            ),
            ChangeNotifierProvider<MedicineProvider>(
              create: (context) => MedicineProvider(
                repository: context.read<MedicineRepository>(),
              ),
            ),
            ChangeNotifierProvider<MedicalRecordProvider>(
              create: (context) => MedicalRecordProvider(
                repository: context.read<MedicalRecordRepository>(),
              ),
            ),
            ChangeNotifierProvider<PrescriptionProvider>(
              create: (context) => PrescriptionProvider(
                repository: context.read<PrescriptionRepository>(),
              ),
            ),
            ChangeNotifierProvider<InvoiceProvider>(
              create: (context) => InvoiceProvider(
                repository: context.read<InvoiceRepository>(),
              ),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ClinicApp(),
          ),
        ),
      );
    } else {
      // Web platform - defer initialization to web_entrypoint.dart
      runApp(const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ClinicApp(),
      ));
    }
  } catch (e) {
    logger.e('Failed to initialize app', error: e);
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error: ${e.toString()}'),
        ),
      ),
    ));
  }
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
