import 'package:flutter/material.dart';

class {{name.pascalCase()}}Page extends void StatelessWidget {
  const {{name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{name.pascalCase()}}')),
      body: const Center(child: Text('{{name.pascalCase()}} Page')),
    );
  }
}
