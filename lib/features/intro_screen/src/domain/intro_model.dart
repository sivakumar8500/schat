import 'package:freezed_annotation/freezed_annotation.dart';

part 'intro_model.freezed.dart';

@freezed
abstract class IntroModel with _$IntroModel {
  const factory IntroModel({
    required String id,
  }) = _IntroModel;
}
