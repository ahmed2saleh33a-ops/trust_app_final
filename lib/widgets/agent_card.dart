// lib/widgets/agent_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/agent.dart';
import '../models/order.dart';
import '../themes/app_theme.dart';

class AgentCard extends StatelessWidget {
  final Agent agent;
  final List<Order> agentOrders;
  final double totalProfit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSettle;
  final VoidCallback onTap;

  const AgentCard({
    super.key,
    required this.agent,
    required this.agentOrders,
    required this.totalProfit,
    required this.onEdit,
    required this.onDelete,
    required this.onSettle,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final delivered = agentOrders.where((o) => o.status == 'واصل').length;
    final returned = agentOrders.where((o) => o.status == 'راجع').length;
    final cancelled = agentOrders.where((o) => o.status == 'ملغي').length;
    final profit = totalProfit;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم المندوب وأزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        agent.agentName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // ✅ رمز الدخول (Username) - قابل للنسخ
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, agent.agentCode, 'رمز الدخول'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_pin, size: 10, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '👤 رمز الدخول: ${agent.agentCode}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 10, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // ✅ كلمة المرور (Password) - قابلة للنسخ
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, agent.agentPassword, 'كلمة المرور'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, size: 10, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                '🔒 كلمة المرور: ${agent.agentPassword}',
                                style: const TextStyle(
                                  color: Colors.redAccent, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 10, color: Colors.redAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 10, color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _copyToClipboard(context, agent.agentPhone, 'رقم الهاتف'),
                              child: Text(
                                agent.agentPhone,
                                style: const TextStyle(color: Colors.grey, fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onPressed: onEdit,
                    ),
                    _buildActionButton(
                      icon: Icons.wallet,
                      color: AppTheme.primaryColor,
                      onPressed: onSettle,
                      tooltip: 'تسديد أرباح المندوب',
                    ),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // الإحصائيات الأساسية
            Row(
              children: [
                _StatItem(
                  value: delivered.toString(),
                  label: 'واصل',
                  color: Colors.green,
                ),
                _StatItem(
                  value: returned.toString(),
                  label: 'مرتجع',
                  color: Colors.red,
                ),
                _StatItem(
                  value: cancelled.toString(),
                  label: 'ملغي',
                  color: Colors.purple,
                ),
                _StatItem(
                  value: agentOrders.length.toString(),
                  label: 'طلبات',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // خط فاصل
            Divider(color: Colors.grey.withOpacity(0.2), height: 1),
            const SizedBox(height: 4),
            // الأرباح في صف واحد مضغوط
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Text('💵', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      const Text(
                        'الأرباح:',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    '${profit.toInt()} د.ع',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      const Text(
                        'الربح/طلب:',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    '${agent.agentProfitPerOrder.toInt()} د.ع',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء أزرار الإجراءات
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}