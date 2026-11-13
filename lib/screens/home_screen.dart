// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'admin/admin_dashboard.dart';
import 'agent/agent_dashboard.dart';
import 'login_screen.dart';
import '../themes/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // رقم الهاتف الأول - قابل للنسخ
            GestureDetector(
              onTap: () => _copyToClipboard(context, '07813824203', 'رقم الهاتف 1'),
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
                    const Text(
                      'الهاتف 1: ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '07813824203',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // رقم الهاتف الثاني - قابل للنسخ
            GestureDetector(
              onTap: () => _copyToClipboard(context, '07740193972', 'رقم الهاتف 2'),
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
                    const Text(
                      'الهاتف 2: ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '07740193972',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                  ],
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // التحقق من حالة التحميل
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }

        // عرض لوحة التحكم المناسبة حسب نوع المستخدم
        Widget dashboard;
        if (authProvider.isAdmin) {
          dashboard = const AdminDashboard();
        } else if (authProvider.isAgentMode && authProvider.currentAgent != null) {
          dashboard = const AgentDashboard();
        } else {
          return const LoginScreen();
        }

        // ✅ إضافة Drawer للقائمة الجانبية مع زر المطور
        return Scaffold(
          drawer: Drawer(
            backgroundColor: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Header القائمة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.store, size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        authProvider.isAdmin ? 'لوحة المدير' : 'لوحة المندوب',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        authProvider.currentAgent?.agentName ?? 'سمايل كوزمتك',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // عناصر القائمة
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ✅ زر المطور في القائمة الجانبية
                      ListTile(
                        leading: const Icon(Icons.code, color: Colors.grey),
                        title: const Text('👨‍💻 المطور', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context); // إغلاق القائمة
                          _showDeveloperInfo(context);
                        },
                      ),
                      const Divider(color: Colors.grey),
                      // زر تسجيل الخروج
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
                        onTap: () async {
                          Navigator.pop(context); // إغلاق القائمة
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
                              content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(color: Colors.white)),
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
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: dashboard,
        );
      },
    );
  }
}
