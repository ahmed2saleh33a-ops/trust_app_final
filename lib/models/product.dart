// lib/models/product.dart
import 'package:flutter/material.dart';

class Product {
  final String? backendId;
  final String name;
  final String? description;
  int quantity;  // الكمية المتوفرة في المخزن
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.backendId,
    required this.name,
    this.description,
    required this.quantity,
    this.category,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      backendId: json['__backendId'],
      name: json['name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      category: json['category'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__backendId': backendId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'type': 'product',
    };
  }

  Product copyWith({
    String? backendId,
    String? name,
    String? description,
    int? quantity,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      backendId: backendId ?? this.backendId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // التحقق من وجود كمية كافية
  bool hasStock(int requestedQuantity) {
    return quantity >= requestedQuantity;
  }

  // خصم الكمية من المخزون
  bool deductStock(int requestedQuantity) {
    if (hasStock(requestedQuantity)) {
      quantity -= requestedQuantity;
      return true;
    }
    return false;
  }

  // إضافة كمية إلى المخزون
  void addStock(int amount) {
    quantity += amount;
  }
}