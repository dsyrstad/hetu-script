<p align="center">
  <a href="https://hetu.dev">
    <img alt="hetu script" width="200px" src="https://hetu.dev/image/hetu-logo-large.png">
  </a>
  <h1 align="center">河图脚本语言</h1>
</p>

<p align="center">
专为 Flutter 打造的轻量型嵌入式脚本语言。
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/hetu_script" ><img src="https://img.shields.io/pub/v/hetu_script" /></a>
  <a title="VSCode Extension" href="https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript" ><img src="https://vsmarketplacebadge.apphb.com/version/hetu-script.hetuscript.svg" /></a>
  <a title="Discord" href="https://discord.gg/aJedwcRPr8" ><img src="https://img.shields.io/discord/829269197727989760" /></a>
</p>

## 目的

为了实现 Flutter 程序和游戏的热更新和脚本能力。

我们没有使用 Javascript 或者 Python 之类的现成脚本语言，主要是为了让这个库保持轻量级。完全用 Dart 写成，也让传递 Flutter 对象和数据变得极为简单。

## 文档

暂时没有中文文档，请参考[英文文档](https://hetu.dev/docs/en-US/)

## 快速上手

下面是一个简单的在 Dart 程序中解释一个脚本字符串的例子。

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var ht = {
      name: 'Hetu',
      greeting: () {
        print('Hi! I\'m', this.name)
      }
    }
    ht.greeting()
  ''');
}
```

我们可以看到河图的[语法](https://hetu.dev/docs/en-US/syntax/)非常简单，如果你熟悉 dart/typescript/kotlin/swift 等现代语言，只要注意下面几点，就可以直接上手。

- 句末分号可选。
- 函数名字前面要加关键字： 'fun, get, set, construct'。
- 既可以使用类似 Java 的 class 的继承，也可以使用 javascript 的对象字面量的原型链，也可以使用函数式的写法。
- 类型注解和 typescript 一样写在关键字后面。（目前静态分析尚未开发完毕，因此类型目前只是纯粹的注解，所有变量实际上都是 dynamic 类型。）

## 绑定

[河图和 Dart 交换数据和调用函数](https://hetu.dev/docs/en-US/binding/)简单到令人发指。下面是一个脚本调用 Dart 函数，并且直接操作 Dart 的 Map 对象的例子。

```dart
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': () => {'greeting': 'Hello from Dart!'},
  });
  final hetuValue = hetu.eval(r'''
      external fun hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
```

## VS Code 插件

如果你使用 VS Code 进行开发，可以下载[这个插件](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript)来获得脚本的高亮显示等功能。

## 命令行工具

河图提供了基本的命令行操作方式，以便快速测试脚本功能。可以使用下面的命令在你的电脑上打开全局的 'hetu' 命令。

```
dart pub global activate hetu_script_dev_tools
```

你可以在任何目录下打开命令行工具，然后输入 'hetu -h' 查看可用命令。

直接输入 'hetu' 会进入类似 Python 命令行的 REPL 模式。在这个模式下，可以直接输入脚本语句，并看到解释的结果。如果需要输入多行，可以在句末输入 '\\'。

```typescript
>>>var a = 42
null // repl print
>>>a
42 // repl print
>>>fun meaning {\
return a }
null // repl print
>>>meaning
meaning() -> any // repl print
>>>hello()
42 // repl print
```

可以在这里查看关于 Dart 的 [pub global activate](https://dart.dev/tools/pub/cmd/pub-global) 功能的更多信息。

## 讨论组

Discord: [https://discord.gg/aJedwcRPr8](https://discord.gg/aJedwcRPr8)

QQ 群：812529118

## 支持我的工作

如果要支持我，可以在 GitHub 上为这个项目加个 star。

也可以在下面的的链接进行捐赠：

[![Buy me a coffee](https://hetu.dev/image/buy_me_a_coffee_small.png)](https://www.buymeacoffee.com/chengfubeiming)
