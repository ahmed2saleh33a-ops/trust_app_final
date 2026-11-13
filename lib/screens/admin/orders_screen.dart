// lib/screens/admin/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/edit_order_dialog.dart';
import '../../utils/constants.dart';
import '../../themes/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _statusFilter = 'all';
  String _searchQuery = '';
  String _presetFilter = 'all';  // ✅ متغير للفلتر المحدد مسبقاً

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is String) {
        setState(() {
          _presetFilter = arguments;
          
          // ✅ تعيين فلتر الحالة بناءً على المعامل
          switch (arguments) {
            case 'new':
              _statusFilter = 'جديد';
              ToastMessage.show(context, '📋 عرض الطلبات الجديدة');
              break;
            case 'pending':
              _statusFilter = 'قيد التوصيل';
              ToastMessage.show(context, '🚚 عرض الطلبات قيد التوصيل');
              break;
            case 'delivered':
              _statusFilter = 'واصل';
              ToastMessage.show(context, '✅ عرض الطلبات الواصلة');
              break;
            case 'returned':
              _statusFilter = 'راجع';
              ToastMessage.show(context, '↩️ عرض الطلبات المرتجعة');
              break;
            case 'cancelled':
              _statusFilter = 'ملغي';
              ToastMessage.show(context, '❌ عرض الطلبات الملغية');
              break;
            case 'delayed':
              _statusFilter = 'مؤجل';
              ToastMessage.show(context, '⏰ عرض الطلبات المؤجلة');
              break;
            case 'today':
              _presetFilter = 'today';
              ToastMessage.show(context, '📅 عرض طلبات اليوم فقط');
              break;
            default:
              break;
          }
        });
      }
    });
  }

  @override
Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final isAdmin = authProvider.isAdmin;

    List<Order> filteredOrders = dataProvider.allOrders;
    
    // ✅ تصفية حسب الحالة
    if (_statusFilter != 'all') {
      filteredOrders = filteredOrders.where((o) => o.status == _statusFilter).toList();
    }
    
    // ✅ تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((o) =>
          o.customerName.contains(_searchQuery) ||
          o.customerPhone.contains(_searchQuery)).toList();
    }
    
    // ✅ تصفية طلبات اليوم
    if (_presetFilter == 'today') {
      final today = DateTime.now().toIso8601String().split('T')[0];
      filteredOrders = filteredOrders.where((o) {
        final orderDate = o.orderDate?.isNotEmpty == true
            ? o.orderDate
            : o.createdAt.toIso8601String().split('T')[0];
        return orderDate == today;
      }).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: '🔍 بحث بالاسم أو الهاتف...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                          ...AppConstants.orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ✅ أزرار التصفية السريعة
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterChip(
                        label: 'جديد',
                        icon: Icons.fiber_new,
                        color: Colors.blue,
                        isActive: _statusFilter == 'جديد',
                        onTap: () => setState(() {
                          _statusFilter = 'جديد';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'قيد التوصيل',
                        icon: Icons.local_shipping,
                        color: const Color(0xFFF59E0B),
                        isActive: _statusFilter == 'قيد التوصيل',
                        onTap: () => setState(() {
                          _statusFilter = 'قيد التوصيل';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'واصل',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        isActive: _statusFilter == 'واصل',
                        onTap: () => setState(() {
                          _statusFilter = 'واصل';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'راجع',
                        icon: Icons.refresh,
                        color: Colors.red,
                        isActive: _statusFilter == 'راجع',
                        onTap: () => setState(() {
                          _statusFilter = 'راجع';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'ملغي',
                        icon: Icons.cancel,
                        color: Colors.purple,
                        isActive: _statusFilter == 'ملغي',
                        onTap: () => setState(() {
                          _statusFilter = 'ملغي';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'مؤجل',
                        icon: Icons.timer,
                        color: const Color(0xFFF59E0B),
                        isActive: _statusFilter == 'مؤجل',
                        onTap: () => setState(() {
                          _statusFilter = 'مؤجل';
                          _presetFilter = 'all';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        label: 'اليوم',
                        icon: Icons.calendar_today,
                        color: const Color(0xFFF59E0B),
                        isActive: _presetFilter == 'today',
                        onTap: () => setState(() {
                          if (_presetFilter == 'today') {
                            _presetFilter = 'all';
                            _statusFilter = 'all';
                          } else {
                            _presetFilter = 'today';
                            _statusFilter = 'all';
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          _presetFilter == 'today' ? '📅 لا توجد طلبات لهذا اليوم' : '📭 لا توجد طلبات',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderListItem(
                            order: order,
                            index: index,
                            isAdmin: isAdmin,
                            onEditOrder: () => _editOrder(context, order),
                            onEditProfit: isAdmin ? () => _editProfit(context, order, dataProvider, notifProvider) : null,
                            onEditDate: isAdmin ? () => _editDate(context, order, dataProvider, notifProvider) : null,
                            onDelete: isAdmin ? () => _deleteOrder(context, order, dataProvider) : null,
                            onEditNote: !isAdmin ? () => _editNote(context, order, dataProvider, authProvider, notifProvider) : null,
                            onStatusTap: () => _showStatusDialog(context, order, dataProvider, notifProvider),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة مساعدة لبناء أزرار التصفية السريعة
  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.black : color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 12)),
        ],
      ),
      selected: isActive,
      onSelected: (_) => onTap(),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: color,
      checkmarkColor: Colors.black,
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: StadiumBorder(),
    );
  }

  void _showStatusDialog(BuildContext context, Order order, DataProvider dataProvider, NotificationProvider notifProvider) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    final statuses = Order.getAvailableStatuses(isAdmin: isAdmin);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🔄 تغيير حالة الطلب', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) => ListTile(
            leading: Text(Order.getStatusIcon(status)),
            title: Text(status, style: const TextStyle(color: Colors.white)),
            trailing: order.status == status ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
              Navigator.pop(dialogContext);
              
              if (status == 'ملغي' && order.backendId != null) {
                final canceled = await dataProvider.cancelOrderInJenni(
                  order.backendId!,
                  reason: 'تم إلغاء الطلب من قبل المدير',
                );
                if (canceled) {
                  ToastMessage.show(context, '✅ تم إلغاء الطلب في نظام الزعيم');
                } else {
                  ToastMessage.show(context, '⚠️ تم تغيير الحالة محلياً فقط');
                }
              }
              
              final updatedOrder = order.copyWith(status: status, updatedAt: DateTime.now());
              final success = await dataProvider.updateOrder(updatedOrder);
              if (success) {
                notifProvider.addNotification(
                  'تغيير حالة',
                  'تم تغيير حالة طلب ${order.customerName} من ${order.status} إلى $status',
                  'status',
                  orderId: order.backendId,
                );
                ToastMessage.show(context, '✅ تم التغيير من ${order.status} إلى $status');
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _editOrder(BuildContext context, Order order) async {
    await showDialog(
      context: context,
      builder: (context) => EditOrderDialog(order: order),
    );
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.loadData();
    ToastMessage.show(context, '✅ تم تحديث الطلب بنجاح');
  }

  Future<void> _editProfit(BuildContext context, Order order, DataProvider dataProvider, NotificationProvider notifProvider) async {
    final controller = TextEditingController(text: order.profit.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('💰 تعديل الربح', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'مبلغ الربح (د.ع)',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text) ?? 0), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != null && result != order.profit) {
      final updatedOrder = order.copyWith(profit: result, updatedAt: DateTime.now());
      if (await dataProvider.updateOrder(updatedOrder)) {
        ToastMessage.show(context, '✅ تم تحديث الربح');
      }
    }
  }

  Future<void> _editDate(BuildContext context, Order order, DataProvider dataProvider, NotificationProvider notifProvider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(order.orderDate ?? '') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final updatedOrder = order.copyWith(orderDate: date.toIso8601String().split('T')[0], updatedAt: DateTime.now());
      if (await dataProvider.updateOrder(updatedOrder)) {
        ToastMessage.show(context, '✅ تم تحديث التاريخ');
      }
    }
  }

  Future<void> _editNote(BuildContext context, Order order, DataProvider dataProvider, AuthProvider authProvider, NotificationProvider notifProvider) async {
    final controller = TextEditingController(text: order.adminNotes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('📌 تعديل الملاحظة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'الملاحظة',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != null) {
      final timestamp = DateTime.now().toLocal().toString().split('.')[0];
      final agentName = authProvider.currentAgent?.agentName ?? 'مندوب';
      final newNote = order.adminNotes != null && order.adminNotes!.isNotEmpty
          ? '${order.adminNotes}\n[$timestamp] $agentName: $result'
          : '[$timestamp] $agentName: $result';
      final updatedOrder = order.copyWith(adminNotes: newNote, updatedAt: DateTime.now());
      if (await dataProvider.updateOrder(updatedOrder)) {
        ToastMessage.show(context, '✅ تم تحديث الملاحظة');
      }
    }
  }

  Future<void> _deleteOrder(BuildContext context, Order order, DataProvider dataProvider) async {
    final confirmed = await ConfirmationDialog.show(
      context, 
      title: 'حذف الطلب', 
      message: 'هل أنت متأكد من حذف طلب ${order.customerName}؟',
    );
    if (confirmed) {
      if (await dataProvider.deleteOrder(order.backendId!)) {
        ToastMessage.show(context, '✅ تم الحذف');
      }
    }
  }
}

class _OrderListItem extends StatelessWidget {
  final Order order;
  final int index;
  final bool isAdmin;
  final VoidCallback? onEditOrder;
  final VoidCallback? onEditProfit;
  final VoidCallback? onEditDate;
  final VoidCallback? onDelete;
  final VoidCallback? onEditNote;
  final VoidCallback? onStatusTap;

  const _OrderListItem({
    required this.order,
    required this.index,
    required this.isAdmin,
    this.onEditOrder,
    this.onEditProfit,
    this.onEditDate,
    this.onDelete,
    this.onEditNote,
    this.onStatusTap,
  });

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ToastMessage.show(context, '✅ تم نسخ النص');
    }
  }

  void _showFullNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📌 ملاحظة الطلب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'للزبون: ${order.customerName}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.adminNotes ?? 'لا توجد ملاحظات',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = order.orderDate?.isNotEmpty == true
        ? order.orderDate
        : order.createdAt.toIso8601String().split('T')[0];
    
    final productDisplay = order.fullProductName;
    
    String addressDisplay = order.customerAddress;
    if (order.landmark != null && order.landmark!.isNotEmpty) {
      addressDisplay = '${order.customerAddress}\n📍 قرب: ${order.landmark}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${index + 1}', style: const TextStyle(color: Colors.grey)),
              Row(
                children: [
                  if (onEditOrder != null)
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue, size: 18),
                      onPressed: onEditOrder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'تعديل الطلب',
                    ),
                  if (isAdmin && onEditProfit != null)
                    IconButton(
                      icon: const Icon(Icons.monetization_on, color: AppTheme.primaryColor, size: 18),
                      onPressed: onEditProfit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'تعديل الربح',
                    ),
                  if (isAdmin && onEditDate != null)
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.purple, size: 18),
                      onPressed: onEditDate,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'تعديل التاريخ',
                    ),
                  if (isAdmin && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'حذف الطلب',
                    ),
                  if (!isAdmin && onEditNote != null)
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.green, size: 18),
                      onPressed: onEditNote,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'تعديل الملاحظة',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(productDisplay, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, order.customerPhone),
                      child: Text(
                        '📞 ${order.customerPhone}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, addressDisplay),
                      child: Text(
                        addressDisplay.length > 40 ? '${addressDisplay.substring(0, 40)}...' : addressDisplay,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${order.total.toInt()} د.ع', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    Text('ربح: ${order.profit.toInt()} د.ع', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                  Text(order.agentName, style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                  GestureDetector(
                    onTap: isAdmin ? onEditDate : null,
                    child: Text(
                      '📅 ${displayDate ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullNote(context),
                    child: Text(
                      order.adminNotes!.length > 40 ? '${order.adminNotes!.substring(0, 40)}...' : order.adminNotes!,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onStatusTap,
                child: StatusBadge(status: order.status, isClickable: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}