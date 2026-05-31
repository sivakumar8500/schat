import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'status_model.freezed.dart';

@freezed
abstract class StatusItemModel with _$StatusItemModel {
  const factory StatusItemModel({
    required String id,
    String? text,
    String? imagePath,
    required DateTime timestamp,
    @Default(Colors.black) Color backgroundColor,
    @Default(false) bool viewed,
  }) = _StatusItemModel;
}

@freezed
abstract class StatusContactModel with _$StatusContactModel {
  const factory StatusContactModel({
    required String contactId,
    required String name,
    required Color profileColor,
    required List<StatusItemModel> statuses,
    @Default(false) bool isMuted,
  }) = _StatusContactModel;
  
  const StatusContactModel._();
  
  bool get allViewed => statuses.every((s) => s.viewed);
  int get statusCount => statuses.length;
}
