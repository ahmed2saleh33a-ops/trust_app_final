// lib/widgets/add_order_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import 'toast_message.dart';

// ✅ قائمة المحافظات الكاملة
const List<String> governorates = [
  'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كركوك',
  'الأنبار', 'كربلاء', 'ذي قار', 'ميسان', 'بابل', 'واسط',
  'صلاح الدين', 'ديالى', 'المثنى', 'القادسية',
  'السليمانية', 'دهوك'
];

// ✅ دالة تحويل الأرقام العربية/الفارسية إلى إنجليزية
String convertToEnglishNumbers(String input) {
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  const englishDigits = '0123456789';
  
  String result = input;
  
  // تحويل الأرقام العربية
  for (int i = 0; i < arabicDigits.length; i++) {
    result = result.replaceAll(arabicDigits[i], englishDigits[i]);
  }
  
  // تحويل الأرقام الفارسية
  for (int i = 0; i < persianDigits.length; i++) {
    result = result.replaceAll(persianDigits[i], englishDigits[i]);
  }
  
  return result;
}

class AddOrderDialog extends StatefulWidget {
  const AddOrderDialog({super.key});

  @override
  State<AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends State<AddOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _noteController = TextEditingController();
  
  // ✅ متغيرات للمنتج من المخزن
  Product? _selectedProduct;
  int _quantity = 1;
  double _unitPrice = 0;  // ✅ سعر القطعة الذي يدخله المندوب
  
  // ✅ Controller لحقل السعر
  late final TextEditingController _priceController;
  
  String _selectedGovernorate = '';
  String _selectedDate = '';
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().split('T')[0];
    _selectedGovernorate = governorates.first;
    _quantity = 1;
    _priceController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final products = dataProvider.allProducts.where((p) => p.quantity > 0).toList();

    // ✅ التحقق من وجود منتجات في المخزن
    if (products.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '⚠️ لا توجد منتجات في المخزن',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'الرجاء إضافة منتجات أولاً من لوحة المدير',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('➕ طلب جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, '👤 اسم الزبون', Icons.person, true),
                      const SizedBox(height: 12),
                      _buildTextField(
  _phoneController, 
  '📞 رقم الهاتف', 
  Icons.phone, 
  true,
  keyboardType: TextInputType.phone,
  onChanged: (value) {
    final converted = convertToEnglishNumbers(value);
    if (converted != value) {
      final cursorPos = _phoneController.selection.baseOffset;
      _phoneController.text = converted;
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPos),
      );
    }
  },
),
                      const SizedBox(height: 12),
                      _buildGovernorateDropdown(),
                      const SizedBox(height: 12),
                      _buildTextField(_districtController, '🏘️ المنطقة/الحي', Icons.location_city, true),
                      const SizedBox(height: 12),
                      _buildTextField(_landmarkController, '📍 أقرب نقطة دالة', Icons.place, false),
                      const SizedBox(height: 12),
                      
                      // ✅ اختيار المنتج من المخزن
                      _buildProductSelector(products),
                      const SizedBox(height: 12),
                      
                      // ✅ حقل السعر يدوي (مع ثبات التركيز)
                      _buildPriceField(),
                      const SizedBox(height: 12),
                      
                      // ✅ تحديد الكمية
                      _buildQuantitySelector(),
                      const SizedBox(height: 12),
                      
                      _buildDatePicker(),
                      const SizedBox(height: 12),
                      _buildTextField(_noteController, '📌 ملاحظة (اختياري)', Icons.note, false, maxLines: 3),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isSubmitting || _selectedProduct == null || _unitPrice <= 0) 
                          ? null 
                          : () => _submitOrder(context, authProvider, dataProvider, notifProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: (_isLoading || _isSubmitting)
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('💾 حفظ الطلب', style: TextStyle(color: Color(0xFF0F172A))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1, void Function(String)? onChanged}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
    ),
    validator: required
        ? (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null
        : null,
  );
}
  // ✅ حقل إدخال السعر يدوياً (مع ثبات التركيز)
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '💰 السعر (د.ع)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
        hintText: 'أدخل سعر القطعة',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'الرجاء إدخال السعر';
        final price = double.tryParse(v);
        if (price == null || price <= 0) return 'الرجاء إدخال سعر صحيح';
        return null;
      },
      onChanged: (value) {
        final price = double.tryParse(value);
        if (price != null && price > 0) {
          _unitPrice = price;
        } else {
          _unitPrice = 0;
        }
      },
    );
  }

  // ✅ تحديد الكمية فقط (بدون عرض السعر)
  Widget _buildQuantitySelector() {
    if (_selectedProduct == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Center(
          child: Text(
            '⚠️ الرجاء اختيار المنتج أولاً',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔢 الكمية:', style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20, color: Colors.white),
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    onPressed: _quantity < _selectedProduct!.quantity
                        ? () {
                            setState(() {
                              _quantity++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          if (_quantity > _selectedProduct!.quantity)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ الكمية المطلوبة (${_quantity}) أكبر من المتوفرة (${_selectedProduct!.quantity})',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(List<Product> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '⚠️ لا توجد منتجات في المخزن',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'الرجاء إضافة منتجات أولاً من لوحة المدير',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonFormField<String?>(
        value: _selectedProduct?.backendId,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        hint: const Text(
          '📦 اختر المنتج',
          style: TextStyle(color: Colors.grey),
        ),
        decoration: const InputDecoration(
          labelText: '📦 المنتج',
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.inventory, color: Colors.grey),
        ),
        items: products.map((product) {
          return DropdownMenuItem<String?>(
            value: product.backendId,
            child: Text(
              '${product.name} (متبقي: ${product.quantity})',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (productId) {
          final selected = products.firstWhere((p) => p.backendId == productId);
          setState(() {
            _selectedProduct = selected;
            _quantity = 1;
          });
        },
      ),
    );
  }

  Widget _buildGovernorateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGovernorate,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: '📍 المحافظة',
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.location_on, color: Colors.grey),
        ),
        items: governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (v) => setState(() => _selectedGovernorate = v!),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date.toIso8601String().split('T')[0];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text('📅 التاريخ: $_selectedDate', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder(BuildContext context, AuthProvider authProvider, DataProvider dataProvider, NotificationProvider notifProvider) async {
    // ✅ منع التكرار نهائياً
    if (_isSubmitting) {
      print("⚠️ تم تجاهل الطلب المكرر - جاري المعالجة بالفعل");
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGovernorate.isEmpty) {
      ToastMessage.show(context, '❌ الرجاء اختيار المحافظة', isError: true);
      return;
    }
    
    if (_selectedProduct == null) {
      ToastMessage.show(context, '❌ الرجاء اختيار المنتج', isError: true);
      return;
    }
    
    if (_unitPrice <= 0) {
      ToastMessage.show(context, '❌ الرجاء إدخال سعر صحيح', isError: true);
      return;
    }
    
    if (_quantity > _selectedProduct!.quantity) {
      ToastMessage.show(context, '❌ الكمية المطلوبة أكبر من المتوفرة في المخزن', isError: true);
      return;
    }

    _isSubmitting = true;
    setState(() => _isLoading = true);

    String agentName = 'مندوب';
    double profitPerOrder = AppConstants.defaultAgentProfit;

    if (authProvider.isAgentMode && authProvider.currentAgent != null) {
      agentName = authProvider.currentAgent!.agentName;
      profitPerOrder = authProvider.currentAgent!.agentProfitPerOrder;
    }

    final productName = _selectedProduct!.name;
    final productInfo = _quantity > 1 ? '$productName ×$_quantity' : productName;
    final landmark = _landmarkController.text.trim();
    final fullAddress = landmark.isNotEmpty 
        ? '$_selectedGovernorate - ${_districtController.text.trim()} (قرب: $landmark)'
        : '$_selectedGovernorate - ${_districtController.text.trim()}';
    
    final totalPrice = _unitPrice * _quantity;

    final order = Order(
      backendId: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: fullAddress,
      product: productName,
      productInfo: productInfo,
      quantity: _quantity,
      price: _unitPrice,
      total: totalPrice,
      profit: profitPerOrder,
      status: 'جديد',
      agentName: agentName,
      orderDate: _selectedDate,
      adminNotes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      governorate: _selectedGovernorate,
      district: _districtController.text.trim(),
      landmark: landmark,
      createdAt: DateTime.now(),
    );

    // ✅ خصم الكمية من المخزن أولاً
    final updatedProduct = _selectedProduct!.copyWith(
      quantity: _selectedProduct!.quantity - _quantity,
      updatedAt: DateTime.now(),
    );
    
    final productUpdated = await dataProvider.updateProduct(updatedProduct);
    
    if (!productUpdated) {
      ToastMessage.show(context, '❌ فشل تحديث المخزن، يرجى المحاولة مرة أخرى', isError: true);
      _isSubmitting = false;
      setState(() => _isLoading = false);
      return;
    }

    final success = await dataProvider.createOrder(order);
    
    setState(() => _isLoading = false);
    _isSubmitting = false;

    if (success) {
      notifProvider.addNotification(
        'طلب جديد',
        'تم إضافة طلب جديد للزبون ${order.customerName}',
        'order',
        orderId: order.backendId,
      );
      ToastMessage.show(context, '✅ تم حفظ الطلب وخصم $_quantity قطعة من المخزن');
      Navigator.pop(context);
    } else {
      // إذا فشل حفظ الطلب، نعيد الكمية إلى المخزن
      final rollbackProduct = _selectedProduct!.copyWith(
        quantity: _selectedProduct!.quantity,
        updatedAt: DateTime.now(),
      );
      await dataProvider.updateProduct(rollbackProduct);
      ToastMessage.show(context, '❌ حدث خطأ في حفظ الطلب', isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}