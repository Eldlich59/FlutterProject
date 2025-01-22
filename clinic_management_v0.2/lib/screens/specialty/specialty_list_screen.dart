import 'package:flutter/material.dart';
import 'package:clinic_management/models/specialty.dart';
import 'package:clinic_management/services/supabase_service.dart';

class SpecialtyListScreen extends StatefulWidget {
  const SpecialtyListScreen({super.key});

  @override
  State<SpecialtyListScreen> createState() => _SpecialtyListScreenState();
}

class _SpecialtyListScreenState extends State<SpecialtyListScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  List<Specialty> specialties = [];
  bool isLoading = true;

  // Enhanced color scheme
  static const primaryColor = Color(0xFFFF5722);
  static const secondaryColor = Color(0xFFFF8A65);
  static const backgroundColor = Color(0xFFFBE9E7);
  static const gradientStart = Color(0xFFFF7043);
  static const gradientEnd = Color(0xFFFF5722);

  late AnimationController _animationController;
  Animation<double>? _fabAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Increased duration
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadSpecialties();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    try {
      final loadedSpecialties =
          await _supabaseService.specialtyService.getSpecialties();
      setState(() {
        specialties = loadedSpecialties;
        isLoading = false;
      });
      // Add this line to start the animation after loading
      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading specialties: $e')),
      );
    }
  }

  // Reset animation when rebuilding the list
  void _resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chuyên Khoa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 20,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gradientEnd, backgroundColor],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: specialties.length,
                    itemBuilder: (context, index) {
                      final specialty = specialties[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index / specialties.length,
                              (index + 1) / specialties.length,
                              curve: Curves.easeOut,
                            ),
                          )),
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    specialty.isActive
                                        ? primaryColor.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        specialty.isActive
                                            ? primaryColor
                                            : Colors.red,
                                        specialty.isActive
                                            ? secondaryColor
                                            : Colors.red[300]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    specialty.isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(specialty.name)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: specialty.isActive
                                            ? primaryColor.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        specialty.isActive
                                            ? 'Đang hoạt động'
                                            : 'Ngừng hoạt động',
                                        style: TextStyle(
                                          color: specialty.isActive
                                              ? primaryColor
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  specialty.isSelfRegistration
                                      ? 'Tự đăng kí'
                                      : 'Hợp đồng hỗ trợ chuyên môn',
                                  style: TextStyle(
                                    color: primaryColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(
                                          specialty.isActive
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: specialty.isActive
                                              ? primaryColor
                                              : Colors.grey,
                                        ),
                                        title: Text(
                                          specialty.isActive
                                              ? 'Đang hoạt động'
                                              : 'Ngừng hoạt động',
                                          style: TextStyle(
                                            color: specialty.isActive
                                                ? primaryColor
                                                : Colors.grey,
                                          ),
                                        ),
                                        dense: true,
                                        onTap: () async {
                                          Navigator.pop(context);
                                          try {
                                            await _supabaseService
                                                .specialtyService
                                                .updateSpecialty(
                                              id: specialty.id,
                                              name: specialty.name,
                                              isActive: !specialty.isActive,
                                              isSelfRegistration:
                                                  specialty.isSelfRegistration,
                                            );
                                            _loadSpecialties();
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content:
                                                        Text(e.toString())),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('Sửa'),
                                        dense: true,
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showSpecialtyDialog(
                                              context, specialty);
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: const Icon(Icons.delete,
                                            color: Colors.red),
                                        title: const Text('Xóa',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        dense: true,
                                        onTap: () {
                                          Navigator.pop(context);
                                          _deleteSpecialty(specialty);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _showSpecialtyDialog(context, specialty),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: FadeTransition(
          opacity: _fabAnimation ?? const AlwaysStoppedAnimation(1.0),
          child: FloatingActionButton.extended(
            onPressed: () => _showSpecialtyDialog(context),
            backgroundColor: primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Thêm chuyên khoa',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSpecialtyDialog(BuildContext context,
      [Specialty? specialty]) async {
    final nameController = TextEditingController(text: specialty?.name);
    bool isActive = specialty?.isActive ?? true;
    bool isSelfRegistration = specialty?.isSelfRegistration ?? true;

    await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, backgroundColor],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      specialty == null
                          ? 'Thêm Chuyên Khoa'
                          : 'Cập Nhật Chuyên Khoa',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên chuyên khoa',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        labelStyle: TextStyle(color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      value: isSelfRegistration,
                      decoration: const InputDecoration(
                        labelText: 'Hình thức cấp phép',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Tự đăng kí'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Hợp đồng hỗ trợ chuyên môn'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => isSelfRegistration = value!),
                    ),
                    const SizedBox(height: 16),
                    if (specialty == null) // Only show for new specialties
                      SwitchListTile(
                        title: const Text('Trạng thái hoạt động'),
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final name = nameController.text.trim();

                              if (name.isEmpty) {
                                throw 'Tên chuyên khoa không được để trống';
                              }

                              if (specialty == null) {
                                await _supabaseService.specialtyService
                                    .addSpecialty(
                                  name: name,
                                  isActive: isActive,
                                  isSelfRegistration: isSelfRegistration,
                                );
                              } else {
                                await _supabaseService.specialtyService
                                    .updateSpecialty(
                                  id: specialty.id,
                                  name: name,
                                  isActive: specialty
                                      .isActive, // Keep existing isActive value
                                  isSelfRegistration: isSelfRegistration,
                                );
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                _loadSpecialties();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            specialty == null ? 'Thêm' : 'Cập nhật',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }

  Future<void> _deleteSpecialty(Specialty specialty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa chuyên khoa "${specialty.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.specialtyService.deleteSpecialty(specialty.id);
        _loadSpecialties();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa chuyên khoa: $e')),
          );
        }
      }
    }
  }
}
