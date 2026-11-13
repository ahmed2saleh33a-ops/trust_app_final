// lib/widgets/edit_order_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import 'toast_message.dart';

const List<String> governorates = [
  'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كركوك',
  'الأنبار', 'كربلاء', 'ذي قار', 'ميسان', 'بابل', 'واسط',
  'صلاح الدين', 'ديالى', 'المثنى', 'القادسية',
  'السليمانية', 'دهوك'
];

class EditOrderDialog extends StatefulWidget {
  final Order order;

  const EditOrderDialog({super.key, required this.order});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _districtController;
  late TextEditingController _landmarkController;
  late TextEditingController _productController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  late String _selectedGovernorate;
  late String _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.order.customerName);
    _phoneController = TextEditingController(text: widget.order.customerPhone);
    _districtController = TextEditingController(text: widget.order.district ?? '');
    _landmarkController = TextEditingController(text: widget.order.landmark ?? '');
    _productController = TextEditingController(text: widget.order.product);
    _quantityController = TextEditingController(text: widget.order.quantity.toString());
    _priceController = TextEditingController(text: widget.order.price.toString());
    _noteController = TextEditingController(text: widget.order.adminNotes ?? '');
    _selectedGovernorate = widget.order.governorate ?? governorates.first;
    _selectedDate = widget.order.orderDate ?? DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

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
                  const Text('✏️ تعديل الطلب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                child: Column(
                  children: [
                    _buildTextField(_nameController, '👤 اسم الزبون', Icons.person, true),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, '📞 رقم الهاتف', Icons.phone, true),
                    const SizedBox(height: 12),
                    _buildGovernorateDropdown(),
                    const SizedBox(height: 12),
                    _buildTextField(_districtController, '🏘️ المنطقة/الحي', Icons.location_city, true),
                    const SizedBox(height: 12),
                    _buildTextField(_landmarkController, '📍 أقرب نقطة دالة', Icons.place, false),
                    const SizedBox(height: 12),
                    _buildTextField(_productController, '📦 المنتج', Icons.inventory, true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_quantityController, '🔢 الكمية', Icons.numbers, true, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_priceController, '💰 السعر (د.ع)', Icons.attach_money, true, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 12),
                    _buildTextField(_noteController, '📌 ملاحظة (اختياري)', Icons.note, false, maxLines: 3),
                  ],
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
                      onPressed: _isLoading ? null : () => _updateOrder(context, dataProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('💾 حفظ التعديلات', style: TextStyle(color: Color(0xFF0F172A))),
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
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
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
          initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
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

  Future<void> _updateOrder(BuildContext context, DataProvider dataProvider) async {
    setState(() => _isLoading = true);

    final qty = int.parse(_quantityController.text);
    final price = double.parse(_priceController.text);
    final total = price;
    final landmark = _landmarkController.text.trim();
    final fullAddress = landmark.isNotEmpty
        ? '$_selectedGovernorate - ${_districtController.text.trim()} (قرب: $landmark)'
        : '$_selectedGovernorate - ${_districtController.text.trim()}';

    final updatedOrder = widget.order.copyWith(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: fullAddress,
      governorate: _selectedGovernorate,
      district: _districtController.text.trim(),
      landmark: landmark,
      product: _productController.text.trim(),
      quantity: qty,
      price: price,
      total: total,
      orderDate: _selectedDate,
      adminNotes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await dataProvider.updateOrder(updatedOrder);
    setState(() => _isLoading = false);

    if (success) {
      ToastMessage.show(context, '✅ تم تحديث الطلب بنجاح');
      Navigator.pop(context);
    } else {
      ToastMessage.show(context, '❌ حدث خطأ أثناء التحديث', isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}