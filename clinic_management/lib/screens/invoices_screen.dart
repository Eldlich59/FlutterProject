import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    Future.microtask(() {
      if (mounted) {
        provider.loadInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddInvoiceDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showRevenueReport(context),
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.invoices.isEmpty) {
            return const Center(child: Text('Chưa có hóa đơn nào'));
          }

          return ListView.builder(
            itemCount: provider.invoices.length,
            itemBuilder: (context, index) {
              final invoice = provider.invoices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Hóa đơn #${invoice.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngày: ${_formatDate(invoice.date)}'),
                      Text('Tổng tiền: ${_formatCurrency(invoice.amount)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print),
                        onPressed: () => _printInvoice(invoice),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _showInvoiceDetails(context, invoice),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    // Implement invoice details dialog
  }

  void _showAddInvoiceDialog(BuildContext context) {
    // Implement add invoice dialog
  }

  void _printInvoice(Invoice invoice) {
    // Implement print functionality
  }

  void _showRevenueReport(BuildContext context) {
    // Implement revenue report dialog
  }
}
