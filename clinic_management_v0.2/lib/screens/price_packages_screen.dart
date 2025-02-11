import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/specialty.dart';
import '../models/price_package.dart';
import '../services/specialty_service.dart';
import '../services/price_package_service.dart';

class PricePackagesScreen extends StatefulWidget {
  const PricePackagesScreen({super.key});

  @override
  State<PricePackagesScreen> createState() => _PricePackagesScreenState();
}

class _PricePackagesScreenState extends State<PricePackagesScreen>
    with SingleTickerProviderStateMixin {
  final SpecialtyService _specialtyService =
      SpecialtyService(Supabase.instance.client);
  final PricePackageService _packageService =
      PricePackageService(Supabase.instance.client);

  List<Specialty> specialties = [];
  List<PricePackage> packages = [];
  String? selectedSpecialtyId;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<PricePackage> _filteredPackages = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchBarAnimation;
  late Animation<double> _dropdownAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Increased duration
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _searchBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _dropdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _refreshData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    try {
      final loadedSpecialties = await _specialtyService
          .getSpecialties(); // Changed from getAllSpecialties
      setState(() {
        specialties = loadedSpecialties;
      });
    } catch (e) {
      _showError('Error loading specialties: $e');
    }
  }

  Future<void> _loadPackages() async {
    try {
      final loadedPackages = selectedSpecialtyId != null
          ? await _packageService.getPackagesByChuyenKhoa(selectedSpecialtyId!)
          : await _packageService.getAllPackages();
      setState(() {
        packages = loadedPackages;
        _filterPackages(); // Update filtered list when loading new data
      });
    } catch (e) {
      _showError('Error loading packages: $e');
    }
  }

  void _filterPackages() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filteredPackages = packages.where((package) {
        return package.name.toLowerCase().contains(_searchText) ||
            package.description.toLowerCase().contains(_searchText) ||
            package.includedServices
                .any((service) => service.toLowerCase().contains(_searchText));
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.wait([
        _loadSpecialties(),
        _loadPackages(),
      ]);
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
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.pink.shade700,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bảng Giá Dịch Vụ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.pink.shade700,
                size: 24,
              ),
              tooltip: 'Làm mới',
              onPressed: _refreshData, // Simplified - removed the SnackBar
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: FadeTransition(
            opacity: _searchBarAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade100.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm gói dịch vụ...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.pink.shade300),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _fadeAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddPackageDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm Bảng Mới'),
            backgroundColor: Colors.pink.shade400,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.pink.shade400,
          child: Column(
            children: [
              // Specialty Dropdown
              FadeTransition(
                opacity: _dropdownAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(_animationController),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Chọn Chuyên Khoa',
                          labelStyle: TextStyle(
                            color: Colors.pink.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.pink.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.pink.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Colors.pink.shade400, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.local_hospital,
                              color: Colors.pink.shade400),
                        ),
                        value: selectedSpecialtyId,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tất cả chuyên khoa',
                                style: TextStyle(color: Colors.pink.shade700)),
                          ),
                          ...specialties.map((specialty) {
                            return DropdownMenuItem<String>(
                              value: specialty.id,
                              child: Text(specialty.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSpecialtyId = value;
                            _loadPackages();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Package List
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Stack(
                      children: [
                        _filteredPackages.isEmpty
                            ? _buildEmptyState()
                            : _buildPackageList(),
                        if (_isLoading) _buildLoadingOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchText.isEmpty
                    ? Icons.medical_services_outlined
                    : Icons.search_off_rounded,
                size: 80,
                color: Colors.pink.shade200,
              ),
              const SizedBox(height: 16),
              Text(
                _searchText.isEmpty
                    ? 'Chưa có gói dịch vụ nào'
                    : 'Không tìm thấy gói dịch vụ',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.pink.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchText.isEmpty
                    ? 'Hãy thêm gói dịch vụ mới'
                    : 'Thử tìm kiếm với từ khóa khác',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredPackages.length,
      itemBuilder: (context, index) {
        final package = _filteredPackages[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.1 * (index % 10), // Stagger items
                  0.6 + 0.1 * (index % 10),
                  curve: Curves.easeOut,
                ),
              ),
            );
            return FadeTransition(
              opacity: itemAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(itemAnimation),
                child: child!,
              ),
            );
          },
          child: Hero(
            tag: 'package-${package.id}',
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: package.isActive
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => _showPackageDetails(package),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        package.isActive
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                      ],
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      package.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.monetization_on,
                                color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${package.price.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Trạng thái:'),
                            Switch(
                              value: package.isActive,
                              onChanged: (bool value) =>
                                  _togglePackageStatus(package, value),
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green.shade100,
                            ),
                            Text(
                              package.isActive
                                  ? "Đang hoạt động"
                                  : "Ngưng hoạt động",
                              style: TextStyle(
                                color: package.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: ListTile(
                            leading: const Icon(Icons.info_outline, size: 20),
                            title: const Text('Chi tiết'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: const Icon(Icons.edit, size: 20),
                            title: const Text('Chỉnh sửa'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            title: const Text('Xóa',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditPackageDialog(package);
                            break;
                          case 'delete':
                            _confirmDelete(package);
                            break;
                          case 'details':
                            _showPackageDetails(package);
                            break;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity:
              Tween<double>(begin: 0.0, end: 0.7).animate(_animationController),
          child: Container(
            color: Colors.white.withOpacity(0.7),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddPackageDialog() async {
    if (specialties.isEmpty) {
      _showError('Vui lòng chờ danh sách chuyên khoa được tải');
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final servicesController = TextEditingController();
    String? dialogSpecialtyId = selectedSpecialtyId;
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: Colors.pink.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Thêm Gói Dịch Vụ Mới',
                          style: TextStyle(
                            color: Colors.pink.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Specialty Selection
                          Text(
                            'Chuyên Khoa',
                            style: TextStyle(
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.pink.shade100),
                              color: Colors.pink.shade50.withOpacity(0.5),
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              value: dialogSpecialtyId,
                              items: specialties.map((specialty) {
                                return DropdownMenuItem(
                                  value: specialty.id,
                                  child: Text(specialty.name),
                                );
                              }).toList(),
                              onChanged: (value) => dialogSpecialtyId = value,
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn chuyên khoa'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Move Date Selection here
                          Text(
                            'Thời Gian',
                            style: TextStyle(
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.pink.shade400, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ngày tạo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(selectedDate),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                                  onPressed: () => _selectDate(
                                    selectedDate,
                                    (date) =>
                                        setState(() => selectedDate = date),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Other form fields
                          _buildFormField(
                            controller: nameController,
                            label: 'Tên Gói Dịch Vụ',
                            icon: Icons.medical_services,
                            validator: (value) => value?.isEmpty == true
                                ? 'Vui lòng nhập tên gói'
                                : null,
                          ),
                          _buildFormField(
                            controller: priceController,
                            label: 'Giá (VNĐ)',
                            icon: Icons.monetization_on,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) {
                                return 'Vui lòng nhập giá';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          _buildFormField(
                            controller: descriptionController,
                            label: 'Mô tả chi tiết',
                            icon: Icons.description,
                            maxLines: 2,
                            helperText: 'Mô tả ngắn gọn về gói dịch vụ',
                            keyboardType: TextInputType.text,
                            validator: (value) => value?.isEmpty == true
                                ? 'Vui lòng nhập mô tả'
                                : null,
                          ),
                          _buildFormField(
                            controller: servicesController,
                            label: 'Dịch vụ bao gồm',
                            icon: Icons.list,
                            maxLines: 2,
                            helperText: 'Phân cách các dịch vụ bằng dấu phẩy',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;
                          try {
                            final newPackage = PricePackage(
                              id: '', // Will be generated by Supabase
                              name: nameController.text,
                              chuyenKhoaId: dialogSpecialtyId!,
                              price: double.parse(priceController.text),
                              description: descriptionController.text,
                              includedServices: servicesController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              isActive: true,
                              createdAt: selectedDate,
                              updatedAt: DateTime.now(),
                            );
                            await _packageService.createPackage(newPackage);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadPackages();
                          } catch (e) {
                            _showError('Lỗi khi thêm gói dịch vụ mới: $e');
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text('Lưu'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditPackageDialog(PricePackage package) async {
    final nameController = TextEditingController(text: package.name);
    final priceController =
        TextEditingController(text: package.price.toString());
    final descriptionController =
        TextEditingController(text: package.description);
    final servicesController =
        TextEditingController(text: package.includedServices.join(', '));
    String? dialogSpecialtyId = package.chuyenKhoaId;
    DateTime selectedDate = package.createdAt;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, color: Colors.pink.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Chỉnh Sửa Gói Dịch Vụ',
                          style: TextStyle(
                            color: Colors.pink.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Specialty Selection
                          Text(
                            'Chuyên Khoa',
                            style: TextStyle(
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.pink.shade100),
                              color: Colors.pink.shade50.withOpacity(0.5),
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              value: dialogSpecialtyId,
                              items: specialties.map((specialty) {
                                return DropdownMenuItem(
                                  value: specialty.id,
                                  child: Text(specialty.name),
                                );
                              }).toList(),
                              onChanged: (value) => dialogSpecialtyId = value,
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn chuyên khoa'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Move Date Selection here
                          Text(
                            'Thời Gian',
                            style: TextStyle(
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.pink.shade400, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ngày tạo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(selectedDate),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                                  onPressed: () => _selectDate(
                                    selectedDate,
                                    (date) =>
                                        setState(() => selectedDate = date),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Other form fields with enhanced styling
                          _buildFormField(
                            controller: nameController,
                            label: 'Tên Gói Dịch Vụ',
                            icon: Icons.medical_services,
                            validator: (value) => value?.isEmpty == true
                                ? 'Vui lòng nhập tên gói'
                                : null,
                          ),
                          _buildFormField(
                            controller: priceController,
                            label: 'Giá (VNĐ)',
                            icon: Icons.monetization_on,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) {
                                return 'Vui lòng nhập giá';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          _buildFormField(
                            controller: descriptionController,
                            label: 'Mô tả chi tiết',
                            icon: Icons.description,
                            maxLines: 2, // Changed from 3 to 2
                            helperText: 'Mô tả ngắn gọn về gói dịch vụ',
                            keyboardType: TextInputType.text,
                            validator: (value) => value?.isEmpty == true
                                ? 'Vui lòng nhập mô tả'
                                : null,
                          ),
                          _buildFormField(
                            controller: servicesController,
                            label: 'Dịch vụ bao gồm',
                            icon: Icons.list,
                            maxLines: 2,
                            helperText: 'Phân cách các dịch vụ bằng dấu phẩy',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;
                          try {
                            final updatedPackage = PricePackage(
                              id: package.id,
                              name: nameController.text,
                              chuyenKhoaId: dialogSpecialtyId!,
                              price: double.parse(priceController.text),
                              description: descriptionController.text,
                              includedServices: servicesController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              isActive: package.isActive,
                              createdAt: selectedDate,
                              updatedAt: DateTime.now(),
                            );
                            await _packageService.updatePackage(updatedPackage);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadPackages();
                          } catch (e) {
                            _showError('Lỗi khi cập nhật gói dịch vụ: $e');
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text('Cập nhật'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.pink.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.pink.shade400, size: 20),
              helperText: helperText,
              helperStyle: TextStyle(color: Colors.grey.shade600),
              errorStyle: const TextStyle(color: Colors.red),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.pink.shade50.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink.shade100),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink.shade400),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(PricePackage package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa vĩnh viễn gói dịch vụ này?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _packageService.deletePackage(package.id);
        _loadPackages();
      } catch (e) {
        _showError('Lỗi khi xóa gói dịch vụ: $e');
      }
    }
  }

  void _showPackageDetails(PricePackage package) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services, color: Colors.pink.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Chi Tiết Gói Dịch Vụ',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package Name
                      Text(
                        'Tên Gói',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink.shade100),
                        ),
                        child: Text(
                          package.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Move Timestamps here
                      Text(
                        'Thông Tin Thời Gian',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildTimeInfoRow(
                              Icons.calendar_today,
                              'Ngày tạo:',
                              _formatDate(package.createdAt),
                            ),
                            if (package.updatedAt != null) ...[
                              const Divider(height: 16),
                              _buildTimeInfoRow(
                                Icons.update,
                                'Cập nhật lần cuối:',
                                _formatDate(package.updatedAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Text(
                        'Giá Dịch Vụ',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.monetization_on,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '${package.price.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Mô Tả Chi Tiết',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          package.description,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Included Services
                      Text(
                        'Dịch Vụ Bao Gồm',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: package.includedServices
                              .map((service) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 16,
                                            color: Colors.blue.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            service,
                                            style: TextStyle(
                                                color: Colors.blue.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Text(
                        'Trạng Thái',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: package.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: package.isActive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              package.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  package.isActive ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              package.isActive
                                  ? 'Đang hoạt động'
                                  : 'Ngưng hoạt động',
                              style: TextStyle(
                                color: package.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add new method for toggling status
  Future<void> _togglePackageStatus(
      PricePackage package, bool newStatus) async {
    try {
      await _packageService.togglePackageStatus(package.id, newStatus);
      _loadPackages(); // Reload to update UI
    } catch (e) {
      _showError('Lỗi khi thay đổi trạng thái: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(
      DateTime initialDate, Function(DateTime) onSelect) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      // Preserve the original time when updating the date
      final newDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        initialDate.hour,
        initialDate.minute,
      );
      onSelect(newDate);
    }
  }

  Widget _buildTimeInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
