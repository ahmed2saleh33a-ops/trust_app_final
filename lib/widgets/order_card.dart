// lib/widgets/order_card.dart
import 'package:flutter/material.dart';
import 'status_badge.dart';
import '../models/order.dart';
import '../themes/app_theme.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final int index;
  final VoidCallback? onEditProfit;
  final VoidCallback? onEditDate;
  final VoidCallback? onDelete;
  final VoidCallback? onEditNote;
  final VoidCallback? onStatusTap;
  final bool isAdmin;

  const OrderCard({
    super.key,
    required this.order,
    required this.index,
    this.onEditProfit,
    this.onEditDate,
    this.onDelete,
    this.onEditNote,
    this.onStatusTap,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = order.orderDate?.isNotEmpty == true
        ? order.orderDate
        : order.createdAt.toIso8601String().split('T')[0];
    
    final productDisplay = order.fullProductName;
    final addressDisplay = order.fullAddress;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الطلب وأزرار الإجراءات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('#${index + 1}', style: const TextStyle(color: Colors.grey)),
                  // ✅ عرض الرقم التسلسلي للمندوب (مخفي ولكن يعمل)
                  if (order.localSerial != null && order.localSerial! > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.numbers, size: 10, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'س:${order.localSerial}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (isAdmin && onEditProfit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
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
          // معلومات الطلب الرئيسية
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
                    const SizedBox(height: 2),
                    Text(
                      productDisplay,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.total.toInt()} د.ع',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  if (isAdmin)
                    Text(
                      'ربح: ${order.profit.toInt()} د.ع',
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                    ),
                  Text(
                    order.agentName,
                    style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // التاريخ والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: isAdmin ? onEditDate : null,
                child: Text(
                  '📅 ${displayDate ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: onStatusTap,
                child: StatusBadge(
                  status: order.status,
                  isClickable: true,
                ),
              ),
            ],
          ),
          // الملاحظة
          if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => _showFullNote(context),
                child: Row(
                  children: [
                    const Icon(Icons.message, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.adminNotes!.length > 50
                            ? '${order.adminNotes!.substring(0, 50)}...'
                            : order.adminNotes!,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // ✅ عرض الرقم التسلسلي أسفل الملاحظات (اختياري - للتوضيح)
          if (order.localSerial != null && order.localSerial! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'الرقم التسلسلي للمندوب: ${order.localSerial}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

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