import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/parser.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext =
      HTFileSystemResourceContext(root: '../lib/', expressionModuleExtensions: [
    HTResource.json,
    HTResource.jsonWithComments,
  ]);

  final sourceFile = File('../lib/main.ht');
  final sourceContent = sourceFile.readAsStringSync();
  final source = HTSource(sourceContent);

  final parser = HTParser(context: sourceContext);
  final module = parser.parseToModule(source, moduleName: 'hetu:main');
  if (parser.errors!.isNotEmpty) {
    for (final err in parser.errors!) {
      print(err);
    }
  } else {
    final compileConfig = CompilerConfig(compileWithLineInfo: false);
    final compiler = HTCompiler(config: compileConfig);
    final bytes = compiler.compile(module);

    stdout.write(
        'Compiling files in \'lib\' folder into bytecode integer array...');
    final output = StringBuffer();
    output.writeln(
        '''/// The pre-compiled binary code of the core module of Hetu scripting language.
/// This file has been automatically generated, please do not edit manually.
final preincludeModule = [''');
    for (var i = 0; i < bytes.length; ++i) {
      output.write('  ${bytes[i]}');
      if (i < bytes.length - 1) {
        output.write(',');
      }
      output.writeln();
    }
    output.writeln('];');

    final content = output.toString();
    final file = File(
        '../packages/hetu_script/lib/interpreter/preinclude/preinclude_module.dart');
    file.writeAsStringSync(content);
    stdout.writeln(' done!');
  }
}
