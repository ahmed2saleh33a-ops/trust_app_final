// lib/screens/agent/agent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/notification_panel.dart';
import '../../widgets/add_order_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/toast_message.dart';
import '../../models/order.dart';
import '../../themes/app_theme.dart';
import '../admin/orders_screen.dart';

class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key});

  void _logout(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authProvider.logout();
      ToastMessage.show(context, 'تم تسجيل الخروج');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم نسخ $message'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('👨‍💻 معلومات المطور', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المهندس حيدر علي',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, '07813824203', 'رقم المهندس حيدر'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '07813824203',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Icon(Icons.copy, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(context, '07740193972', 'رقم المهندس حيدر'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '07740193972',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Icon(Icons.copy, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _goToOrdersWithFilter(BuildContext context, String filterType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrdersScreen(),
        settings: RouteSettings(arguments: filterType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    
    final agentName = authProvider.currentAgent?.agentName ?? '';
    
    // ✅ استخدام allOrders المفلترة تلقائياً من DataProvider (طلبات المندوب فقط)
    final agentOrders = dataProvider.allOrders;
    
    final total = agentOrders.length;
    final delivered = agentOrders.where((o) => o.status == 'واصل').length;
    final pending = agentOrders.where((o) => o.status == 'قيد التوصيل').length;
    final returned = agentOrders.where((o) => o.status == 'راجع').length;
    final cancelled = agentOrders.where((o) => o.status == 'ملغي').length;
    final newOrders = agentOrders.where((o) => o.status == 'جديد').length;
    final delayed = agentOrders.where((o) => o.status == 'مؤجل').length;
    final profit = agentOrders.where((o) => o.status == 'واصل').fold(0.0, (s, o) => s + o.profit);
    final todayOrdersCount = agentOrders.where((o) {
      final orderDate = o.orderDate?.isNotEmpty == true
          ? o.orderDate
          : o.createdAt.toIso8601String().split('T')[0];
      return orderDate == DateTime.now().toIso8601String().split('T')[0];
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحتي الخاصة'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // زر الإشعارات
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => showDialog(
                  context: context, 
                  builder: (_) => const NotificationPanel(),
                ),
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProvider.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // ✅ زر إضافة طلب جديد (للمندوب فقط)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context, 
              builder: (_) => const AddOrderDialog(),
            ),
            tooltip: 'إضافة طلب جديد',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF0F172A),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF1E293B)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 35,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      agentName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'مندوب',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
                title: const Text('لوحتي'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Color(0xFF60A5FA)),
                title: const Text('طلباتي'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
              const Divider(color: Color(0xFF1E293B)),
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF10B981)),
                title: const Text(
                  '👨‍💻 المطور',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeveloperInfo(context);
                },
              ),
              const Divider(color: Color(0xFF1E293B)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج'),
                onTap: () => _logout(context, authProvider),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => dataProvider.loadData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // بطاقات الإحصائيات الأساسية
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CustomCard(
                    title: 'إجمالي طلباتي',
                    value: '$total',
                    icon: Icons.shopping_bag,
                    color: Colors.blue,
                  ),
                  CustomCard(
                    title: 'الواصلة',
                    value: '$delivered',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  CustomCard(
                    title: 'قيد التوصيل',
                    value: '$pending',
                    icon: Icons.pending,
                    color: AppTheme.primaryColor,
                  ),
                  CustomCard(
                    title: 'الراجعة',
                    value: '$returned',
                    icon: Icons.refresh,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ✅ أزرار التصفية السريعة لطلباتي (للمندوب فقط: راجع، ملغي، مؤجل، اليوم)
              Text(
                'تصفية طلباتي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 12),
              
              // ✅ الصف الأول: راجع - ملغي - مؤجل (للمندوب فقط)
              Row(
                children: [
                  _buildStatusButton(
                    context: context,
                    label: 'راجع',
                    count: returned,
                    icon: Icons.refresh,
                    color: Colors.red,
                    filterType: 'returned',
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context: context,
                    label: 'ملغي',
                    count: cancelled,
                    icon: Icons.cancel,
                    color: Colors.purple,
                    filterType: 'cancelled',
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context: context,
                    label: 'مؤجل',
                    count: delayed,
                    icon: Icons.timer,
                    color: const Color(0xFFF59E0B),
                    filterType: 'delayed',
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context: context,
                    label: 'اليوم',
                    count: todayOrdersCount,
                    icon: Icons.calendar_today,
                    color: const Color(0xFFF59E0B),
                    filterType: 'today',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              // إجمالي أرباحي
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'إجمالي أرباحي',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profit.toInt()} د.ع',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // طلباتي الأخيرة
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'طلباتي الأخيرة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (agentOrders.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              '📭 لا توجد طلبات',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: agentOrders.length > 10 ? 10 : agentOrders.length,
                          itemBuilder: (context, index) {
                            final order = agentOrders[index];
                            return _AgentOrderItem(order: order);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ دالة مساعدة لبناء أزرار الحالات (للمندوب فقط: راجع، ملغي، مؤجل، اليوم)
  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required String filterType,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _goToOrdersWithFilter(context, filterType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentOrderItem extends StatelessWidget {
  final Order order;

  const _AgentOrderItem({required this.order});

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم نسخ النص'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productDisplay,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, order.customerPhone),
                      child: Text(
                        '📞 ${order.customerPhone}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.total.toInt()} د.ع',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, displayDate ?? ''),
                    child: Text(
                      '📅 ${displayDate ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: order.status),
                ],
              ),
            ],
          ),
          if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.message, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullNote(context),
                      child: Text(
                        order.adminNotes!.length > 40 ? '${order.adminNotes!.substring(0, 40)}...' : order.adminNotes!,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
}