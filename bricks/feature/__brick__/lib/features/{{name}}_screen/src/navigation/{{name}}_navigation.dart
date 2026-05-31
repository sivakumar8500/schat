import 'package:flutter/material.dart';
import '../presentation/{{name}}_page.dart';

class {{name.pascalCase()}}Navigation {
  void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const {{name.pascalCase()}}Page()),
    );
  }
}
