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
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  List<String> _allergies = [];
  List<String> _chronicConditions = [];

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
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      try {
        // Thử tải dữ liệu bệnh nhân
        final data =
            await supabase
                .from('patients')
                .select()
                .eq('id', userId)
                .maybeSingle();

        if (data != null) {
          // Đã tìm thấy hồ sơ bệnh nhân
          setState(() {
            _patient = Patient.fromJson(data);
            _fullNameController.text = _patient?.fullName ?? '';
            _emailController.text = _patient?.email ?? '';
            _phoneController.text = _patient?.phoneNumber ?? '';
            _addressController.text = _patient?.address ?? '';
            _emergencyContactController.text = _patient?.emergencyContact ?? '';
            _heightController.text = _patient?.height?.toString() ?? '';
            _weightController.text = _patient?.weight?.toString() ?? '';
            _allergies = _patient?.allergies?.toList() ?? [];
            _chronicConditions = _patient?.chronicConditions?.toList() ?? [];
          });
        } else {
          // Không tìm thấy hồ sơ bệnh nhân - tạo một hồ sơ mới
          debugPrint(
            'Không tìm thấy hồ sơ bệnh nhân cho người dùng $userId - tạo mới',
          );

          // Lấy thông tin từ bảng auth.users
          final authUser = await supabase.auth.getUser();
          String email = authUser.user?.email ?? '';

          // Tạo bản ghi bệnh nhân mới với các trường cơ bản
          final patientData = {
            'id': userId,
            'full_name': '', // Sẽ yêu cầu người dùng cập nhật
            'email': email,
          };

          // Thêm vào cơ sở dữ liệu
          await supabase.from('patients').insert(patientData);

          // Tạo đối tượng bệnh nhân mới trong ứng dụng
          setState(() {
            _patient = Patient(
              id: userId,
              fullName: '',
              email: email,
              allergies: [],
              chronicConditions: [],
              dateOfBirth: DateTime(1900, 1, 1), // Default date instead of null
              gender: '',
              bloodType: '',
              address: '',
              phoneNumber: '',
            );

            // Cập nhật controllers
            _emailController.text = email;

            // Tự động bật chế độ chỉnh sửa để người dùng cập nhật thông tin
            _isEditing = true;
          });
        }
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu bệnh nhân: $e');

        // Nếu lỗi xảy ra khi truy vấn, tạo đối tượng bệnh nhân trống
        final userId = supabase.auth.currentUser!.id;
        final email = supabase.auth.currentUser!.email ?? '';

        setState(() {
          _patient = Patient(
            id: userId,
            fullName: '',
            email: email,
            allergies: [],
            chronicConditions: [],
            dateOfBirth: DateTime(1900, 1, 1), // Add default date
            gender: '',
            bloodType: '',
            address: '',
            phoneNumber: '',
          );

          _emailController.text = email;
          _isEditing =
              true; // Bật chế độ chỉnh sửa để người dùng nhập thông tin
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu bệnh nhân: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải thông tin: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePatientData() async {
    if (_patient == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Parse height and weight
      double? height;
      double? weight;

      try {
        if (_heightController.text.trim().isNotEmpty) {
          height = double.parse(_heightController.text.trim());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chiều cao không hợp lệ')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        if (_weightController.text.trim().isNotEmpty) {
          weight = double.parse(_weightController.text.trim());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cân nặng không hợp lệ')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Chuẩn bị dữ liệu cập nhật với cấu trúc đúng cho Supabase
      final Map<String, dynamic> updateData = {
        'full_name': _fullNameController.text.trim(),
      };

      // Chuyển đổi các giá trị số thập phân thành số nguyên cho cơ sở dữ liệu
      if (height != null) {
        updateData['height'] = height.toInt(); // Chuyển đổi thành số nguyên
      }

      if (weight != null) {
        updateData['weight'] = weight.toInt(); // Chuyển đổi thành số nguyên
      }

      // Xử lý các mảng
      updateData['allergies'] = _allergies;
      updateData['chronic_conditions'] = _chronicConditions;

      // Chỉ thêm các trường văn bản khi có giá trị
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        updateData['email'] = email;
      }

      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        updateData['phone_number'] = phone;
      }

      final address = _addressController.text.trim();
      if (address.isNotEmpty) {
        updateData['address'] = address;
      }

      final emergency = _emergencyContactController.text.trim();
      if (emergency.isNotEmpty) {
        updateData['emergency_contact'] = emergency;
      }

      // Debug: Ghi log dữ liệu sẽ cập nhật
      debugPrint('Cập nhật dữ liệu: $updateData');

      // Gọi API để cập nhật
      await supabase.from('patients').update(updateData).eq('id', _patient!.id);

      // Cập nhật state - giữ nguyên kiểu double trong model
      final updatedPatient = _patient!.copyWith(
        fullName: _fullNameController.text.trim(),
        email: email.isNotEmpty ? email : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        address: address.isNotEmpty ? address : null,
        emergencyContact: emergency.isNotEmpty ? emergency : null,
        height: height, // Giữ nguyên kiểu double trong model
        weight: weight, // Giữ nguyên kiểu double trong model
        allergies: _allergies,
        chronicConditions: _chronicConditions,
      );

      setState(() {
        _patient = updatedPatient;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thông tin đã được cập nhật')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi cập nhật dữ liệu bệnh nhân: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật thông tin: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  'Thông tin y tế',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEditing) const Icon(Icons.edit_note, color: Colors.blue),
              ],
            ),
            const Divider(),
            if (_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Height and weight in a row
                  Row(
                    children: [
                      // Height field
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Chiều cao (cm)',
                            suffixText: 'cm',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Weight field
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg)',
                            suffixText: 'kg',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Allergies section
                  const Text(
                    'Dị ứng',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildChipInputField(
                    _allergies,
                    onAdd: (value) {
                      setState(() => _allergies.add(value));
                    },
                    onDelete: (index) {
                      setState(() => _allergies.removeAt(index));
                    },
                    hintText: 'Thêm dị ứng',
                  ),

                  const SizedBox(height: 16),

                  // Chronic conditions section
                  const Text(
                    'Bệnh mãn tính',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildChipInputField(
                    _chronicConditions,
                    onAdd: (value) {
                      setState(() => _chronicConditions.add(value));
                    },
                    onDelete: (index) {
                      setState(() => _chronicConditions.removeAt(index));
                    },
                    hintText: 'Thêm bệnh mãn tính',
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    'Dị ứng',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  _buildChipList(_patient?.allergies),

                  const SizedBox(height: 8),
                  Text(
                    'Bệnh mãn tính',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  _buildChipList(_patient?.chronicConditions),
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

  Widget _buildChipList(List<String>? items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items != null && items.isNotEmpty
              ? items
                  .map(
                    (item) => Chip(
                      label: Text(item),
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
    );
  }

  Widget _buildChipInputField(
    List<String> items, {
    required Function(String) onAdd,
    required Function(int) onDelete,
    required String hintText,
  }) {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show existing items
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(items.length, (index) {
              return Chip(
                label: Text(items[index]),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onDelete(index),
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
              );
            }),
            // Input field as a chip
            InputChip(
              label: SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      onAdd(value);
                      controller.clear();
                    }
                  },
                ),
              ),
              backgroundColor: Colors.grey.withOpacity(0.1),
            ),
          ],
        ),
      ],
    );
  }
}
