// lib/screens/medicine/medicine_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/medicine.dart';
import '../../services/supabase_service.dart';

class MedicineFormScreen extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService().medicineService;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _mfgDateController;
  late final TextEditingController _expDateController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedMfgDate;
  DateTime? _selectedExpDate;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _populateFormIfEditing();
  }

  void _initializeControllers() {
    _nameController = TextEditingController()..addListener(_onFormChanged);
    _unitController = TextEditingController()..addListener(_onFormChanged);
    _priceController = TextEditingController()..addListener(_onFormChanged);
    _mfgDateController = TextEditingController();
    _expDateController = TextEditingController();
    _descriptionController = TextEditingController()
      ..addListener(_onFormChanged);
  }

  void _populateFormIfEditing() {
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _unitController.text = widget.medicine!.unit;
      _priceController.text = _currencyFormat.format(widget.medicine!.price);
      _selectedMfgDate = widget.medicine!.manufacturingDate;
      _selectedExpDate = widget.medicine!.expiryDate;
      _mfgDateController.text =
          DateFormat('dd/MM/yyyy').format(_selectedMfgDate!);
      _expDateController.text =
          DateFormat('dd/MM/yyyy').format(_selectedExpDate!);
    }
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thay đổi?'),
        content: const Text(
            'Bạn có các thay đổi chưa lưu. Bạn có chắc muốn hủy không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy thay đổi'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _selectDate(BuildContext context, bool isMfgDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMfgDate
          ? (_selectedMfgDate ?? DateTime.now())
          : (_selectedExpDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate:
          isMfgDate ? DateTime(2000) : (_selectedMfgDate ?? DateTime.now()),
      lastDate: isMfgDate ? DateTime.now() : DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isMfgDate) {
          _selectedMfgDate = picked;
          _mfgDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          // Reset expiry date if it's before manufacturing date
          if (_selectedExpDate != null && _selectedExpDate!.isBefore(picked)) {
            _selectedExpDate = null;
            _expDateController.clear();
          }
        } else {
          _selectedExpDate = picked;
          _expDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
        _hasChanges = true;
      });
    }
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập giá thuốc';
    }

    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    final price = double.tryParse(cleanValue);

    if (price == null) {
      return 'Giá không hợp lệ';
    }
    if (price <= 0) {
      return 'Giá phải lớn hơn 0';
    }
    if (price > 10000000) {
      return 'Giá không được vượt quá 10,000,000đ';
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMfgDate == null || _selectedExpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn đầy đủ ngày sản xuất và hạn sử dụng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final priceString =
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.parse(priceString);

      final medicine = widget.medicine != null
          ? Medicine(
              id: widget.medicine!.id,
              name: _nameController.text.trim(),
              unit: _unitController.text.trim(),
              price: price,
              manufacturingDate: _selectedMfgDate!,
              expiryDate: _selectedExpDate!,
              stock: widget.medicine!.stock,
            )
          : Medicine.create(
              name: _nameController.text.trim(),
              unit: _unitController.text.trim(),
              price: price,
              manufacturingDate: _selectedMfgDate!,
              expiryDate: _selectedExpDate!,
            );

      if (widget.medicine == null) {
        await _supabaseService.addMedicine(medicine);
      } else {
        await _supabaseService.updateMedicine(medicine);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medicine == null
                ? 'Đã thêm thuốc mới'
                : 'Đã cập nhật thuốc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.medicine == null ? 'Thêm thuốc mới' : 'Chỉnh sửa thuốc',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF8A80),
                  Color(0xFFE57373)
                ], // Light red gradient
              ),
            ),
          ),
          elevation: 0,
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _isLoading ? null : _handleSubmit,
                  tooltip: 'Lưu thay đổi',
                ),
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF8A80),
                Color(0xFFE57373)
              ], // Light red gradient
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFormField(
                              controller: _nameController,
                              label: 'Tên thuốc',
                              hint: 'Nhập tên thuốc',
                              icon: Icons.medication,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên thuốc';
                                }
                                if (value.trim().length < 3) {
                                  return 'Tên thuốc phải có ít nhất 3 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              controller: _unitController,
                              label: 'Đơn vị',
                              hint: 'VD: Viên, Hộp, Chai...',
                              icon: Icons.scale,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập đơn vị';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              controller: _priceController,
                              label: 'Giá (VNĐ)',
                              hint: 'Nhập giá thuốc',
                              icon: Icons.monetization_on,
                              keyboardType: TextInputType.number,
                              suffixText: 'VNĐ',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                  if (newValue.text.isEmpty) return newValue;
                                  final number = int.parse(newValue.text);
                                  final newString =
                                      _currencyFormat.format(number);
                                  return TextEditingValue(
                                    text: newString,
                                    selection: TextSelection.collapsed(
                                        offset: newString.length),
                                  );
                                }),
                              ],
                              validator: _validatePrice,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    controller: _mfgDateController,
                                    label: 'Ngày sản xuất',
                                    icon: Icons.calendar_today,
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    controller: _expDateController,
                                    label: 'Hạn sử dụng',
                                    icon: Icons.event_busy,
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor:
                                    const Color(0xFFEF5350), // Light red button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.medicine == null
                                        ? 'Thêm thuốc'
                                        : 'Cập nhật',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFEF5350), width: 2), // Light red border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFEF5350)),
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.red.shade700),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFEF5350)),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.red.shade700),
      ),
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng chọn $label';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _mfgDateController.dispose();
    _expDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
