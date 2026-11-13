// lib/services/supabase_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/agent.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient? _client;
  
  // ✅ روابط Supabase Edge Functions (بدلاً من Render)
  static const String supabaseFunctionsUrl = 'https://vljbpyfopzlcxwyaxaxl.supabase.co/functions/v1';
  static const String sendOrderUrl = '$supabaseFunctionsUrl/send-order-to-jenni';
  static const String updateShipmentStatusUrl = '$supabaseFunctionsUrl/update-shipment-status';
  // ✅ تم تصحيح الرابط: استخدام send-order-to-jenni بدلاً من cancel-shipment
  static const String cancelShipmentUrl = '$supabaseFunctionsUrl/send-order-to-jenni';
  static const String settleAgentUrl = '$supabaseFunctionsUrl/settle-agent';
  static const String syncWithJenniUrl = '$supabaseFunctionsUrl/sync-with-jenni';
  static const String getGovernoratesUrl = '$supabaseFunctionsUrl/get-governorates';
  
  // رابط API الخاص بنظام الزعيم الرئيسي (Jenni) - يبقى كما هو
  static const String jenniBaseUrl = 'https://jenni.alzaeemexp.com/api';
  
  // ✅ منع التكرار على مستوى الخدمة
  static final Set<String> _processingKeys = {};  // منع تكرار الطلب بنفس البيانات
  static String? _jenniAuthToken;
  static DateTime? _jenniTokenExpiry;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    print("✅ Supabase initialized successfully");
    
    // محاولة تحميل توكن الزعيم من التخزين المحلي
    await _loadJenniToken();
  }
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized');
    }
    return _client!;
  }
  
  // ============== دوال مصادقة نظام الزعيم (Jenni) ==============
  static Future<void> _loadJenniToken() async {
    final prefs = await SharedPreferences.getInstance();
    _jenniAuthToken = prefs.getString('jenni_auth_token');
    final expiryStr = prefs.getString('jenni_token_expiry');
    if (expiryStr != null) {
      _jenniTokenExpiry = DateTime.tryParse(expiryStr);
    }
  }
  
  static Future<void> _saveJenniToken(String token, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jenni_auth_token', token);
    await prefs.setString('jenni_token_expiry', expiry.toIso8601String());
    _jenniAuthToken = token;
    _jenniTokenExpiry = expiry;
  }
  
  Future<bool> loginToJenni(String username, String password) async {
    try {
      print("🔐 محاولة تسجيل الدخول إلى نظام الزعيم...");
      
      final response = await http.post(
        Uri.parse('$jenniBaseUrl/v2/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final token = result['token'];
        final expiresIn = result['expires_in'] ?? 86400; // 24 ساعة افتراضياً
        
        if (token != null) {
          final expiry = DateTime.now().add(Duration(seconds: expiresIn));
          await _saveJenniToken(token, expiry);
          print("✅ تم تسجيل الدخول إلى نظام الزعيم بنجاح");
          return true;
        }
      }
      
      print("❌ فشل تسجيل الدخول إلى نظام الزعيم: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ خطأ في تسجيل الدخول إلى نظام الزعيم: $e");
      return false;
    }
  }
  
  Future<String?> _getValidJenniToken() async {
    // التحقق من صحة التوكن
    if (_jenniAuthToken != null && _jenniTokenExpiry != null) {
      if (DateTime.now().isBefore(_jenniTokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return _jenniAuthToken;
      }
    }
    
    // إذا انتهى التوكن، نحاول تجديده
    print("⚠️ توكن نظام الزعيم منتهي أو غير موجود، يرجى تسجيل الدخول مرة أخرى");
    return null;
  }
  
  // ============== ✅ دالة جلب الرقم التسلسلي التالي للمندوب ==============
  Future<int> getNextSerialForAgent(String agentName) async {
    try {
      print("📊 جلب الرقم التسلسلي التالي للمندوب: $agentName");
      
      final result = await client.from('orders')
          .select('local_serial')
          .eq('agent_name', agentName)
          .order('local_serial', ascending: false)
          .limit(1);
      
      int maxSerial = 0;
      if (result.isNotEmpty && result[0]['local_serial'] != null) {
        maxSerial = result[0]['local_serial'] as int;
      }
      
      final nextSerial = maxSerial + 1;
      print("📊 الرقم التسلسلي الجديد: $nextSerial");
      return nextSerial;
    } catch (e) {
      print("❌ خطأ في جلب الرقم التسلسلي: $e");
      return 1;
    }
  }
  
  // ============== ✅ إرسال الطلب عبر Supabase Edge Function ==============
  Future<Map<String, dynamic>?> sendOrderToJenni(Order order) async {
    if (order.jenniShipmentId != null && order.jenniShipmentId!.isNotEmpty) {
      print("⚠️ الطلب تم إرساله مسبقاً إلى الزعيم");
      return null;
    }
    
    try {
      final Map<String, dynamic> orderData = {
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'customer_address': order.customerAddress,
        'product': order.product,
        'product_info': order.productInfo,
        'quantity': order.quantity,
        'price': order.price,
        'total': order.price,
        'profit': order.profit,
        'status': order.status,
        'agent_name': order.agentName,
        'order_date': order.orderDate ?? DateTime.now().toIso8601String().split('T')[0],
        'admin_notes': order.adminNotes ?? '',
        'governorate': order.governorate ?? 'بغداد',
        'district': order.district ?? '',
        'landmark': order.landmark ?? '',
        'local_serial': order.localSerial ?? 0,
      };
      
      print("📤 محاولة إرسال الطلب إلى نظام الزعيم عبر Edge Function...");
      print("📡 الرابط: $sendOrderUrl");
      print("📦 المنتج: ${order.product}");
      print("💰 سعر القطعة: ${order.price}");
      print("🔢 الكمية: ${order.quantity}");
      
      final response = await http.post(
        Uri.parse(sendOrderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      ).timeout(const Duration(seconds: 30));
      
      print("📡 رد الخادم: ${response.statusCode}");
      print("📡 جسم الرد: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تم إرسال الطلب إلى نظام الزعيم بنجاح عبر Edge Function");
          return result['data'];
        } else {
          print("⚠️ نظام الزعيم رد بفشل: ${result['error']}");
          return null;
        }
      }
      
      print("⚠️ فشل إرسال الطلب إلى الزعيم: ${response.statusCode}");
      return null;
    } catch (e) {
      print("❌ خطأ في إرسال الطلب إلى الزعيم: $e");
      return null;
    }
  }
  
  // ============== ✅ إرسال تحديث حالة الطلب إلى نظام الزعيم (عبر Edge Function) ==============
  Future<bool> updateShipmentStatusToJenni({
    required String shipmentId,
    required String actionCode,
    String? postponedReason,
    int? postponedDateId,
    String? returnReason,
    String? note,
    double? newAmount,
  }) async {
    try {
      // الحصول على توكن صالح
      final token = await _getValidJenniToken();
      if (token == null) {
        print("❌ لا يوجد توكن صالح لنظام الزعيم، يرجى تسجيل الدخول أولاً");
        return false;
      }
      
      print("📤 محاولة إرسال تحديث حالة إلى نظام الزعيم عبر Edge Function...");
      print("📦 shipment_id: $shipmentId");
      print("🎯 action_code: $actionCode");
      
      final Map<String, dynamic> updateData = {
        "shipment_id": int.parse(shipmentId),
        "action": actionCode,
      };
      
      // إضافة حقول التأجيل
      if (actionCode == "POSTPONED" || actionCode == "POSTPONEMENT_APPROVED") {
        if (postponedReason != null && postponedReason.isNotEmpty) {
          updateData["postponed_reason"] = postponedReason;
          updateData["postponed_reason_en"] = _translatePostponedReasonEn(postponedReason);
          updateData["postponed_reason_ku"] = _translatePostponedReasonKu(postponedReason);
        }
        if (postponedDateId != null) {
          updateData["postponed_date_id"] = postponedDateId;
        }
      }
      
      // إضافة حقول الإرجاع
      if (actionCode == "RETURN_TO_STORE" || actionCode == "RETURNED_WITH_AGENT" || actionCode == "RETURN_APPROVED") {
        if (returnReason != null && returnReason.isNotEmpty) {
          updateData["return_reason"] = returnReason;
          updateData["return_reason_en"] = _translateReturnReasonEn(returnReason);
          updateData["return_reason_ku"] = _translateReturnReasonKu(returnReason);
        }
      }
      
      // إضافة حقول تغيير السعر
      if (actionCode == "SUCCESSFUL_DELIVERY_WITH_AMOUNT_CHANGE" && newAmount != null) {
        updateData["new_amount_iqd"] = newAmount;
      }
      
      if (note != null && note.isNotEmpty) {
        updateData["note"] = note;
      }
      
      print("📦 بيانات التحديث: ${jsonEncode(updateData)}");
      
      final response = await http.post(
        Uri.parse(updateShipmentStatusUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 30));
      
      print("📡 رد تحديث الحالة: ${response.statusCode}");
      print("📡 جسم الرد: ${response.body}");
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تم تحديث حالة الطلب في نظام الزعيم بنجاح");
          return true;
        } else {
          print("⚠️ فشل تحديث الحالة: ${result['message']}");
        }
      } else if (response.statusCode == 401) {
        print("⚠️ توكن غير صالح، يرجى تسجيل الدخول مرة أخرى");
      }
      
      return false;
    } catch (e) {
      print("❌ خطأ في تحديث حالة الطلب: $e");
      return false;
    }
  }
  
  // ============== دوال الترجمة للأسباب ==============
  String _translatePostponedReasonEn(String reasonAr) {
    switch (reasonAr) {
      case 'العميل غير موجود':
        return 'Customer not available';
      case 'العميل مشغول':
        return 'Customer busy';
      case 'مسافر':
        return 'Traveling';
      case 'تم التأجيل لرغبة الزبون':
        return 'Customer requested postponement';
      case 'الزبون لا يرد':
        return 'Customer not answering';
      default:
        return reasonAr;
    }
  }
  
  String _translatePostponedReasonKu(String reasonAr) {
    switch (reasonAr) {
      case 'العميل غير موجود':
        return 'کڕیار بەردەست نییە';
      case 'العميل مشغول':
        return 'کڕیار سەرقاڵە';
      case 'مسافر':
        return 'گەشت دەکات';
      case 'تم التأجيل لرغبة الزبون':
        return 'کڕیار داوای دواخستنی کردووە';
      case 'الزبون لا يرد':
        return 'کڕیار وەڵام نامێنێتەوە';
      default:
        return reasonAr;
    }
  }
  
  String _translateReturnReasonEn(String reasonAr) {
    switch (reasonAr) {
      case 'رفض الاستلام':
        return 'Customer refused';
      case 'العنوان خاطئ':
        return 'Wrong address';
      case 'المنتج تالف':
        return 'Product damaged';
      case 'القياس ليس المطلوب':
        return 'Wrong size';
      case 'البضاعة ليست هي المطلوبة':
        return 'Wrong item';
      default:
        return reasonAr;
    }
  }
  
  String _translateReturnReasonKu(String reasonAr) {
    switch (reasonAr) {
      case 'رفض الاستلام':
        return 'کڕیار ڕەتکردەوە';
      case 'العنوان خاطئ':
        return 'ناونیشان هەڵەیە';
      case 'المنتج تالف':
        return 'بەرهەمەکە زیان پێگەیشتووە';
      case 'القياس ليس المطلوب':
        return 'قەبارەکە هەڵەیە';
      case 'البضاعة ليست هي المطلوبة':
        return 'بەرهەمەکە هەڵەیە';
      default:
        return reasonAr;
    }
  }
  
  // ============== ✅ إلغاء طلب في نظام الزعيم (عبر Edge Function) ==============
  Future<bool> cancelInJenni(String shipmentNumber, {String reason = 'تم إلغاء الطلب'}) async {
    try {
      print("📝 محاولة إلغاء الطلب $shipmentNumber في نظام الزعيم عبر Edge Function...");
      
      // ✅ تم تصحيح الرابط: استخدام DELETE مع send-order-to-jenni
      final response = await http.delete(
        Uri.parse('$cancelShipmentUrl/$shipmentNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 30));
      
      print("📡 رد الإلغاء: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تم إلغاء الطلب في نظام الزعيم: ${result['message']}");
          return true;
        }
      }
      return false;
    } catch (e) {
      print("❌ خطأ في إلغاء الطلب: $e");
      return false;
    }
  }
  
  // ============== ✅ حذف طلب من نظام الزعيم (عبر Edge Function) ==============
  Future<bool> deleteShipmentFromJenni(String shipmentNumber) async {
    try {
      print("🗑️ محاولة حذف الطلب $shipmentNumber من نظام الزعيم عبر Edge Function...");
      
      // ✅ تم تصحيح الرابط: استخدام DELETE مع send-order-to-jenni
      final response = await http.delete(
        Uri.parse('$cancelShipmentUrl/$shipmentNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      print("📡 رد الحذف من الزعيم: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تم حذف/إلغاء الطلب من نظام الزعيم: ${result['message']}");
          return true;
        }
      } else if (response.statusCode == 404) {
        print("ℹ️ الطلب غير موجود في نظام الزعيم (ربما تم حذفه مسبقاً)");
        return true;
      }
      print("⚠️ فشل حذف الطلب من الزعيم: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ خطأ في حذف الطلب من الزعيم: $e");
      return false;
    }
  }
  
  // ============== ✅ تسديد أرباح المندوب (عبر Edge Function) ==============
  Future<bool> settleAgent(String agentId, double paidAmount) async {
    try {
      print("💰 محاولة تسديد أرباح المندوب $agentId عبر Edge Function...");
      
      final response = await http.post(
        Uri.parse('$settleAgentUrl/$agentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'paid_amount': paidAmount}),
      ).timeout(const Duration(seconds: 30));
      
      print("📡 رد التسديد: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تم تسديد أرباح المندوب: ${result['message']}");
          return true;
        }
      }
      return false;
    } catch (e) {
      print("❌ خطأ في تسديد الأرباح: $e");
      return false;
    }
  }
  
  // ============== ✅ حذف الطلبات الواصلة فقط للمندوب دفعة واحدة ==============
  Future<int> deleteAgentDeliveredOrders(String agentName) async {
    try {
      print("🗑️ بدء حذف الطلبات الواصلة للمندوب $agentName دفعة واحدة...");
      
      final response = await client
          .from('orders')
          .delete()
          .eq('agent_name', agentName)
          .eq('status', 'واصل')
          .select();
      
      final deletedCount = response.length;
      print("✅ تم حذف $deletedCount طلب واصل للمندوب $agentName دفعة واحدة");
      return deletedCount;
    } catch (e) {
      print("❌ خطأ في حذف طلبات المندوب: $e");
      return 0;
    }
  }
  
  // ============== ✅ مزامنة مع نظام الزعيم (عبر Edge Function) ==============
  Future<bool> syncWithJenni() async {
    try {
      print("🔄 بدء مزامنة يدوية مع نظام الزعيم عبر Edge Function...");
      
      final response = await http.post(
        Uri.parse(syncWithJenniUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));
      
      print("📡 رد المزامنة: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print("✅ تمت المزامنة بنجاح: ${result['message']}");
          return true;
        }
      }
      return false;
    } catch (e) {
      print("❌ خطأ في المزامنة: $e");
      return false;
    }
  }
  
  // ============== ✅ جلب المحافظات (عبر Edge Function) ==============
  Future<List<String>> getGovernorates() async {
    try {
      print("📍 جلب المحافظات عبر Edge Function...");
      
      final response = await http.get(
        Uri.parse(getGovernoratesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          return data.map((e) => e.toString()).toList();
        }
      }
      print("⚠️ فشل جلب المحافظات، استخدام القائمة المحلية");
      return AppConstants.fallbackGovernorates;
    } catch (e) {
      print("⚠️ فشل جلب المحافظات، استخدام القائمة المحلية: $e");
      return AppConstants.fallbackGovernorates;
    }
  }
  
  // ============== Orders ==============
  Future<List<Order>> getOrders() async {
    try {
      print("🔍 [Supabase] جاري جلب جميع الطلبات من قاعدة البيانات...");
      
      List<Order> allOrders = [];
      int from = 0;
      int batchSize = 1000;
      bool hasMore = true;
      
      while (hasMore) {
        final response = await client.from('orders')
            .select('*')
            .order('created_at', ascending: false)
            .range(from, from + batchSize - 1);
        
        if (response.isEmpty) {
          hasMore = false;
        } else {
          allOrders.addAll(response.map<Order>((json) => Order.fromJson(json)).toList());
          from += batchSize;
          print("✅ [Supabase] تم جلب ${allOrders.length} طلب حتى الآن...");
        }
      }
      
      print("✅ [Supabase] اكتمل الجلب! إجمالي الطلبات: ${allOrders.length}");
      return allOrders;
    } catch (e) {
      print("❌ Error getting orders: $e");
      return [];
    }
  }
  
  Stream<List<Order>> streamOrders() {
    return client.from('orders')
        .stream(primaryKey: ['__backendId'])
        .map((data) {
      return data.map<Order>((json) => Order.fromJson(json)).toList();
    });
  }
  
  // ============== ✅ إنشاء طلب جديد (يمنع التكرار تماماً) ==============
  Future<Order?> createOrder(Order order) async {
    // ✅ 1. منع التكرار على مستوى البيانات
    final uniqueKey = '${order.customerName}_${order.customerPhone}_${order.product}_${order.price}';
    
    if (_processingKeys.contains(uniqueKey)) {
      print("🚫 تم منع الطلب المكرر (نفس البيانات)");
      return null;
    }
    
    _processingKeys.add(uniqueKey);
    
    // ✅ 2. التأكد من عدم وجود نفس الطلب محفوظ مسبقاً خلال آخر 5 ثواني
    final prefs = await SharedPreferences.getInstance();
    final lastOrderKey = 'last_order_${order.customerPhone}_${order.agentName}';
    final lastOrderTime = prefs.getInt(lastOrderKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - lastOrderTime < 5000) {
      print("🚫 تم منع الطلب المكرر (نفس المندوب خلال 5 ثوان)");
      _processingKeys.remove(uniqueKey);
      return null;
    }
    
    await prefs.setInt(lastOrderKey, now);
    
    try {
      final nowDate = DateTime.now();
      
      // ✅ 3. جلب الرقم التسلسلي
      final nextSerial = await getNextSerialForAgent(order.agentName);
      print("📊 الرقم التسلسلي المتوقع: $nextSerial");
      
      // ✅ 4. إنشاء الطلب للإرسال إلى الزعيم
      final newOrder = Order(
        backendId: null,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        product: order.product,
        productInfo: order.productInfo,
        quantity: order.quantity,
        price: order.price,
        total: order.price,
        profit: order.profit,
        status: order.status,
        agentName: order.agentName,
        orderDate: order.orderDate ?? nowDate.toIso8601String().split('T')[0],
        adminNotes: order.adminNotes,
        governorate: order.governorate,
        district: order.district,
        landmark: order.landmark,
        localSerial: nextSerial,
        createdAt: nowDate,
        updatedAt: nowDate,
      );
      
      // ✅ 5. إرسال إلى نظام الزعيم عبر Edge Function
      print("🚀 بدء إرسال الطلب إلى نظام الزعيم عبر Edge Function...");
      final jenniResult = await sendOrderToJenni(newOrder);
      
      if (jenniResult != null && jenniResult['__backendId'] != null) {
        print("✅ تم إرسال الطلب إلى نظام الزعيم بنجاح، جاري استرجاع الطلب...");
        
        final backendId = jenniResult['__backendId'];
        final savedOrder = await client.from('orders')
            .select()
            .eq('__backendId', backendId)
            .maybeSingle();
        
        if (savedOrder != null) {
          final createdOrder = Order.fromJson(savedOrder);
          print("✅ تم استرجاع الطلب المحفوظ: ${createdOrder.backendId} (الرقم التسلسلي: ${createdOrder.localSerial})");
          _processingKeys.remove(uniqueKey);
          return createdOrder;
        }
      }
      
      // ✅ 6. إذا فشل الإرسال إلى الزعيم، نحفظ محلياً
      print("⚠️ فشل الإرسال إلى الزعيم أو لم يتم حفظه، جاري الحفظ محلياً...");
      
      final backendId = DateTime.now().millisecondsSinceEpoch.toString();
      final localOrder = newOrder.copyWith(backendId: backendId);
      
      final response = await client.from('orders')
          .insert(localOrder.toJson())
          .select()
          .single();
      
      final createdOrder = Order.fromJson(response);
      print("✅ تم حفظ الطلب محلياً: ${createdOrder.backendId} (الرقم التسلسلي: ${createdOrder.localSerial})");
      
      _processingKeys.remove(uniqueKey);
      return createdOrder;
      
    } catch (e) {
      print("❌ فشل حفظ الطلب: $e");
      _processingKeys.remove(uniqueKey);
      return null;
    }
  }
  
  Future<Order?> updateOrder(Order order) async {
    if (order.backendId == null) return null;
    
    try {
      final updatedOrder = order.copyWith(updatedAt: DateTime.now());
      final response = await client.from('orders')
          .update(updatedOrder.toJson())
          .eq('__backendId', order.backendId!)
          .select()
          .single();
      return Order.fromJson(response);
    } catch (e) {
      print("❌ Error updating order: $e");
      return null;
    }
  }
  
  // ============== حذف الطلب ==============
  Future<bool> deleteOrder(String backendId) async {
    try {
      print("🗑️ بدء عملية حذف الطلب $backendId...");
      
      // ✅ محاولة حذف من نظام الزعيم (إذا كان له shipment_id)
      final order = await client.from('orders')
          .select('jenni_shipment_id')
          .eq('__backendId', backendId)
          .maybeSingle();
      
      if (order != null && order['jenni_shipment_id'] != null) {
        final jenniId = order['jenni_shipment_id'].toString();
        if (jenniId.isNotEmpty && jenniId != 'null') {
          print("🗑️ حذف من نظام الزعيم: $jenniId");
          await deleteShipmentFromJenni(jenniId);
        }
      }
      
      // ✅ حذف من Supabase
      await client.from('orders').delete().eq('__backendId', backendId);
      
      print("✅ تم حذف الطلب $backendId");
      return true;
    } catch (e) {
      print("❌ Error deleting order: $e");
      return false;
    }
  }
  
  // ============== Agents ==============
  Future<List<Agent>> getAgents() async {
    try {
      final response = await client.from('agents')
          .select('*')
          .order('created_at', ascending: false);
      return response.map<Agent>((json) => Agent.fromJson(json)).toList();
    } catch (e) {
      print("❌ Error getting agents: $e");
      return [];
    }
  }
  
  Stream<List<Agent>> streamAgents() {
    return client.from('agents')
        .stream(primaryKey: ['__backendId'])
        .map((data) {
      return data.map<Agent>((json) => Agent.fromJson(json)).toList();
    });
  }
  
  Future<Agent?> createAgent(Agent agent) async {
    try {
      final now = DateTime.now();
      final newAgent = Agent(
        backendId: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'agent',
        agentName: agent.agentName,
        agentPhone: agent.agentPhone,
        agentCode: agent.agentCode,
        agentPassword: agent.agentPassword,
        agentProfitPerOrder: agent.agentProfitPerOrder,
        lastSerial: 0,
        createdAt: now,
        updatedAt: now,
      );
      
      final response = await client.from('agents')
          .insert(newAgent.toJson())
          .select()
          .single();
      return Agent.fromJson(response);
    } catch (e) {
      print("❌ Error creating agent: $e");
      return null;
    }
  }
  
  Future<Agent?> updateAgent(Agent agent) async {
    if (agent.backendId == null) return null;
    
    try {
      final updatedAgent = agent.copyWith(updatedAt: DateTime.now());
      final response = await client.from('agents')
          .update(updatedAgent.toJson())
          .eq('__backendId', agent.backendId!)
          .select()
          .single();
      return Agent.fromJson(response);
    } catch (e) {
      print("❌ Error updating agent: $e");
      return null;
    }
  }
  
  Future<bool> deleteAgent(String backendId) async {
    try {
      await client.from('agents').delete().eq('__backendId', backendId);
      return true;
    } catch (e) {
      print("❌ Error deleting agent: $e");
      return false;
    }
  }
  
  Future<Agent?> getAgentByCredentials(String username, String password) async {
    try {
      final response = await client.from('agents')
          .select()
          .eq('agent_code', username)
          .eq('agent_password', password)
          .maybeSingle();
      if (response == null) return null;
      return Agent.fromJson(response);
    } catch (e) {
      print("❌ Error getting agent by credentials: $e");
      return null;
    }
  }

  // ============== Products (المخزن) ==============
  Future<List<Product>> getProducts() async {
    try {
      print("🔍 [Supabase] جاري جلب المنتجات من المخزن...");
      
      final response = await client.from('products')
          .select('*')
          .order('name', ascending: true);
      
      final products = response.map<Product>((json) => Product.fromJson(json)).toList();
      print("✅ [Supabase] تم جلب ${products.length} منتج");
      return products;
    } catch (e) {
      print("❌ Error getting products: $e");
      return [];
    }
  }
  
  Stream<List<Product>> streamProducts() {
    return client.from('products')
        .stream(primaryKey: ['__backendId'])
        .map((data) {
      return data.map<Product>((json) => Product.fromJson(json)).toList();
    });
  }
  
  Future<Product?> createProduct(Product product) async {
    try {
      final now = DateTime.now();
      final newProduct = Product(
        backendId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: product.name,
        description: product.description,
        quantity: product.quantity,
        category: product.category,
        createdAt: now,
        updatedAt: now,
      );
      
      final response = await client.from('products')
          .insert(newProduct.toJson())
          .select()
          .single();
      return Product.fromJson(response);
    } catch (e) {
      print("❌ Error creating product: $e");
      return null;
    }
  }
  
  Future<Product?> updateProduct(Product product) async {
    if (product.backendId == null) return null;
    
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      final response = await client.from('products')
          .update(updatedProduct.toJson())
          .eq('__backendId', product.backendId!)
          .select()
          .single();
      return Product.fromJson(response);
    } catch (e) {
      print("❌ Error updating product: $e");
      return null;
    }
  }
  
  Future<bool> deleteProduct(String backendId) async {
    try {
      await client.from('products').delete().eq('__backendId', backendId);
      print("✅ تم حذف المنتج $backendId");
      return true;
    } catch (e) {
      print("❌ Error deleting product: $e");
      return false;
    }
  }
  
  // تحديث كمية المنتج بعد الطلب
  Future<bool> updateProductQuantity(String productId, int newQuantity) async {
    try {
      await client.from('products')
          .update({'quantity': newQuantity, 'updated_at': DateTime.now().toIso8601String()})
          .eq('__backendId', productId);
      print("✅ تم تحديث كمية المنتج إلى $newQuantity");
      return true;
    } catch (e) {
      print("❌ Error updating product quantity: $e");
      return false;
    }
  }
}