// lib/models/agent.dart
import 'order.dart';

class Agent {
  final int? id;  // معرف رقمي تلقائي من Supabase
  final String? backendId;  // __backendId المعرف المخصص
  final String? type;  // 'agent'
  final String agentName;
  final String agentPhone;
  final String agentCode;
  final String agentPassword;
  double agentProfitPerOrder;
  final int? lastSerial;  // ✅ آخر رقم تسلسلي تم استخدامه لهذا المندوب (لمنع تكرار الطلبات)
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agent({
    this.id,
    this.backendId,
    this.type,
    required this.agentName,
    required this.agentPhone,
    required this.agentCode,
    required this.agentPassword,
    required this.agentProfitPerOrder,
    this.lastSerial,
    required this.createdAt,
    this.updatedAt,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      backendId: json['__backendId'],
      type: json['type'],
      agentName: json['agent_name'] ?? '',
      agentPhone: json['agent_phone'] ?? '',
      agentCode: json['agent_code'] ?? '',
      agentPassword: json['agent_password'] ?? '',
      agentProfitPerOrder: (json['agent_profit_per_order'] ?? 1000).toDouble(),
      lastSerial: json['last_serial'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__backendId': backendId,
      'type': 'agent',
      'agent_name': agentName,
      'agent_phone': agentPhone,
      'agent_code': agentCode,
      'agent_password': agentPassword,
      'agent_profit_per_order': agentProfitPerOrder,
      'last_serial': lastSerial,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Agent copyWith({
    int? id,
    String? backendId,
    String? type,
    String? agentName,
    String? agentPhone,
    String? agentCode,
    String? agentPassword,
    double? agentProfitPerOrder,
    int? lastSerial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agent(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      type: type ?? this.type,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      agentCode: agentCode ?? this.agentCode,
      agentPassword: agentPassword ?? this.agentPassword,
      agentProfitPerOrder: agentProfitPerOrder ?? this.agentProfitPerOrder,
      lastSerial: lastSerial ?? this.lastSerial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // حساب إجمالي أرباح المندوب من الطلبات
  double calculateTotalProfit(List<Order> orders) {
    return orders
        .where((order) => order.agentName == agentName && order.status == 'واصل')
        .fold(0.0, (sum, order) => sum + order.profit);
  }

  // حساب عدد الطلبات المنجزة
  int getCompletedOrdersCount(List<Order> orders) {
    return orders
        .where((order) => order.agentName == agentName && order.status == 'واصل')
        .length;
  }

  // حساب عدد الطلبات الكلي
  int getTotalOrdersCount(List<Order> orders) {
    return orders.where((order) => order.agentName == agentName).length;
  }

  // نسبة الإنجاز
  double getCompletionRate(List<Order> orders) {
    int total = getTotalOrdersCount(orders);
    if (total == 0) return 0.0;
    return getCompletedOrdersCount(orders) / total * 100;
  }
}