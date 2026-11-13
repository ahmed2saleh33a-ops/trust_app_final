// lib/screens/admin/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/data_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/toast_message.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final products = _getInventory(dataProvider.allOrders);
        
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => dataProvider.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory, size: 28, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 8),
                              const Text('إدارة المخزن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // ✅ إضافة SizedBox محددة العرض للزر
                          SizedBox(
                            width: 120,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () => _clearAllInventory(context, dataProvider),
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('مسح الكل', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يتم تتبع المنتجات تلقائيا من خلال الطلبات المسجلة',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Inventory List
                  if (products.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('📦 لا توجد منتجات في المخزن', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _InventoryItem(
                          product: product,
                          onDelete: () => _clearProduct(context, dataProvider, product['name']),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getInventory(List<Order> orders) {
    final Map<String, Map<String, dynamic>> products = {};
    for (final order in orders) {
      final productKey = order.product;
      if (!products.containsKey(productKey)) {
        products[productKey] = {
          'name': order.product,
          'sold': 0,
          'returned': 0,
        };
      }
      if (order.status == 'واصل') {
        products[productKey]!['sold'] = (products[productKey]!['sold'] as int) + (order.quantity);
      } else if (order.status == 'راجع') {
        products[productKey]!['returned'] = (products[productKey]!['returned'] as int) + (order.quantity);
      }
    }
    return products.values.toList();
  }

  Future<void> _clearProduct(BuildContext context, DataProvider dataProvider, String productName) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'مسح المنتج',
      message: 'هل أنت متأكد من حذف جميع طلبات المنتج "$productName" من المخزن؟',
      confirmText: 'مسح',
    );
    
    if (confirmed) {
      final ordersToDelete = dataProvider.allOrders.where((o) => o.product == productName).toList();
      int deletedCount = 0;
      for (final order in ordersToDelete) {
        if (order.backendId != null && await dataProvider.deleteOrder(order.backendId!)) {
          deletedCount++;
        }
      }
      ToastMessage.show(context, '✅ تم حذف $deletedCount طلب للمنتج $productName');
    }
  }

  Future<void> _clearAllInventory(BuildContext context, DataProvider dataProvider) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '⚠️ تحذير',
      message: 'هذا الإجراء سيقوم بحذف جميع الطلبات والمنتجات من المخزن!\nهل أنت متأكد؟',
      confirmText: 'نعم احذف الكل',
      confirmColor: Colors.red,
    );
    
    if (confirmed) {
      int deletedCount = 0;
      for (final order in dataProvider.allOrders) {
        if (order.backendId != null && await dataProvider.deleteOrder(order.backendId!)) {
          deletedCount++;
        }
      }
      ToastMessage.show(context, '✅ تم حذف $deletedCount طلب والمخزن الآن فارغ');
    }
  }
}

class _InventoryItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDelete;

  const _InventoryItem({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sold = product['sold'] as int;
    final returned = product['returned'] as int;
    final total = sold + returned;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Text('مباع: $sold', style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('مرتجع: $returned', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                      Text('الإجمالي: $total', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'مسح المنتج',
            ),
          ],
        ),
      ),
    );
  }
}