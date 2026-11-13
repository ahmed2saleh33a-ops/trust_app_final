// lib/screens/admin/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/order.dart';
import '../../providers/data_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final orders = dataProvider.allOrders;
        final delivered = orders.where((o) => o.status == 'واصل').toList();
        final returned = orders.where((o) => o.status == 'راجع').toList();
        final totalSales = delivered.fold(0.0, (s, o) => s + o.total);
        final returnedValue = returned.fold(0.0, (s, o) => s + o.total);
        
        final topProducts = _getTopProducts(delivered);
        final agentPerformance = _getAgentPerformance(delivered);

        return RefreshIndicator(
          onRefresh: () => dataProvider.loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📊 ملخص المبيعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _ReportRow(label: 'إجمالي الطلبات', value: '${orders.length}'),
                        _ReportRow(label: '✅ الواصلة', value: '${delivered.length}', valueColor: Colors.green),
                        _ReportRow(label: '❌ المرتجعة', value: '${returned.length}', valueColor: Colors.red),
                        const Divider(),
                        _ReportRow(label: '💰 المبيعات', value: '${totalSales.toInt()} د.ع', valueColor: const Color(0xFF34D399)),
                        _ReportRow(label: '🔄 المرتجعات', value: '${returnedValue.toInt()} د.ع', valueColor: Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Top Products
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏆 المنتجات الأكثر مبيعا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (topProducts.isEmpty)
                          const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)))
                        else
                          ...topProducts.take(10).map((p) => _ReportRow(
                            label: p['name'],
                            value: '${p['qty']} × ${p['revenue'].toInt()} د.ع',
                            valueColor: const Color(0xFFF59E0B),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Agent Performance
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('👥 أداء المندوبين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (agentPerformance.isEmpty)
                          const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)))
                        else
                          ...agentPerformance.map((a) => _ReportRow(
                            label: a['name'],
                            value: '${a['sales'].toInt()} د.ع (${a['delivered']} طلب)',
                            valueColor: const Color(0xFF34D399),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportCSV(context, orders),
                    icon: const Icon(Icons.download),
                    label: const Text('تصدير البيانات CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTopProducts(List<Order> delivered) {
    final Map<String, Map<String, dynamic>> products = {};
    for (final order in delivered) {
      if (!products.containsKey(order.product)) {
        products[order.product] = {'name': order.product, 'qty': 0, 'revenue': 0.0};
      }
      products[order.product]!['qty'] += order.quantity;
      products[order.product]!['revenue'] += order.total;
    }
    final list = products.values.toList();
    list.sort((a, b) => b['revenue'].compareTo(a['revenue']));
    return list;
  }

  List<Map<String, dynamic>> _getAgentPerformance(List<Order> delivered) {
    final Map<String, Map<String, dynamic>> agents = {};
    for (final order in delivered) {
      if (!agents.containsKey(order.agentName)) {
        agents[order.agentName] = {'name': order.agentName, 'delivered': 0, 'sales': 0.0};
      }
      agents[order.agentName]!['delivered']++;
      agents[order.agentName]!['sales'] += order.total;
    }
    final list = agents.values.toList();
    list.sort((a, b) => b['sales'].compareTo(a['sales']));
    return list;
  }

  Future<void> _exportCSV(BuildContext context, List<Order> orders) async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للتصدير')),
      );
      return;
    }

    final headers = ['الزبون', 'الهاتف', 'العنوان', 'المنتج', 'الكمية', 'السعر', 'الإجمالي', 'المندوب', 'التاريخ', 'الحالة', 'الملاحظات'];
    final rows = orders.map((o) => [
      o.customerName,
      o.customerPhone,
      o.customerAddress,
      o.product,
      o.quantity.toString(),
      o.price.toString(),
      o.total.toString(),
      o.agentName,
      o.orderDate ?? '',
      o.status,
      o.adminNotes ?? '',
    ]).toList();
    
    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    final bytes = Uint8List.fromList(csv.codeUnits);
    
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: 'orders.csv')],
      text: 'مركز الثقة - تقرير الطلبات',
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReportRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

