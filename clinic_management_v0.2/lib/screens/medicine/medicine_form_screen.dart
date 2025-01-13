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
              widget.medicine == null ? 'Thêm thuốc mới' : 'Chỉnh sửa thuốc'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isLoading ? null : _handleSubmit,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên thuốc *',
                          hintText: 'Nhập tên thuốc',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medication),
                        ),
                        textCapitalization: TextCapitalization.words,
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị *',
                          hintText: 'VD: Viên, Hộp, Chai...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập đơn vị';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá (VNĐ) *',
                          hintText: 'Nhập giá thuốc',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on),
                          suffixText: 'VNĐ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
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
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mfgDateController,
                              decoration: const InputDecoration(
                                labelText: 'Ngày sản xuất *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context, true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Chọn ngày sản xuất';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _expDateController,
                              decoration: const InputDecoration(
                                labelText: 'Hạn sử dụng *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event_busy),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context, false),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Chọn hạn sử dụng';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        icon: const Icon(Icons.save),
                        label: Text(widget.medicine == null
                            ? 'Thêm thuốc'
                            : 'Cập nhật'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
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
