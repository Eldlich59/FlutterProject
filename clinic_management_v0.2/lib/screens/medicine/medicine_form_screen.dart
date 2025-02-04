// lib/screens/medicine/medicine_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/inventory/medicine.dart';
import '../../services/supabase_service.dart';

// Change to Dialog instead of Screen
class MedicineFormDialog extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormDialog({super.key, this.medicine});

  @override
  State<MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<MedicineFormDialog> {
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
        Navigator.pop(context, true); // Return true to indicate success
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 800,
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                automaticallyImplyLeading:
                    false, // Add this line to remove back arrow
                title: Text(
                  widget.medicine == null
                      ? 'Thêm thuốc mới'
                      : 'Chỉnh sửa thuốc',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFEF5350),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ).animate().fadeIn().slideX(
                  begin: -0.2, duration: const Duration(milliseconds: 400)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        )
                            .animate(delay: const Duration(milliseconds: 100))
                            .fadeIn()
                            .slideY(begin: 0.2),
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
                        )
                            .animate(delay: const Duration(milliseconds: 200))
                            .fadeIn()
                            .slideY(begin: 0.2),
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
                              final newString = _currencyFormat.format(number);
                              return TextEditingValue(
                                text: newString,
                                selection: TextSelection.collapsed(
                                    offset: newString.length),
                              );
                            }),
                          ],
                          validator: _validatePrice,
                        )
                            .animate(delay: const Duration(milliseconds: 300))
                            .fadeIn()
                            .slideY(begin: 0.2),
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
                        )
                            .animate(delay: const Duration(milliseconds: 400))
                            .fadeIn()
                            .slideY(begin: 0.2),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
            ],
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
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
