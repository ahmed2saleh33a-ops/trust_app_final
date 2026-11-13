// lib/screens/admin/agents_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agent.dart';
import '../../models/order.dart';
import '../../providers/data_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/agent_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/toast_message.dart';
import '../../utils/constants.dart';
import '../../themes/app_theme.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  Agent? _editingAgent;

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return RefreshIndicator(
      onRefresh: () => dataProvider.loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // زر إضافة مندوب
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _showAgentDialog(context, dataProvider, notifProvider),
                icon: const Icon(Icons.person_add),
                label: const Text('إضافة مندوب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // شبكة المندوبين
            dataProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dataProvider.allAgents.isEmpty
                    ? const Center(child: Text('👥 لا توجد مندوبين', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: dataProvider.allAgents.length,
                        itemBuilder: (context, index) {
                          final agent = dataProvider.allAgents[index];
                          final agentOrders = dataProvider.allOrders
                              .where((o) => o.agentName == agent.agentName)
                              .toList();
                          final totalProfit = dataProvider.getAgentTotalProfit(agent.agentName);
                          return AgentCard(
                            agent: agent,
                            agentOrders: agentOrders,
                            totalProfit: totalProfit,
                            onEdit: () => _showAgentDialog(context, dataProvider, notifProvider, agent: agent),
                            onDelete: () => _deleteAgent(context, agent, dataProvider),
                            onSettle: () => _settleAgent(context, agent, dataProvider),
                            onTap: () => _showAgentStats(context, agent, agentOrders),
                          );
                        },
                      ),
            const SizedBox(height: 24),
            // بطاقة إحصائيات المندوبين
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إحصائيات المندوبين',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._getAgentStats(dataProvider.allOrders, dataProvider.allAgents).map((stat) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(
                          stat['name'][0],
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                      title: Text(stat['name']),
                      subtitle: Text('واصل: ${stat['delivered']} | مرتجع: ${stat['returned']} | ملغي: ${stat['cancelled']}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stat['sales'].toInt()} د.ع',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                          Text(
                            '${stat['profit'].toInt()} د.ع',
                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAgentStats(List<Order> orders, List<Agent> agents) {
    final Map<String, Map<String, dynamic>> stats = {};
    for (final agent in agents) {
      stats[agent.agentName] = {
        'name': agent.agentName,
        'delivered': 0,
        'returned': 0,
        'cancelled': 0,
        'sales': 0.0,
        'profit': 0.0,
      };
    }
    for (final order in orders) {
      if (stats.containsKey(order.agentName)) {
        if (order.status == 'واصل') {
          stats[order.agentName]!['delivered']++;
          stats[order.agentName]!['sales'] += order.total;
          stats[order.agentName]!['profit'] += order.profit;
        } else if (order.status == 'راجع') {
          stats[order.agentName]!['returned']++;
        } else if (order.status == 'ملغي') {
          stats[order.agentName]!['cancelled']++;
        }
      }
    }
    return stats.values.toList();
  }

  // نافذة إضافة/تعديل مندوب
  Future<void> _showAgentDialog(
    BuildContext context,
    DataProvider dataProvider,
    NotificationProvider notifProvider, {
    Agent? agent,
  }) async {
    final isEditing = agent != null;
    final nameController = TextEditingController(text: agent?.agentName ?? '');
    final phoneController = TextEditingController(text: agent?.agentPhone ?? '');
    final codeController = TextEditingController(text: agent?.agentCode ?? '');
    final passwordController = TextEditingController(text: agent?.agentPassword ?? '');
    final profitController = TextEditingController(
      text: (agent?.agentProfitPerOrder ?? AppConstants.defaultAgentProfit).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          isEditing ? '✏️ تعديل مندوب' : '➕ إضافة مندوب',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '👤 اسم المندوب',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '📞 رقم الهاتف',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '🔑 كود المندوب',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '🔒 كلمة المرور',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: profitController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '💰 الربح الثابت لكل طلب',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
      if (isEditing && agent != null) {
        final updatedAgent = Agent(
          id: agent.id,
          backendId: agent.backendId,
          type: 'agent',
          agentName: nameController.text.trim(),
          agentPhone: phoneController.text.trim(),
          agentCode: codeController.text.trim(),
          agentPassword: passwordController.text.trim(),
          agentProfitPerOrder: double.tryParse(profitController.text) ?? AppConstants.defaultAgentProfit,
          createdAt: agent.createdAt,
          updatedAt: DateTime.now(),
        );
        success = await dataProvider.updateAgent(updatedAgent);
        if (success) {
          notifProvider.addNotification(
            'تعديل مندوب',
            'تم تعديل بيانات المندوب ${updatedAgent.agentName}',
            'agent',
          );
        }
      } else {
        final newAgent = Agent(
          backendId: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'agent',
          agentName: nameController.text.trim(),
          agentPhone: phoneController.text.trim(),
          agentCode: codeController.text.trim(),
          agentPassword: passwordController.text.trim(),
          agentProfitPerOrder: double.tryParse(profitController.text) ?? AppConstants.defaultAgentProfit,
          createdAt: DateTime.now(),
        );
        success = await dataProvider.createAgent(newAgent);
        if (success) {
          notifProvider.addNotification(
            'مندوب جديد',
            'تم إضافة مندوب جديد: ${newAgent.agentName}',
            'agent',
          );
        }
      }
      ToastMessage.show(
        context,
        success ? (isEditing ? '✅ تم التحديث' : '✅ تم الإضافة') : '❌ حدث خطأ',
        isError: !success,
      );
    }
  }

  // حذف مندوب
  Future<void> _deleteAgent(BuildContext context, Agent agent, DataProvider dataProvider) async {
    final orderCount = dataProvider.allOrders.where((o) => o.agentName == agent.agentName).length;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المندوب',
      message: 'هل أنت متأكد من حذف المندوب ${agent.agentName}\n(لديه $orderCount طلب مرتبط)',
    );
    if (confirmed) {
      if (await dataProvider.deleteAgent(agent.backendId!)) {
        ToastMessage.show(context, '✅ تم الحذف');
      }
    }
  }

  // ✅ تسديد أرباح المندوب (تصفير الطلبات الواصلة فقط)
  Future<void> _settleAgent(BuildContext context, Agent agent, DataProvider dataProvider) async {
    final totalProfit = dataProvider.getAgentTotalProfit(agent.agentName);
    
    if (totalProfit == 0) {
      ToastMessage.show(context, '⚠️ لا توجد أرباح مستحقة لهذا المندوب');
      return;
    }

    // ✅ الحصول على عدد الطلبات الواصلة
    final deliveredOrdersCount = dataProvider.getAgentDeliveredOrders(agent.agentName);
    
    final paidAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('💰 تسديد أرباح المندوب', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👤 المندوب: ${agent.agentName}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '💰 إجمالي الأرباح المستحقة: ${totalProfit.toInt()} د.ع',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              '📦 عدد الطلبات الواصلة: $deliveredOrdersCount طلب',
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '💵 المبلغ المدفوع (د.ع)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: totalProfit.toString()),
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
              Navigator.pop(context, totalProfit);
            },
            child: const Text('تسديد'),
          ),
        ],
      ),
    );

    if (paidAmount != null && paidAmount > 0) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'تأكيد التسديد',
        message: 'هل أنت متأكد من تسديد ${paidAmount.toInt()} د.ع للمندوب ${agent.agentName}؟\n\n⚠️ سيتم تصفير أرباح الطلبات الواصلة فقط (${deliveredOrdersCount} طلب) دون حذفها.',
      );
      if (confirmed) {
        // ✅ إظهار مؤشر تحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تسديد الأرباح...'),
                  ],
                ),
              ),
            ),
          ),
        );
        
        final success = await dataProvider.settleAgent(agent.backendId!, paidAmount);
        
        // ✅ إغلاق مؤشر التحميل
        Navigator.pop(context);
        
        if (success) {
          ToastMessage.show(context, '✅ تم تسديد أرباح المندوب وتصفير الطلبات الواصلة');
          await dataProvider.refreshData(); // تحديث البيانات
        } else {
          ToastMessage.show(context, '❌ فشل تسديد الأرباح', isError: true);
        }
      }
    }
  }

  // عرض إحصائيات المندوب
  void _showAgentStats(BuildContext context, Agent agent, List<Order> orders) {
    final delivered = orders.where((o) => o.status == 'واصل').length;
    final returned = orders.where((o) => o.status == 'راجع').length;
    final cancelled = orders.where((o) => o.status == 'ملغي').length;
    final sales = orders.where((o) => o.status == 'واصل').fold(0.0, (s, o) => s + o.total);
    final profit = orders.where((o) => o.status == 'واصل').fold(0.0, (s, o) => s + o.profit);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          agent.agentName,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow(label: '📞 الهاتف', value: agent.agentPhone),
            _StatRow(label: '🔑 الكود', value: agent.agentCode),
            const Divider(color: Colors.grey),
            _StatRow(label: '📦 إجمالي الطلبات', value: '${orders.length}'),
            _StatRow(label: '✅ الواصلة', value: '$delivered', valueColor: Colors.green),
            _StatRow(label: '❌ المرتجعة', value: '$returned', valueColor: Colors.red),
            _StatRow(label: '❌ الملغية', value: '$cancelled', valueColor: Colors.purple),
            _StatRow(label: '💰 المبيعات', value: '${sales.toInt()} د.ع', valueColor: Colors.green),
            _StatRow(label: '💵 الأرباح', value: '${profit.toInt()} د.ع', valueColor: AppTheme.primaryColor),
            _StatRow(
              label: '🎯 الربح لكل طلب',
              value: '${agent.agentProfitPerOrder.toInt()} د.ع',
              valueColor: const Color(0xFF60A5FA),
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
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}