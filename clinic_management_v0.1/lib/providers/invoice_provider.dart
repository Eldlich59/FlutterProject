import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../repositories/invoice_repository.dart';
import '../models/invoice.dart';

class InvoiceProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final InvoiceRepository repository;
  List<Invoice> _invoices;
  bool _isLoading = false;
  String? _error;
  double _dailyRevenue = 0;

  InvoiceProvider({required this.repository}) : _invoices = [];

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get dailyRevenue => _dailyRevenue;

  Future<void> loadInvoices() async {
    _invoices = [];
    notifyListeners();
    _error = null;
    notifyListeners();

    try {
      _invoices = await repository.getAllInvoices();
    } catch (e) {
      _error = 'Unable to load invoice list: $e';
      _logger.e('Error loading invoices: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addInvoice(Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.insertInvoice(invoice);
      await loadInvoices();
    } catch (e) {
      _error = 'Unable to add invoice: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDailyRevenue(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyRevenue = await repository.getDailyRevenue(date);
    } catch (e) {
      _error = 'Unable to load daily revenue: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
