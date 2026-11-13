// lib/widgets/programmer_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'celebrations.dart';
import 'toast_message.dart';

class ProgrammerInfoDialog {
  static void show(BuildContext context) {
    CelebrationEffect.showBalloonsAndFlowers(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.code, size: 40, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),
              const Text(
                '👨‍💻 المهندس حيدر',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 8),
              const Text(
                'مطور ومصمم النظام',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _InfoRow(
                icon: Icons.person,
                label: 'الاسم الكامل',
                value: 'حيدر علي',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.phone,
                label: 'رقم الهاتف',
                value: '07813824203',
                color: const Color(0xFF34D399),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '07813824203'));
                  ToastMessage.show(context, '✅ تم نسخ الرقم');
                },
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.email,
                label: 'البريد الإلكتروني',
                value: 'haider171700@gmail.com',
                color: const Color(0xFFF472B6),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'haider171700@gmail.com'));
                  ToastMessage.show(context, '✅ تم نسخ البريد');
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '✨ سمايل كوزمتك والبضائع العالمية ✨',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '© 2026 جميع الحقوق محفوظة',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            if (onTap != null)
              const Spacer(),
            if (onTap != null)
              const Icon(Icons.copy, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
