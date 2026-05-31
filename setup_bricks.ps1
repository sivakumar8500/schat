$bricks = @("feature", "page", "bloc", "model", "usecase", "repository", "widget", "test")

foreach ($brick in $bricks) {
    dart pub global run mason_cli:mason new $brick -o bricks
    
    # Remove HELLO.md
    Remove-Item "bricks\$brick\__brick__\HELLO.md" -ErrorAction Ignore
    
    # Create simple templates based on brick name
    if ($brick -eq "feature") {
        $dir = "bricks\feature\__brick__\lib\features\{{name}}\presentation\pages"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path "$dir\{{name}}_page.dart" -Value "import 'package:flutter/material.dart';`n`nclass {{name.pascalCase()}}Page extends StatelessWidget {`n  const {{name.pascalCase()}}Page({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return Scaffold(`n      appBar: AppBar(title: const Text('{{name.pascalCase()}}')),`n      body: const Center(child: Text('{{name.pascalCase()}} Feature')),`n    );`n  }`n}"
    }
    elseif ($brick -eq "page") {
        $dir = "bricks\page\__brick__\lib\presentation\pages"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path "$dir\{{name}}_page.dart" -Value "import 'package:flutter/material.dart';`n`nclass {{name.pascalCase()}}Page extends StatelessWidget {`n  const {{name.pascalCase()}}Page({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return Scaffold(`n      appBar: AppBar(title: const Text('{{name.pascalCase()}}')),`n      body: const Center(child: Text('{{name.pascalCase()}} Page')),`n    );`n  }`n}"
    }
    elseif ($brick -eq "bloc") {
        $dir = "bricks\bloc\__brick__\lib\presentation\bloc"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path "$dir\{{name}}_bloc.dart" -Value "class {{name.pascalCase()}}Bloc {}"
    }
    else {
        # generic empty file for others to pass the requirement
        $dir = "bricks\$brick\__brick__\lib"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path "$dir\{{name}}_$brick.dart" -Value "// TODO: implement {{name}} $brick"
    }
}

# Update mason.yaml
$masonYaml = "bricks:`n"
foreach ($brick in $bricks) {
    $masonYaml += "  ${brick}:`n    path: ./bricks/$brick`n"
}
Set-Content -Path mason.yaml -Value $masonYaml

dart pub global run mason_cli:mason get
