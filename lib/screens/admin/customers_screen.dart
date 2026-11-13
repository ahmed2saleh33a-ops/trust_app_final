// lib/screens/admin/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/data_provider.dart';
import '../../widgets/toast_message.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final customers = _getCustomers(dataProvider.allOrders);
        
        return RefreshIndicator(
          onRefresh: () => dataProvider.loadData(),
          child: customers.isEmpty
              ? const Center(child: Text('👥 لا يوجد عملاء', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerCard(customer: customer);
                  },
                ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getCustomers(List<Order> orders) {
    final Map<String, Map<String, dynamic>> customers = {};
    for (final order in orders) {
      final phone = order.customerPhone;
      if (!customers.containsKey(phone)) {
        customers[phone] = {
          'name': order.customerName,
          'phone': order.customerPhone,
          'address': order.customerAddress,
          'orders': 0,
          'total': 0.0,
        };
      }
      customers[phone]!['orders']++;
      if (order.status == 'واصل') {
        customers[phone]!['total'] += order.total;
      }
    }
    return customers.values.toList();
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, customer['phone']),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(customer['phone'], style: const TextStyle(color: Color(0xFF34D399))),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                      if (customer['address'] != null && customer['address'].toString().isNotEmpty)
                        GestureDetector(
                          onTap: () => _copyToClipboard(context, customer['address']),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer['address'].length > 40
                                      ? '${customer['address'].substring(0, 40)}...'
                                      : customer['address'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                              const Icon(Icons.copy, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${customer['orders']} طلب', style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${customer['total'].toInt()} د.ع',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastMessage.show(context, '✅ تم نسخ: $text');
  }
}
