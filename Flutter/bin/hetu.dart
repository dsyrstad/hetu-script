import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:hetu_script_flutter/hetu.dart';

abstract class Hetu_Env {
  static const title = '河图脚本语言';
  static const version = '版本：0.0.1';
}

void main(List<String> args) {
  try {
    hetu.init(displayLoadingInfo: false);
    if (args.isNotEmpty) {
      if ((args.first == '--help') || (args.first == '-h')) {
        String doc = File(path.join('doc', 'cli_help.md')).readAsStringSync();
        print(doc);
      } else if ((args.first == '--version') || (args.first == '-v')) {
        print('${Hetu_Env.title} ${Hetu_Env.version}');
      } else if ((args.first == '--repl') || (args.first == '-r')) {
        stdout.write('\x1B]0;${Hetu_Env.title} ${Hetu_Env.version}\x07');
        print('\n${Hetu_Env.title} ${Hetu_Env.version}\n'
            '输入指令并按回车即可执行，输入\'quit\'退出REPL环境。以\'\\\'结尾的指令可以换行继续输入。\n');
        var quit = false;
        var currentFileName = DateTime.now().millisecondsSinceEpoch.toString();

        while (!quit) {
          stdout.write('>>>');
          String input = stdin.readLineSync();

          if ((input == 'exit') ||
              (input == 'quit') ||
              (input == 'close') ||
              (input == 'end') ||
              (input == '退出') ||
              (input == '离开') ||
              (input == '关闭') ||
              (input == '结束')) {
            quit = true;
          } else {
            if (input.endsWith('\\')) {
              input += '\n' + stdin.readLineSync();
            }

            dynamic result;
            try {
              result = hetu.eval(input, currentFileName, style: ParseStyle.function);
            } catch (e) {
              print(e);
            }
            if (result != null) print(result);
          }
        }
      } else if (args.first == '-s') {
        var style = ParseStyle.function;

        hetu.evalf(args.first, displayLoadingInfo: false, style: style);
      } else {
        var style = ParseStyle.library;
        String entrance = HS_Common.mainFunc;

        hetu.evalf(args.first, displayLoadingInfo: false, style: style, invokeFunc: entrance);
      }
    } else {
      String doc = File(path.join('doc', 'cli_help.md')).readAsStringSync();
      print(doc);
    }
  } catch (e) {
    print(e);
  }
}
