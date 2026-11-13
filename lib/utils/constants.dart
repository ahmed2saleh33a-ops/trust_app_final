// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // Supabase - Anon Key (للاستخدام العام)
  static const String supabaseUrl = 'https://vljbpyfopzlcxwyaxaxl.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_AgJGqyhSjrmS4rt8cv5WJg_XvkbzNyg';
  
  // إعدادات النظام
  static const double defaultAgentProfit = 1000.0;
  static const String adminUsername = 'admin';
  static const String adminPassword = 'Ahmed1234321';  // ✅ تم التصحيح
  
  // ✅ قائمة حالات الطلبات (بدون مصفى)
  static const List<String> orderStatuses = ['جديد', 'قيد التوصيل', 'واصل', 'راجع', 'ملغي', 'مؤجل'];
  
  // ألوان الحالات
  static const Map<String, Color> statusColors = {
    'جديد': Color(0xFF1E3A5F),
    'قيد التوصيل': Color(0xFF78350F),
    'واصل': Color(0xFF065F46),
    'راجع': Color(0xFF7F1D1D),
    'ملغي': Color(0xFF4A044E),
    'مؤجل': Color(0xFFB45309),  // ✅ لون برتقالي غامق
  };
  
  static const Map<String, Color> statusTextColors = {
    'جديد': Color(0xFF93C5FD),
    'قيد التوصيل': Color(0xFFFCD34D),
    'واصل': Color(0xFF6EE7B7),
    'راجع': Color(0xFFFCA5A5),
    'ملغي': Color(0xFFD8B4FE),
    'مؤجل': Color(0xFFFDE68A),  // ✅ لون أصفر فاتح
  };
  
  // ✅ قائمة المحافظات الاحتياطية (تمت إضافة السليمانية ودهوك)
  static const List<String> fallbackGovernorates = [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كركوك',
    'الأنبار', 'كربلاء', 'ذي قار', 'ميسان', 'بابل', 'واسط',
    'صلاح الدين', 'ديالى', 'المثنى', 'القادسية',
    'السليمانية', 'دهوك'  // ✅ تمت الإضافة
  ];
  
  // أسماء الجداول في Supabase
  static const String tableOrders = 'orders';
  static const String tableAgents = 'agents';
  static const String tableNotifications = 'notifications';
  static const String tableFcmTokens = 'fcm_tokens';
  static const String tableProducts = 'products';  // ✅ إضافة جدول المنتجات
}