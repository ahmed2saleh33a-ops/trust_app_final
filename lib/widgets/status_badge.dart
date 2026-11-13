// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../themes/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isClickable;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.status,
    this.isClickable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Order.getStatusColor(status);
    
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Order.getStatusIcon(status),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}