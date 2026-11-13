// lib/providers/data_provider.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/agent.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  List<Order> _allOrdersRaw = [];
  List<Order> _allOrders = [];
  List<Agent> _allAgents = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String? _error;
  String? _currentAgentName;
  bool _isAgentMode = false;
  Timer? _autoRefreshTimer;
  
  // ✅ متغيرات لمنع التكرار
  bool _isCreatingOrder = false;
  bool _isUpdatingOrder = false;
  bool _isDeletingOrder = false;
  
  List<Order> get allOrders => _allOrders;
  List<Agent> get allAgents => _allAgents;
  List<Product> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAgentMode => _isAgentMode;
  String? get currentAgentName => _currentAgentName;
  List<Order> get allOrdersRaw => _allOrdersRaw;
  
  DataProvider() {
    _startAutoRefresh();
    loadData();
  }
  
  // ✅ بدء التحديث التلقائي في الخلفية (بدون ظهور دائرة تحميل)
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadDataInBackground();
    });
  }
  
  // ✅ تحميل البيانات في الخلفية (بدون تغيير حالة التحميل)
  Future<void> _loadDataInBackground() async {
    try {
      final supabaseService = SupabaseService();
      final ordersFuture = supabaseService.getOrders();
      final agentsFuture = supabaseService.getAgents();
      final productsFuture = supabaseService.getProducts();
      
      final results = await Future.wait([ordersFuture, agentsFuture, productsFuture]);
      
      // ✅ منع التكرار: استخدام Set للتأكد من عدم وجود تكرار في البيانات
      final uniqueOrders = <String, Order>{};
      for (final order in results[0] as List<Order>) {
        if (order.backendId != null) {
          uniqueOrders[order.backendId!] = order;
        }
      }
      _allOrdersRaw = uniqueOrders.values.toList();
      
      _allAgents = results[1] as List<Agent>;
      _allProducts = results[2] as List<Product>;
      _error = null;
      
      // ✅ ترتيب الطلبات من الأحدث إلى الأقدم
      _allOrdersRaw.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _applyFilter();
    } catch (e) {
      print("❌ خطأ في التحديث الخلفي: $e");
    }
  }
  
  void setUserMode(bool isAgentMode, {String? agentName}) {
    _isAgentMode = isAgentMode;
    _currentAgentName = agentName;
    _applyFilter();
  }
  
  // ============== ✅ دالة التصفية الرئيسية (معدلة) ==============
  void _applyFilter() {
    if (_isAgentMode && _currentAgentName != null && _currentAgentName!.isNotEmpty) {
      // ✅ تصفية طلبات المندوب الحالي فقط
      _allOrders = _allOrdersRaw
          .where((order) => 
              order.agentName.trim() == _currentAgentName!.trim() &&
              order.status != 'مصفى' &&
              order.backendId != null)
          .toList();
    } else {
      // ✅ للمدير: عرض جميع الطلبات
      _allOrders = _allOrdersRaw
          .where((order) => order.backendId != null)
          .toList();
    }
    
    // ✅ ترتيب الطلبات من الأحدث إلى الأقدم
    _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
  
  void setCurrentAgent(String agentName) {
    _currentAgentName = agentName;
    _isAgentMode = true;
    _applyFilter();
  }
  
  List<Order> getAgentOrders() {
    if (_currentAgentName == null || _currentAgentName!.isEmpty) {
      return [];
    }
    return _allOrdersRaw.where((o) => o.agentName == _currentAgentName).toList();
  }
  
  List<Order> getAllOrders() {
    return _allOrdersRaw;
  }
  
  // ✅ تحديث يدوي (مع ظهور دائرة تحميل فقط عند الطلب)
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final supabaseService = SupabaseService();
      final ordersFuture = supabaseService.getOrders();
      final agentsFuture = supabaseService.getAgents();
      final productsFuture = supabaseService.getProducts();
      
      final results = await Future.wait([ordersFuture, agentsFuture, productsFuture]);
      
      // ✅ منع التكرار
      final uniqueOrders = <String, Order>{};
      for (final order in results[0] as List<Order>) {
        if (order.backendId != null) {
          uniqueOrders[order.backendId!] = order;
        }
      }
      _allOrdersRaw = uniqueOrders.values.toList();
      
      _allAgents = results[1] as List<Agent>;
      _allProducts = results[2] as List<Product>;
      _error = null;
      
      // ✅ ترتيب الطلبات
      _allOrdersRaw.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _applyFilter();
    } catch (e) {
      _error = e.toString();
      print("❌ خطأ في تحميل البيانات: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // ✅ تحميل البيانات الأولية (مع ظهور دائرة تحميل)
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final supabaseService = SupabaseService();
      final ordersFuture = supabaseService.getOrders();
      final agentsFuture = supabaseService.getAgents();
      final productsFuture = supabaseService.getProducts();
      
      final results = await Future.wait([ordersFuture, agentsFuture, productsFuture]);
      
      // ✅ منع التكرار: استخدام Map للتأكد من عدم وجود تكرار في البيانات
      final uniqueOrders = <String, Order>{};
      for (final order in results[0] as List<Order>) {
        if (order.backendId != null) {
          uniqueOrders[order.backendId!] = order;
        }
      }
      _allOrdersRaw = uniqueOrders.values.toList();
      
      _allAgents = results[1] as List<Agent>;
      _allProducts = results[2] as List<Product>;
      _error = null;
      
      // ✅ ترتيب الطلبات من الأحدث إلى الأقدم
      _allOrdersRaw.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _applyFilter();
    } catch (e) {
      _error = e.toString();
      print("❌ خطأ في تحميل البيانات: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // ✅ إنشاء طلب جديد (مع منع التكرار)
  Future<bool> createOrder(Order order) async {
    // ✅ منع التكرار على مستوى DataProvider
    if (_isCreatingOrder) {
      print("⚠️ DataProvider: جاري إنشاء طلب بالفعل، تم تجاهل الطلب المكرر");
      return false;
    }
    
    _isCreatingOrder = true;
    print("📝 DataProvider: بدء إنشاء طلب جديد للعميل ${order.customerName}");
    
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.createOrder(order);
      if (result != null) {
        await _loadDataInBackground();
        print("✅ DataProvider: تم إنشاء الطلب بنجاح");
        return true;
      }
      print("❌ DataProvider: فشل في إنشاء الطلب");
      return false;
    } catch (e) {
      print("❌ خطأ في إنشاء الطلب: $e");
      return false;
    } finally {
      _isCreatingOrder = false;
    }
  }
  
  Future<bool> updateOrder(Order order) async {
    if (_isUpdatingOrder) {
      print("⚠️ DataProvider: جاري تحديث طلب بالفعل، تم التجاهل");
      return false;
    }
    
    _isUpdatingOrder = true;
    
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.updateOrder(order);
      if (result != null) {
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في تحديث الطلب: $e");
      return false;
    } finally {
      _isUpdatingOrder = false;
    }
  }
  
  // ✅ حذف الطلب (مع إرجاع الكمية إلى المخزن إذا كان الطلب جديداً)
  Future<bool> deleteOrder(String id) async {
    if (_isDeletingOrder) {
      print("⚠️ DataProvider: جاري حذف طلب بالفعل، تم التجاهل");
      return false;
    }
    
    _isDeletingOrder = true;
    
    try {
      // ✅ البحث عن الطلب قبل حذفه
      final orderToDelete = _allOrdersRaw.firstWhere(
        (o) => o.backendId == id,
        orElse: () => throw Exception('الطلب غير موجود'),
      );
      
      final supabaseService = SupabaseService();
      
      // ✅ إذا كان الطلب بحالة "جديد"، نعيد الكمية إلى المخزن
      if (orderToDelete.status == 'جديد') {
        print("🔄 الطلب بحالة جديد، جاري إرجاع الكمية إلى المخزن...");
        
        // البحث عن المنتج في المخزن
        final product = _allProducts.firstWhere(
          (p) => p.name == orderToDelete.product,
          orElse: () => throw Exception('المنتج غير موجود'),
        );
        
        // إرجاع الكمية
        final updatedProduct = product.copyWith(
          quantity: product.quantity + orderToDelete.quantity,
          updatedAt: DateTime.now(),
        );
        
        await supabaseService.updateProduct(updatedProduct);
        print("✅ تم إرجاع ${orderToDelete.quantity} قطعة إلى المخزن للمنتج ${product.name}");
      }
      
      // حذف الطلب
      final success = await supabaseService.deleteOrder(id);
      if (success) {
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في حذف الطلب: $e");
      return false;
    } finally {
      _isDeletingOrder = false;
    }
  }
  
  Future<bool> createAgent(Agent agent) async {
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.createAgent(agent);
      if (result != null) {
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في إنشاء المندوب: $e");
      return false;
    }
  }
  
  Future<bool> updateAgent(Agent agent) async {
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.updateAgent(agent);
      if (result != null) {
        // ✅ تحديث اسم المندوب في جميع طلباته
        final agentOrders = _allOrdersRaw.where((o) => o.agentName == agent.agentName).toList();
        for (final order in agentOrders) {
          final updatedOrder = order.copyWith(
            agentName: agent.agentName,
            updatedAt: DateTime.now(),
          );
          await supabaseService.updateOrder(updatedOrder);
        }
        
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في تحديث المندوب: $e");
      return false;
    }
  }
  
  Future<bool> deleteAgent(String id) async {
    try {
      final supabaseService = SupabaseService();
      await supabaseService.deleteAgent(id);
      await _loadDataInBackground();
      return true;
    } catch (e) {
      print("❌ خطأ في حذف المندوب: $e");
      return false;
    }
  }
  
  List<Order> getOrdersForAgent(String agentName) {
    return _allOrdersRaw.where((o) => o.agentName == agentName).toList();
  }
  
  // إحصائيات المدير
  int get totalOrders => _allOrdersRaw.length;
  int get deliveredOrders => _allOrdersRaw.where((o) => o.status == 'واصل').length;
  int get returnedOrders => _allOrdersRaw.where((o) => o.status == 'راجع').length;
  int get cancelledOrders => _allOrdersRaw.where((o) => o.status == 'ملغي').length;
  double get totalSales => _allOrdersRaw
      .where((o) => o.status == 'واصل')
      .fold(0.0, (sum, o) => sum + o.total);
  
  // إحصائيات المندوب
  int getAgentTotalOrders(String agentName) {
    return _allOrdersRaw.where((o) => o.agentName == agentName).length;
  }
  
  int getAgentDeliveredOrders(String agentName) {
    return _allOrdersRaw.where((o) => o.agentName == agentName && o.status == 'واصل').length;
  }
  
  double getAgentTotalProfit(String agentName) {
    return _allOrdersRaw
        .where((o) => o.agentName == agentName && o.status == 'واصل')
        .fold(0.0, (sum, o) => sum + o.profit);
  }
  
  // إلغاء طلب في نظام الزعيم
  Future<bool> cancelOrderInJenni(String shipmentNumber, {String reason = 'تم إلغاء الطلب'}) async {
    try {
      final supabaseService = SupabaseService();
      return await supabaseService.cancelInJenni(shipmentNumber, reason: reason);
    } catch (e) {
      print("❌ خطأ في إلغاء الطلب: $e");
      return false;
    }
  }
  
  // ✅ تسوية حساب المندوب (حذف الطلبات الواصلة فقط دفعة واحدة)
  Future<bool> settleAgent(String agentId, double paidAmount) async {
    try {
      print("💰 بدء تسوية حساب المندوب $agentId...");
      
      final agent = _allAgents.firstWhere((a) => a.backendId == agentId);
      if (agent == null) {
        print("❌ المندوب غير موجود");
        return false;
      }
      
      final supabaseService = SupabaseService();
      
      // ✅ حذف الطلبات الواصلة فقط دفعة واحدة
      final deletedCount = await supabaseService.deleteAgentDeliveredOrders(agent.agentName);
      
      if (deletedCount > 0) {
        print("✅ تم تسوية حساب المندوب ${agent.agentName} (تم حذف $deletedCount طلب واصل دفعة واحدة)");
      } else {
        print("⚠️ لا توجد طلبات واصلة لهذا المندوب");
      }
      
      await _loadDataInBackground();
      
      return true;
    } catch (e) {
      print("❌ خطأ في تسوية الحساب: $e");
      return false;
    }
  }
  
  // ✅ مزامنة يدوية مع نظام الزعيم
  Future<bool> syncWithJenni() async {
    try {
      print("🔄 بدء مزامنة يدوية مع نظام الزعيم...");
      final supabaseService = SupabaseService();
      final success = await supabaseService.syncWithJenni();
      
      if (success) {
        print("✅ تمت المزامنة بنجاح");
        await _loadDataInBackground();
        return true;
      }
      print("❌ فشل المزامنة");
      return false;
    } catch (e) {
      print("❌ خطأ في المزامنة: $e");
      return false;
    }
  }

  // ============== إدارة المخزن (Products) ==============
  Future<bool> createProduct(Product product) async {
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.createProduct(product);
      if (result != null) {
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في إنشاء المنتج: $e");
      return false;
    }
  }
  
  Future<bool> updateProduct(Product product) async {
    try {
      final supabaseService = SupabaseService();
      final result = await supabaseService.updateProduct(product);
      if (result != null) {
        await _loadDataInBackground();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ خطأ في تحديث المنتج: $e");
      return false;
    }
  }
  
  Future<bool> deleteProduct(String id) async {
    try {
      final supabaseService = SupabaseService();
      await supabaseService.deleteProduct(id);
      await _loadDataInBackground();
      return true;
    } catch (e) {
      print("❌ خطأ في حذف المنتج: $e");
      return false;
    }
  }
  
  // الحصول على منتج بالاسم
  Product? getProductByName(String name) {
    try {
      return _allProducts.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }
  
  // التحقق من توفر المنتج
  bool isProductAvailable(String productName, int quantity) {
    final product = getProductByName(productName);
    if (product == null) return false;
    return product.hasStock(quantity);
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}