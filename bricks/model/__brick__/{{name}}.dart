import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}.freezed.dart';
part '{{name}}.g.dart';

@freezed
abstract class {{name.pascalCase()}} with _${{name.pascalCase()}} {
  const factory {{name.pascalCase()}}({
    {{#fields}}
    {{{this}}},
    {{/fields}}
  }) = _{{name.pascalCase()}};

  factory {{name.pascalCase()}}.fromJson(Map<String, dynamic> json) => _${{name.pascalCase()}}FromJson(json);
}
