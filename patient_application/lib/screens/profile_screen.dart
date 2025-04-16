import 'package:flutter/material.dart';
import 'package:patient_application/models/patient.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Patient? _patient;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for editing
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadPatientData();
  }

  void _initControllers() {
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyContactController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final data =
            await supabase.from('patients').select().eq('id', userId).single();

        setState(() {
          _patient = Patient.fromJson(data);
          _fullNameController.text = _patient?.fullName ?? '';
          _emailController.text = _patient?.email ?? '';
          _phoneController.text = _patient?.phoneNumber ?? '';
          _addressController.text = _patient?.address ?? '';
          _emergencyContactController.text = _patient?.emergencyContact ?? '';
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu bệnh nhân: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải thông tin: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePatientData() async {
    if (_patient == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final updatedPatient = _patient!.copyWith(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        emergencyContact: _emergencyContactController.text,
      );

      await supabase
          .from('patients')
          .update(updatedPatient.toJson())
          .eq('id', _patient!.id);

      setState(() {
        _patient = updatedPatient;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông tin đã được cập nhật')),
      );
    } catch (e) {
      debugPrint('Lỗi khi cập nhật dữ liệu bệnh nhân: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật thông tin: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _patient == null
              ? const Center(child: Text('Không tìm thấy thông tin bệnh nhân'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildMedicalInfoSection(),
                    const SizedBox(height: 24),
                    _buildEmergencySection(),
                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton(
                          onPressed: _savePatientData,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 45),
                          ),
                          child: const Text('Lưu thông tin'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    _patient?.avatarUrl != null
                        ? CachedNetworkImageProvider(_patient!.avatarUrl!)
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        // Thêm logic để thay đổi ảnh đại diện
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            TextField(
              controller: _fullNameController,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Họ và tên',
                border: InputBorder.none,
              ),
            )
          else
            Text(
              _patient?.fullName ?? 'Chưa cập nhật',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          Text(
            'Tuổi: ${_patient?.age ?? '--'} | Nhóm máu: ${_patient?.bloodType ?? '--'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông tin cá nhân',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEditing) const Icon(Icons.edit_note, color: Colors.blue),
              ],
            ),
            const Divider(),
            _isEditing
                ? Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                  ],
                )
                : Column(
                  children: [
                    _buildInfoRow('Email', _patient?.email),
                    _buildInfoRow('Số điện thoại', _patient?.phoneNumber),
                    _buildInfoRow('Địa chỉ', _patient?.address),
                    _buildInfoRow('Ngày sinh', _patient?.formattedDateOfBirth),
                    _buildInfoRow('Giới tính', _patient?.gender),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    final allergiesList = _patient?.allergies;
    final conditionsList = _patient?.chronicConditions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin y tế',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              'Chiều cao',
              _patient?.height != null
                  ? '${_patient!.height} cm'
                  : 'Chưa cập nhật',
            ),
            _buildInfoRow(
              'Cân nặng',
              _patient?.weight != null
                  ? '${_patient!.weight} kg'
                  : 'Chưa cập nhật',
            ),
            _buildInfoRow(
              'BMI',
              _patient?.bmi != null
                  ? _patient!.bmi!.toStringAsFixed(1)
                  : 'Chưa cập nhật',
            ),
            const SizedBox(height: 8),
            Text('Dị ứng', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  allergiesList != null && allergiesList.isNotEmpty
                      ? allergiesList
                          .map(
                            (allergy) => Chip(
                              label: Text(allergy),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          )
                          .toList()
                      : [
                        Chip(
                          label: const Text('Không có'),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                      ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bệnh mãn tính',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  conditionsList != null && conditionsList.isNotEmpty
                      ? conditionsList
                          .map(
                            (condition) => Chip(
                              label: Text(condition),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          )
                          .toList()
                      : [
                        Chip(
                          label: const Text('Không có'),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                      ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liên hệ khẩn cấp',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _isEditing
                ? TextField(
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(
                    labelText: 'Người liên hệ khẩn cấp',
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                )
                : _buildInfoRow(
                  'Người liên hệ',
                  _patient?.emergencyContact ?? 'Chưa cập nhật',
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'Chưa cập nhật')),
        ],
      ),
    );
  }
}
