import 'package:flutter/material.dart';
import 'models/patient_model.dart';
import 'services/patient_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Bệnh Nhân',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PatientListScreen(),
    );
  }
}

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  late Future<List<Patient>> futurePatients;

  @override
  void initState() {
    super.initState();
    futurePatients = PatientService().fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Bệnh Nhân'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Patient>>(
        future: futurePatients,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Patient patient = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(patient.name[0]),
                    ),
                    title: Text(
                      patient.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tuổi: ${patient.age}'),
                        Text('Giới tính: ${patient.gender}'),
                        Text('Tình trạng: ${patient.medicalCondition}'),
                        Text('Liên hệ: ${patient.contactNumber}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Có thể thêm chức năng thêm bệnh nhân mới
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chức năng thêm bệnh nhân')),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
