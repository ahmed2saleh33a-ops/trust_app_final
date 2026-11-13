// lib/screens/admin/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/toast_message.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _commissionType = 'fixed';
  final TextEditingController _commissionValue = TextEditingController(text: '1000');
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _commissionType = prefs.getString('commission_type') ?? 'fixed';
      _commissionValue.text = prefs.getString('commission_value') ?? '1000';
      _isDarkMode = prefs.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('commission_type', _commissionType);
    await prefs.setString('commission_value', _commissionValue.text);
    await prefs.setBool('dark_mode', _isDarkMode);
    ToastMessage.show(context, '✅ تم حفظ الإعدادات');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💰 إعدادات العمولة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _commissionType,
                    decoration: const InputDecoration(
                      labelText: 'نوع العمولة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'percent', child: Text('نسبة مئوية')),
                      DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
                    ],
                    onChanged: (v) => setState(() => _commissionType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commissionValue,
                    decoration: InputDecoration(
                      labelText: 'قيمة العمولة',
                      border: const OutlineInputBorder(),
                      suffixText: _commissionType == 'percent' ? '%' : 'د.ع',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎨 المظهر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('الوضع الليلي'),
                    subtitle: const Text('تغيير مظهر التطبيق'),
                    value: _isDarkMode,
                    onChanged: (v) => setState(() => _isDarkMode = v),
                    secondary: Icon(_isDarkMode ? Icons.nightlight_round : Icons.light_mode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ℹ️ معلومات التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'الإصدار', value: '1.0.0'),
                  _InfoRow(label: 'المطور', value: 'المهندس حيدر علي'),
                  _InfoRow(label: 'البريد الإلكتروني', value: 'haider171700@gmail.com'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('💾 حفظ الإعدادات', style: TextStyle(color: Color(0xFF0F172A))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commissionValue.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
