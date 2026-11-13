// lib/models/order.dart
import 'package:flutter/material.dart';

class Order {
  final String? backendId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String product;
  final String? productInfo;
  final int quantity;
  final double price;
  final double total;
  final double profit;
  String status;
  final String agentName;
  final String? orderDate;
  String? adminNotes;
  final String? governorate;
  final String? district;
  final String? landmark;
  final String? jenniShipmentId;
  final int? localSerial;  // ✅ الرقم التسلسلي الخاص بالمندوب (لمنع التكرار)
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    this.backendId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.product,
    this.productInfo,
    required this.quantity,
    required this.price,
    required this.total,
    required this.profit,
    required this.status,
    required this.agentName,
    this.orderDate,
    this.adminNotes,
    this.governorate,
    this.district,
    this.landmark,
    this.jenniShipmentId,
    this.localSerial,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      backendId: json['__backendId'],
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      product: json['product'] ?? '',
      productInfo: json['product_info'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      status: json['status'] ?? 'جديد',
      agentName: json['agent_name'] ?? 'مندوب',
      orderDate: json['order_date'],
      adminNotes: json['admin_notes'],
      governorate: json['governorate'],
      district: json['district'],
      landmark: json['landmark'],
      jenniShipmentId: json['jenni_shipment_id'],
      localSerial: json['local_serial'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__backendId': backendId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'product': product,
      'product_info': productInfo,
      'quantity': quantity,
      'price': price,
      'total': total,
      'profit': profit,
      'status': status,
      'agent_name': agentName,
      'order_date': orderDate,
      'admin_notes': adminNotes,
      'governorate': governorate,
      'district': district,
      'landmark': landmark,
      'jenni_shipment_id': jenniShipmentId,
      'local_serial': localSerial,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'type': 'order',
    };
  }

  Order copyWith({
    String? backendId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? product,
    String? productInfo,
    int? quantity,
    double? price,
    double? total,
    double? profit,
    String? status,
    String? agentName,
    String? orderDate,
    String? adminNotes,
    String? governorate,
    String? district,
    String? landmark,
    String? jenniShipmentId,
    int? localSerial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      backendId: backendId ?? this.backendId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      product: product ?? this.product,
      productInfo: productInfo ?? this.productInfo,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
      profit: profit ?? this.profit,
      status: status ?? this.status,
      agentName: agentName ?? this.agentName,
      orderDate: orderDate ?? this.orderDate,
      adminNotes: adminNotes ?? this.adminNotes,
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      landmark: landmark ?? this.landmark,
      jenniShipmentId: jenniShipmentId ?? this.jenniShipmentId,
      localSerial: localSerial ?? this.localSerial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // دالة للحصول على لون الحالة
  static Color getStatusColor(String status) {
    switch (status) {
      case 'واصل':
        return Colors.green;
      case 'راجع':
        return Colors.red;
      case 'قيد التوصيل':
        return Colors.orange;
      case 'ملغي':
        return Colors.purple;
      case 'مؤجل':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  // دالة للحصول على أيقونة الحالة
  static String getStatusIcon(String status) {
    switch (status) {
      case 'واصل':
        return '✅';
      case 'راجع':
        return '↩️';
      case 'قيد التوصيل':
        return '🚚';
      case 'ملغي':
        return '❌';
      case 'مؤجل':
        return '⏰';
      default:
        return '📋';
    }
  }

  // ✅ قائمة الحالات المتاحة حسب نوع المستخدم (معدلة)
  static List<String> getAvailableStatuses({required bool isAdmin}) {
    if (isAdmin) {
      // ✅ المدير: جميع الحالات
      return ['جديد', 'قيد التوصيل', 'واصل', 'راجع', 'ملغي', 'مؤجل'];
    } else {
      // ✅ المندوب فقط: راجع، ملغي، مؤجل
      return ['راجع', 'ملغي', 'مؤجل'];
    }
  }

  // عنوان كامل
  String get fullAddress {
    if (landmark != null && landmark!.isNotEmpty) {
      return '$governorate - $district (قرب: $landmark)';
    }
    return '$governorate - $district';
  }

  // اسم المنتج مع الكمية
  String get fullProductName {
    if (quantity > 1) {
      return '$product ×$quantity';
    }
    return product;
  }
}