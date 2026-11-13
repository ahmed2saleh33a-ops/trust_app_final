// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/notification_panel.dart';
import '../../widgets/add_order_dialog.dart';
import '../../widgets/toast_message.dart';
import '../../themes/app_theme.dart';
import 'orders_screen.dart';
import 'agents_screen.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'inventory_management_screen.dart';  // ✅ إضافة شاشة إدارة المخزن الجديدة

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSyncing = false;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const OrdersScreen(),
    const AgentsScreen(),
    const CustomersScreen(),
    const InventoryManagementScreen(),  // ✅ استبدال InventoryScreen بـ InventoryManagementScreen
    const ReportsScreen(),
  ];

  final List<String> _titles = [
    'لوحة التحكم',
    'الطلبات',
    'المندوبين',
    'العملاء',
    'المخزن',
    'التقارير',
  ];

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.shopping_bag,
    Icons.people,
    Icons.contact_mail,
    Icons.inventory,
    Icons.bar_chart,
  ];

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
            ),
          ],
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

  Future<void> _syncWithJenni(BuildContext context) async {
    if (_isSyncing) {
      ToastMessage.show(context, '⚠️ جاري المزامنة حالياً...');
      return;
    }
    
    _isSyncing = true;
    ToastMessage.show(context, '🔄 جاري المزامنة مع نظام الزعيم...');
    
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final success = await dataProvider.syncWithJenni();
      
      if (success) {
        ToastMessage.show(context, '✅ تمت المزامنة مع نظام الزعيم بنجاح');
        await dataProvider.refreshData();
      } else {
        ToastMessage.show(context, '❌ فشل المزامنة', isError: true);
      }
    } catch (e) {
      ToastMessage.show(context, '❌ حدث خطأ أثناء المزامنة', isError: true);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(authProvider),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
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
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
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
                  const Text(
                    'سمايل كوزمتك',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.currentAgent?.agentName ?? 'المدير العام',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Text(
                    'مسؤول النظام',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            ...List.generate(_titles.length, (index) {
              return ListTile(
                leading: Icon(
                  _icons[index],
                  color: _selectedIndex == index ? AppTheme.primaryColor : Colors.grey,
                ),
                title: Text(
                  _titles[index],
                  style: TextStyle(
                    color: _selectedIndex == index ? AppTheme.primaryColor : Colors.white,
                  ),
                ),
                selected: _selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(color: Color(0xFF334155)),
            ListTile(
              leading: const Icon(Icons.code, color: Color(0xFF10B981)),
              title: const Text(
                '👨‍💻 المطور',
                style: TextStyle(color: Color(0xFF10B981)),
              ),
              onTap: () => _showDeveloperInfo(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('تسجيل خروج'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// الصفحة الرئيسية للمدير
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

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
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final orders = dataProvider.allOrders;
        
        // إحصائيات جميع الحالات
        final totalOrders = orders.length;
        final newOrders = orders.where((o) => o.status == 'جديد').length;
        final pendingOrders = orders.where((o) => o.status == 'قيد التوصيل').length;
        final deliveredOrders = orders.where((o) => o.status == 'واصل').length;
        final returnedOrders = orders.where((o) => o.status == 'راجع').length;
        final cancelledOrders = orders.where((o) => o.status == 'ملغي').length;
        final delayedOrders = orders.where((o) => o.status == 'مؤجل').length;
        final todayOrdersCount = orders.where((o) {
          final orderDate = o.orderDate?.isNotEmpty == true
              ? o.orderDate
              : o.createdAt.toIso8601String().split('T')[0];
          return orderDate == DateTime.now().toIso8601String().split('T')[0];
        }).length;

        return RefreshIndicator(
          onRefresh: () => dataProvider.loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
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
                      title: 'إجمالي الطلبات',
                      value: '$totalOrders',
                      icon: Icons.shopping_bag,
                      color: Colors.blue,
                    ),
                    CustomCard(
                      title: 'واصل',
                      value: '$deliveredOrders',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    CustomCard(
                      title: 'مرتجع',
                      value: '$returnedOrders',
                      icon: Icons.refresh,
                      color: Colors.red,
                    ),
                    CustomCard(
                      title: 'ملغي',
                      value: '$cancelledOrders',
                      icon: Icons.cancel,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // ✅ أزرار التصفية السريعة (جميع الحالات)
                Text(
                  'التصفية السريعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                
                // الصف الأول: جديد - قيد التوصيل - واصل
                Row(
                  children: [
                    _buildStatusButton(
                      context: context,
                      label: 'جديد',
                      count: newOrders,
                      icon: Icons.fiber_new,
                      color: Colors.blue,
                      filterType: 'new',
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      context: context,
                      label: 'قيد التوصيل',
                      count: pendingOrders,
                      icon: Icons.local_shipping,
                      color: const Color(0xFFF59E0B),
                      filterType: 'pending',
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      context: context,
                      label: 'واصل',
                      count: deliveredOrders,
                      icon: Icons.check_circle,
                      color: Colors.green,
                      filterType: 'delivered',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // الصف الثاني: راجع - ملغي - مؤجل
                Row(
                  children: [
                    _buildStatusButton(
                      context: context,
                      label: 'راجع',
                      count: returnedOrders,
                      icon: Icons.refresh,
                      color: Colors.red,
                      filterType: 'returned',
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      context: context,
                      label: 'ملغي',
                      count: cancelledOrders,
                      icon: Icons.cancel,
                      color: Colors.purple,
                      filterType: 'cancelled',
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      context: context,
                      label: 'مؤجل',
                      count: delayedOrders,
                      icon: Icons.timer,
                      color: const Color(0xFFF59E0B),
                      filterType: 'delayed',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // الصف الثالث: طلبات اليوم
                Row(
                  children: [
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
                
                const SizedBox(height: 24),
                // آخر الطلبات
                Card(
                  color: const Color(0xFF1E293B),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'آخر الطلبات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...orders.take(5).map((order) => ListTile(
                          title: Text(order.customerName),
                          subtitle: Text('${order.product} - ${order.agentName}'),
                          trailing: Text('${order.total.toInt()} د.ع'),
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Order.getStatusColor(order.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )),
                        if (orders.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('لا توجد طلبات'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // أداء المندوبين
                Card(
                  color: const Color(0xFF1E293B),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أداء المندوبين',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ..._getAgentPerformance(orders).map((item) => ListTile(
                          title: Text(item['name']),
                          subtitle: Text('${item['orders']} طلب (${item['delivered']} واصل)'),
                          trailing: Text('${((item['delivered'] / item['orders']) * 100).toInt()}%'),
                        )),
                        if (_getAgentPerformance(orders).isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('لا توجد بيانات'),
                            ),
                          ),
                      ],
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

  // ✅ دالة مساعدة لبناء أزرار الحالات
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrdersScreen(),
              settings: RouteSettings(arguments: filterType),
            ),
          );
        },
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

  List<Map<String, dynamic>> _getAgentPerformance(List orders) {
    final Map<String, Map<String, dynamic>> agents = {};
    for (final order in orders) {
      if (!agents.containsKey(order.agentName)) {
        agents[order.agentName] = {
          'name': order.agentName,
          'orders': 0,
          'delivered': 0,
        };
      }
      agents[order.agentName]!['orders']++;
      if (order.status == 'واصل') {
        agents[order.agentName]!['delivered']++;
      }
    }
    return agents.values.toList();
  }
}
