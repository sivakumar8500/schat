import 'package:flutter/material.dart';

class ThemeColorModel {
  final String id;
  final String name;
  final String hexCode;

  const ThemeColorModel({
    required this.id,
    required this.name,
    required this.hexCode,
  });

  factory ThemeColorModel.fromJson(Map<String, dynamic> json) {
    return ThemeColorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hexCode: json['hexCode']?.toString() ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hexCode': hexCode,
    };
  }

  /// Parse the hexCode string and return a Flutter [Color].
  Color toColor() {
    try {
      final hex = hexCode.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return Colors.white;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ThemeColorModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
