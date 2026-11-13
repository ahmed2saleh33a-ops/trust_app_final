// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  bool isRead;
  final String? orderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
  });
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  NotificationProvider() {
    _loadNotifications();
  }
  
  void addNotification(String title, String message, String type, {String? orderId}) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      orderId: orderId,
    );
    _notifications.insert(0, notification);
    if (_notifications.length > 50) _notifications.removeLast();
    _saveNotifications();
    notifyListeners();
  }
  
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }
  
  void clearAll() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }
  
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    // simplified for now
  }
  
  Future<void> _loadNotifications() async {
    notifyListeners();
  }
}
