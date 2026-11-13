// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  Agent? _currentAgent;
  bool _isAgentMode = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isInitialized = false;  // ✅ أضف هذا المتغير

  Agent? get currentAgent => _currentAgent;
  bool get isAgentMode => _isAgentMode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isLoggedIn && !_isAgentMode;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;  // ✅ أضف هذا getter

  // مرجع إلى DataProvider
  dynamic _dataProvider;
  
  void setDataProvider(dynamic dataProvider) {
    _dataProvider = dataProvider;
  }

  Future<bool> login(String username, String password) async {
    print("🔐 محاولة تسجيل الدخول: $username");
    
    // Admin login
    if (username == AppConstants.adminUsername && password == AppConstants.adminPassword) {
      print("✅ تسجيل دخول كمدير");
      _currentAgent = null;
      _isAgentMode = false;
      _isLoggedIn = true;
      await _saveLoginState();
      
      if (_dataProvider != null) {
        _dataProvider!.setUserMode(false);
        await _dataProvider!.refreshData();
      }
      
      notifyListeners();
      return true;
    }
    
    // Agent login
    try {
      final supabaseService = SupabaseService();
      final agents = await supabaseService.getAgents();
      print("📋 تم جلب ${agents.length} مندوب");
      
      Agent? foundAgent;
      for (final agent in agents) {
        if (agent.agentCode == username || agent.agentName == username) {
          if (agent.agentPassword == password) {
            foundAgent = agent;
            break;
          }
        }
      }
      
      if (foundAgent != null) {
        print("✅ تم العثور على المندوب: ${foundAgent.agentName}");
        _currentAgent = foundAgent;
        _isAgentMode = true;
        _isLoggedIn = true;
        await _saveLoginState();
        
        if (_dataProvider != null) {
          _dataProvider!.setUserMode(true, agentName: foundAgent.agentName);
          await _dataProvider!.refreshData();
        }
        
        notifyListeners();
        return true;
      } else {
        print("❌ لم يتم العثور على المندوب");
        return false;
      }
    } catch (e) {
      print("❌ خطأ في البحث عن المندوب: $e");
      return false;
    }
  }
  
  Future<void> logout() async {
    print("🚪 تسجيل الخروج");
    _currentAgent = null;
    _isAgentMode = false;
    _isLoggedIn = false;
    await _clearLoginState();
    
    if (_dataProvider != null) {
      _dataProvider!.setUserMode(false);
    }
    
    notifyListeners();
  }
  
  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', _isLoggedIn);
    await prefs.setBool('is_agent_mode', _isAgentMode);
    if (_currentAgent != null) {
      await prefs.setString('agent_backend_id', _currentAgent!.backendId ?? '');
      await prefs.setString('agent_name', _currentAgent!.agentName);
      await prefs.setString('agent_code', _currentAgent!.agentCode);
      await prefs.setDouble('agent_profit', _currentAgent!.agentProfitPerOrder);
    }
  }
  
  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('is_agent_mode');
    await prefs.remove('agent_backend_id');
    await prefs.remove('agent_name');
    await prefs.remove('agent_code');
    await prefs.remove('agent_profit');
  }
  
  Future<void> loadLoginState() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _isAgentMode = prefs.getBool('is_agent_mode') ?? false;
    
    if (_isLoggedIn && _isAgentMode) {
      final backendId = prefs.getString('agent_backend_id');
      final agentName = prefs.getString('agent_name') ?? '';
      final agentCode = prefs.getString('agent_code') ?? '';
      final agentProfit = prefs.getDouble('agent_profit') ?? AppConstants.defaultAgentProfit;
      
      _currentAgent = Agent(
        backendId: backendId,
        agentName: agentName,
        agentCode: agentCode,
        agentPhone: '',
        agentPassword: '',
        agentProfitPerOrder: agentProfit,
        createdAt: DateTime.now(),
      );
      
      if (_dataProvider != null && _currentAgent != null) {
        _dataProvider!.setUserMode(true, agentName: _currentAgent!.agentName);
      }
    } else if (_isLoggedIn && !_isAgentMode) {
      if (_dataProvider != null) {
        _dataProvider!.setUserMode(false);
      }
    }
    
    _isLoading = false;
    _isInitialized = true;  // ✅ تم الانتهاء من التحميل
    notifyListeners();
  }

  // تحديث ربح المندوب
  Future<void> updateAgentProfit(double newProfit) async {
    if (_currentAgent != null && _isAgentMode) {
      _currentAgent!.agentProfitPerOrder = newProfit;
      
      // حفظ التغيير في Supabase
      final supabaseService = SupabaseService();
      await supabaseService.updateAgent(_currentAgent!);
      
      // حفظ التغيير في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('agent_profit', newProfit);
      
      notifyListeners();
    }
  }
}