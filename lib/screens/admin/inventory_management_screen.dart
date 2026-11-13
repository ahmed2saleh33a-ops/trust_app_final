// lib/screens/admin/inventory_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/data_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/toast_message.dart';
import '../../themes/app_theme.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final products = dataProvider.allProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 إدارة المخزن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(context, dataProvider),
            tooltip: 'إضافة منتج',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dataProvider.loadData(),
        child: products.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('📦 لا توجد منتجات في المخزن', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('اضغط على زر + لإضافة منتج جديد', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductCard(
                    product: product,
                    onEdit: () => _showProductDialog(context, dataProvider, product: product),
                    onDelete: () => _deleteProduct(context, dataProvider, product),
                    onAddStock: () => _adjustStock(context, dataProvider, product, true),
                    onRemoveStock: () => _adjustStock(context, dataProvider, product, false),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showProductDialog(BuildContext context, DataProvider dataProvider, {Product? product}) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '0');
    final categoryController = TextEditingController(text: product?.category ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          isEditing ? '✏️ تعديل منتج' : '➕ إضافة منتج',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '📦 اسم المنتج',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '📝 وصف المنتج (اختياري)',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '📊 الكمية المتوفرة',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '🏷️ التصنيف (اختياري)',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      bool success;
      if (isEditing && product != null) {
        final updatedProduct = product.copyWith(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          quantity: int.tryParse(quantityController.text) ?? 0,
          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
          updatedAt: DateTime.now(),
        );
        success = await dataProvider.updateProduct(updatedProduct);
      } else {
        final newProduct = Product(
          backendId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          quantity: int.tryParse(quantityController.text) ?? 0,
          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
          createdAt: DateTime.now(),
        );
        success = await dataProvider.createProduct(newProduct);
      }
      ToastMessage.show(
        context,
        success ? (isEditing ? '✅ تم تحديث المنتج' : '✅ تم إضافة المنتج') : '❌ حدث خطأ',
        isError: !success,
      );
    }
  }

  Future<void> _deleteProduct(BuildContext context, DataProvider dataProvider, Product product) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المنتج',
      message: 'هل أنت متأكد من حذف المنتج "${product.name}"؟',
    );
    if (confirmed) {
      if (await dataProvider.deleteProduct(product.backendId!)) {
        ToastMessage.show(context, '✅ تم حذف المنتج');
      }
    }
  }

  Future<void> _adjustStock(BuildContext context, DataProvider dataProvider, Product product, bool isAdding) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          isAdding ? '➕ إضافة كمية للمخزن' : '➖ خصم كمية من المخزن',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المنتج: ${product.name}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'الكمية الحالية: ${product.quantity}',
              style: const TextStyle(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: isAdding ? 'الكمية المراد إضافتها' : 'الكمية المراد خصمها',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context, amount);
              } else {
                ToastMessage.show(context, '⚠️ الرجاء إدخال كمية صحيحة', isError: true);
              }
            },
            child: Text(isAdding ? 'إضافة' : 'خصم'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      int newQuantity;
      if (isAdding) {
        newQuantity = product.quantity + result;
      } else {
        if (product.quantity < result) {
          ToastMessage.show(context, '⚠️ الكمية المطلوبة أكبر من المتوفرة', isError: true);
          return;
        }
        newQuantity = product.quantity - result;
      }
      
      final updatedProduct = product.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );
      
      if (await dataProvider.updateProduct(updatedProduct)) {
        ToastMessage.show(context, isAdding 
          ? '✅ تم إضافة $result قطعة إلى المخزن' 
          : '✅ تم خصم $result قطعة من المخزن');
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddStock;
  final VoidCallback onRemoveStock;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onAddStock,
    required this.onRemoveStock,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= 5 && product.quantity > 0;
    final isOutOfStock = product.quantity == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (product.category != null)
                        Text(
                          product.category!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_box, color: Colors.green, size: 20),
                      onPressed: onAddStock,
                      tooltip: 'إضافة كمية',
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.orange, size: 20),
                      onPressed: onRemoveStock,
                      tooltip: 'خصم كمية',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: onEdit,
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutOfStock 
                        ? Colors.red.withOpacity(0.2)
                        : isLowStock
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutOfStock ? Icons.cancel : Icons.inventory,
                        size: 14,
                        color: isOutOfStock ? Colors.red : isLowStock ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock ? 'غير متوفر' : 'المتبقي: ${product.quantity}',
                        style: TextStyle(
                          color: isOutOfStock ? Colors.red : isLowStock ? Colors.orange : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  product.description!,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}