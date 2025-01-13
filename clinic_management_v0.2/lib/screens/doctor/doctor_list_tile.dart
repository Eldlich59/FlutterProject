import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';

class DoctorListTile extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DoctorListTile({
    super.key,
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(doctor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khoa: ${doctor.specialty}'),
            if (doctor.phone != null && doctor.phone!.isNotEmpty)
              Text('SĐT: ${doctor.phone}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
