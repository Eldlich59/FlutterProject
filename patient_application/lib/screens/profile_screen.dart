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

  // Controllers for editing - khởi tạo ngay lập tức
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dateOfBirthController =
      TextEditingController(); // Khởi tạo ngay
  String _selectedGender = ''; // Thêm biến cho giới tính
  List<String> _allergies = [];
  List<String> _chronicConditions = [];

  @override
  void initState() {
    super.initState();
    // Không cần gọi _initControllers() vì controllers đã được khởi tạo
    _loadPatientData();
  }

  // Thêm didChangeDependencies override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tải lại dữ liệu khi màn hình được hiển thị lại
    _loadPatientData();
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
    _dateOfBirthController.dispose(); // Giải phóng controller
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

      debugPrint('Loading data for userId: $userId');

      try {
        // Sử dụng cách tiếp cận khác để truy vấn
        final List<dynamic> response = await supabase
            .from('patients')
            .select()
            .eq('id', userId);

        debugPrint('Supabase response: $response');

        if (response.isNotEmpty) {
          final data = response[0];
          debugPrint('Patient data found: $data');

          // Log chi tiết từng trường
          debugPrint(
            'full_name: ${data['full_name']} (${data['full_name']?.runtimeType})',
          );
          debugPrint('email: ${data['email']} (${data['email']?.runtimeType})');
          debugPrint(
            'height: ${data['height']} (${data['height']?.runtimeType})',
          );
          debugPrint(
            'weight: ${data['weight']} (${data['weight']?.runtimeType})',
          );
          debugPrint(
            'allergies: ${data['allergies']} (${data['allergies']?.runtimeType})',
          );
          debugPrint(
            'chronic_conditions: ${data['chronic_conditions']} (${data['chronic_conditions']?.runtimeType})',
          );
          debugPrint(
            'date_of_birth: ${data['date_of_birth']} (${data['date_of_birth']?.runtimeType})',
          );
          debugPrint(
            'gender: ${data['gender']} (${data['gender']?.runtimeType})',
          );

          setState(() {
            _patient = Patient.fromJson(data);

            // Cập nhật tất cả controller với dữ liệu mới
            _fullNameController.text = _patient?.fullName ?? '';
            _emailController.text = _patient?.email ?? '';
            _phoneController.text = _patient?.phoneNumber ?? '';
            _addressController.text = _patient?.address ?? '';
            _emergencyContactController.text = _patient?.emergencyContact ?? '';

            if (_patient?.height != null) {
              _heightController.text = _patient!.height!.toString();
            }

            if (_patient?.weight != null) {
              _weightController.text = _patient!.weight!.toString();
            }

            // Cập nhật giá trị ngày sinh và giới tính
            _dateOfBirthController.text = _patient?.formattedDateOfBirth ?? '';
            _selectedGender = _patient?.gender ?? '';

            _allergies = _patient?.allergies?.toList() ?? [];
            _chronicConditions = _patient?.chronicConditions?.toList() ?? [];

            debugPrint('Controllers đã được cập nhật với giá trị mới');
          });
        } else {
          debugPrint('Không tìm thấy dữ liệu cho userId: $userId');
        }
      } catch (e) {
        debugPrint('Lỗi khi truy vấn dữ liệu bệnh nhân: $e');
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu bệnh nhân: $e');
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
      double? heightDouble;
      double? weightDouble;
      int? heightInt;
      int? weightInt;

      try {
        if (_heightController.text.trim().isNotEmpty) {
          heightDouble = double.parse(_heightController.text.trim());
          heightInt = heightDouble.round();
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
          weightDouble = double.parse(_weightController.text.trim());
          weightInt = weightDouble.round();
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

      // Debug the data before sending
      debugPrint('About to update patient data: ${_patient!.id}');
      debugPrint('Height going to DB (as int): $heightInt');
      debugPrint('Weight going to DB (as int): $weightInt');

      // Cập nhật chiều cao và cân nặng dưới dạng số nguyên (int)
      if (heightInt != null) {
        updateData['height'] = heightInt;
      }

      if (weightInt != null) {
        updateData['weight'] = weightInt;
      }

      // Xử lý các mảng
      if (_allergies.isNotEmpty) {
        updateData['allergies'] = _allergies;
      } else {
        updateData['allergies'] = []; // Đảm bảo gửi mảng rỗng thay vì null
      }

      if (_chronicConditions.isNotEmpty) {
        updateData['chronic_conditions'] = _chronicConditions;
      } else {
        updateData['chronic_conditions'] =
            []; // Đảm bảo gửi mảng rỗng thay vì null
      }

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

      // Cập nhật giới tính nếu đã chọn
      if (_selectedGender.isNotEmpty) {
        updateData['gender'] = _selectedGender.toLowerCase();
      }

      // Cập nhật ngày sinh nếu có
      final dateOfBirth = _dateOfBirthController.text.trim();
      if (dateOfBirth.isNotEmpty) {
        try {
          // Định dạng ngày: dd/MM/yyyy -> yyyy-MM-dd (định dạng ISO cho database)
          final parts = dateOfBirth.split('/');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = parts[1].padLeft(2, '0');
            final year = parts[2];
            updateData['date_of_birth'] = '$year-$month-$day';
          }
        } catch (e) {
          debugPrint('Lỗi khi chuyển đổi định dạng ngày sinh: $e');
        }
      }

      // Debug: Ghi log dữ liệu sẽ cập nhật
      debugPrint('Cập nhật dữ liệu: $updateData');

      // Gọi API để cập nhật với xử lý lỗi chi tiết hơn
      try {
        final response =
            await supabase
                .from('patients')
                .update(updateData)
                .eq('id', _patient!.id)
                .select(); // Thêm .select() để nhận phản hồi

        debugPrint('Cập nhật thành công, phản hồi: $response');

        // Tải lại dữ liệu từ server để đảm bảo đồng bộ
        await _loadPatientData();

        // Tắt chế độ chỉnh sửa
        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công')),
          );
        }
      } catch (supabaseError) {
        // Xử lý lỗi cụ thể từ Supabase
        debugPrint('Lỗi Supabase khi cập nhật: $supabaseError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $supabaseError')),
          );
        }
        rethrow; // Ném lại lỗi để outer catch xử lý
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

  Future<void> _debugRawData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('DEBUG: userId is null');
        return;
      }

      debugPrint('DEBUG: Fetching data for userId: $userId');

      // Truy vấn trực tiếp không qua .maybeSingle()
      final response = await supabase
          .from('patients')
          .select()
          .eq('id', userId);

      debugPrint('DEBUG: Raw response from Supabase: $response');

      if (response.isNotEmpty) {
        debugPrint('DEBUG: First row data: ${response[0]}');

        // Hiển thị dialog với dữ liệu raw
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Raw Database Data'),
                  content: SingleChildScrollView(
                    child: Text(response[0].toString()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
          );
        }
      } else {
        debugPrint('DEBUG: No data found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy dữ liệu từ database')),
          );
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching raw data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log thông tin hiện tại của patient và controller
    debugPrint('Current patient data: ${_patient?.toJson()}');
    debugPrint(
      'Current controller values: Name=${_fullNameController.text}, Height=${_heightController.text}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          // Thêm nút debug
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugRawData,
            tooltip: 'Debug Database',
          ),
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
                    const SizedBox(height: 8),

                    // Thêm trường ngày sinh với date picker
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 25),
                          ), // Mặc định 25 tuổi
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            // Format ngày theo định dạng dd/MM/yyyy
                            _dateOfBirthController.text =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateOfBirthController,
                          decoration: const InputDecoration(
                            labelText: 'Ngày sinh',
                            prefixIcon: Icon(Icons.calendar_today),
                            hintText: 'DD/MM/YYYY',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thêm dropdown để chọn giới tính
                    DropdownButtonFormField<String>(
                      value:
                          _selectedGender.isNotEmpty ? _selectedGender : null,
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Nam')),
                        DropdownMenuItem(value: 'female', child: Text('Nữ')),
                        DropdownMenuItem(value: 'other', child: Text('Khác')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGender = value;
                          });
                        }
                      },
                    ),
                  ],
                )
                : Column(
                  children: [
                    _buildInfoRow('Email', _patient?.email),
                    _buildInfoRow('Số điện thoại', _patient?.phoneNumber),
                    _buildInfoRow('Địa chỉ', _patient?.address),
                    _buildInfoRow('Ngày sinh', _patient?.formattedDateOfBirth),
                    _buildInfoRow(
                      'Giới tính',
                      _mapGenderToVietnamese(_patient?.gender),
                    ),
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

  String _mapGenderToVietnamese(String? gender) {
    if (gender == null) return 'Chưa cập nhật';

    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return gender;
    }
  }
}
