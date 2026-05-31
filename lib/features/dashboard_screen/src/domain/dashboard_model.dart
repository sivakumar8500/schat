import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_model.freezed.dart';

@freezed
abstract class DashboardModel with _$DashboardModel {
  const factory DashboardModel({
    required String id,
  }) = _DashboardModel;
}
