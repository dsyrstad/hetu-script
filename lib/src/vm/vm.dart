import '../interpreter.dart';
import '../type.dart';
import '../parser.dart' show ParseStyle;
import '../lexicon.dart';
import 'compiler.dart';
import 'opcode.dart';
import '../lexer.dart';
import '../errors.dart';
import '../plugin/importHandler.dart';
import '../namespace.dart';
import 'bytes_resolver.dart';
import '../plugin/errorHandler.dart';
import 'bytes_reader.dart';

mixin VMRef {
  late final HTVM interpreter;
}

class HTVM extends HTInterpreter {
  late BytesReader _bytesReader;

  late final _codeStartIp;

  /// 符号表，不同语句块和环境的符号可能会有重名。
  /// key代表ip指针，value代表符号代表的值所在的命名空间上层深度
  final _distances = <int, int>{};

  dynamic _curValue;
  String? _curSymbol;
  String? _curClass;
  final _leftValueStack = <String>[];

  // final List<dynamic> _stack = [];
  final _register = List<dynamic>.filled(16, null, growable: false);

  HTVM({HTErrorHandler? errorHandler, HTImportHandler? importHandler})
      : super(errorHandler: errorHandler, importHandler: importHandler);

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTNamespace? namespace,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    curFileName = fileName ?? HTLexicon.anonymousScript;
    curNamespace = namespace ?? global;

    final tokens = Lexer().lex(content, curFileName);
    final bytes = await Compiler().compile(tokens, this, curNamespace, curFileName, style, debugMode);
    _bytesReader = BytesReader(bytes);
    print('Bytes length: ${_bytesReader.bytes.length}');
    print(_bytesReader.bytes);

    HTBytesResolver().resolve(_bytesReader.bytes, 10, curFileName);

    final result = execute();

    print(result);
  }

  @override
  Future<dynamic> import(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {}

  @override
  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {}

  @override
  HTTypeId typeof(dynamic object) {
    return HTTypeId.ANY;
  }

  void _storeLocal() {
    final oprandType = _bytesReader.read();
    switch (oprandType) {
      case HTLocalValueType.NULL:
        _curValue = null;
        break;
      case HTLocalValueType.boolean:
        (_bytesReader.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTLocalValueType.int64:
        _curValue = curNamespace.getConstInt(_bytesReader.readUint16());
        break;
      case HTLocalValueType.float64:
        _curValue = curNamespace.getConstFloat(_bytesReader.readUint16());
        break;
      case HTLocalValueType.utf8String:
        _curValue = curNamespace.getConstString(_bytesReader.readUint16());
        break;
      case HTLocalValueType.symbol:
        _curSymbol = _bytesReader.readShortUtf8String();
        _curValue = curNamespace.fetch(_curSymbol!);
        break;
      case HTLocalValueType.group:
        _curValue = execute(ip: _bytesReader.ip, keepIp: true);
        break;
      case HTLocalValueType.list:
        final list = [];
        final length = _bytesReader.readUint16();
        for (var i = 0; i < length; ++i) {
          list.add(execute(ip: _bytesReader.ip, keepIp: true));
        }
        _curValue = list;
        break;
      case HTLocalValueType.map:
        final map = {};
        final length = _bytesReader.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute(ip: _bytesReader.ip, keepIp: true);
          map[key] = execute(ip: _bytesReader.ip, keepIp: true);
        }
        _curValue = map;
        break;
    }
  }

  void _storeRegister(int index, dynamic value) {
    // if (index > _register.length) {
    //   _register.length = index + 8;
    // }

    _register[index] = value;
  }

  void _handleError() {
    final err_type = _bytesReader.read();
    // TODO: line 和 column
    switch (err_type) {
    }
  }

  void _handleAssignOp(int opcode) {
    final right = _bytesReader.read();

    switch (opcode) {
      case HTOpCode.assign:
        _curValue = _register[right];
        curNamespace.assign(_leftValueStack.last, _curValue);
        _leftValueStack.removeLast();
        break;
      case HTOpCode.assignMultiply:
        final leftValue = curNamespace.fetch(_leftValueStack.last);
        _curValue = leftValue * _register[right];
        curNamespace.assign(_leftValueStack.last, _curValue);
        _leftValueStack.removeLast();
        break;
      case HTOpCode.assignDevide:
        // _local = _register[left] /= _register[right];
        break;
      case HTOpCode.assignAdd:
        // _local = _register[left] += _register[right];
        break;
      case HTOpCode.assignSubtract:
        // _local = _register[left] -= _register[right];
        break;
    }
  }

  void _handleBinaryOp(int opcode) {
    final left = _bytesReader.read();
    final right = _bytesReader.read();

    switch (opcode) {
      case HTOpCode.logicalOr:
        _curValue = _register[left] = _register[left] || _register[right];
        break;
      case HTOpCode.logicalAnd:
        _curValue = _register[left] = _register[left] && _register[right];
        break;
      case HTOpCode.equal:
        _curValue = _register[left] = _register[left] == _register[right];
        break;
      case HTOpCode.notEqual:
        _curValue = _register[left] = _register[left] != _register[right];
        break;
      case HTOpCode.lesser:
        _curValue = _register[left] = _register[left] < _register[right];
        break;
      case HTOpCode.greater:
        _curValue = _register[left] = _register[left] > _register[right];
        break;
      case HTOpCode.lesserOrEqual:
        _curValue = _register[left] = _register[left] <= _register[right];
        break;
      case HTOpCode.greaterOrEqual:
        _curValue = _register[left] = _register[left] >= _register[right];
        break;
      case HTOpCode.add:
        _curValue = _register[left] = _register[left] + _register[right];
        break;
      case HTOpCode.subtract:
        _curValue = _register[left] = _register[left] - _register[right];
        break;
      case HTOpCode.multiply:
        _curValue = _register[left] = _register[left] * _register[right];
        break;
      case HTOpCode.devide:
        _curValue = _register[left] = _register[left] / _register[right];
        break;
      case HTOpCode.modulo:
        _curValue = _register[left] = _register[left] % _register[right];
        break;
      default:
      // throw HTErrorUndefinedBinaryOperator(_register[left].toString(), _register[right].toString(), opcode);
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final value = _bytesReader.read();

    switch (op) {
      case HTOpCode.negative:
        _curValue = _register[value] = -_register[value];
        break;
      case HTOpCode.logicalNot:
        _curValue = _register[value] = !_register[value];
        break;
      case HTOpCode.preIncrement:
        _curValue = _register[value] = ++_register[value];
        break;
      case HTOpCode.preDecrement:
        _curValue = _register[value] = --_register[value];
        break;
      default:
      // throw HTErrorUndefinedOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  void _handleUnaryPostfixOp(int op) {
    final value = _bytesReader.read();

    switch (op) {
      case HTOpCode.memberGet:
        // _local = _register[value] = -_register[value];
        break;
      case HTOpCode.subGet:
        // _local = _register[value] = !_register[value];
        break;
      case HTOpCode.call:
        // _local = _register[value] = !_register[value];
        break;
      case HTOpCode.postIncrement:
        _curValue = _register[value];
        _register[value] += 1;
        break;
      case HTOpCode.postDecrement:
        _curValue = _register[value];
        _register[value] -= 1;
        break;
      default:
      // throw HTErrorUndefinedOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  dynamic execute({int ip = 0, bool keepIp = false}) {
    final savedIp = _bytesReader.ip;
    _bytesReader.ip = ip;

    var instruction = _bytesReader.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _bytesReader.readUint32();
          break;
        case HTOpCode.version:
          final major = _bytesReader.read();
          final minor = _bytesReader.read();
          final patch = _bytesReader.readUint16();
          scriptVersion = HTVersion(major, minor, patch);
          print('Version: $scriptVersion');
          break;
        case HTOpCode.debug:
          debugMode = _bytesReader.read() == 0 ? false : true;
          print('Debug: $debugMode');
          break;
        case HTOpCode.codeStart:
          _codeStartIp = _bytesReader.ip;
          break;
        // 返回当前运算值
        case HTOpCode.returnValue:
          if (!keepIp) {
            _bytesReader.ip = savedIp;
          }
          return _curValue;
        // 语句结束
        case HTOpCode.endOfStatement:
          _curSymbol = null;
          break;
        // 从字节码读取常量表并保存在当前环境中
        case HTOpCode.constTable:
          var table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstInt(_bytesReader.readInt64());
          }
          table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstFloat(_bytesReader.readFloat64());
          }
          table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstString(_bytesReader.readUtf8String());
          }
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存储如下一个字节代表的寄存器位置中
        case HTOpCode.register:
          _storeRegister(_bytesReader.read(), _curValue);
          break;
        case HTOpCode.varDecl:
          _curSymbol = _bytesReader.readShortUtf8String();
          break;
        case HTOpCode.varInitStart:
          final initializerLength = _bytesReader.readUint16();
          if (_curClass == null) {
            _curValue = execute(ip: _bytesReader.ip);
            curNamespace.assign(_curSymbol!, _curValue);
          }
          _bytesReader.skip(initializerLength);
          break;
        case HTOpCode.leftValue:
          _leftValueStack.add(_curSymbol!);
          break;
        case HTOpCode.assign:
        case HTOpCode.assignMultiply:
        case HTOpCode.assignDevide:
        case HTOpCode.assignAdd:
        case HTOpCode.assignSubtract:
          _handleAssignOp(instruction);
          break;
        case HTOpCode.logicalOr:
        case HTOpCode.logicalAnd:
        case HTOpCode.equal:
        case HTOpCode.notEqual:
        case HTOpCode.lesser:
        case HTOpCode.greater:
        case HTOpCode.lesserOrEqual:
        case HTOpCode.greaterOrEqual:
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.modulo:
          _handleBinaryOp(instruction);
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.preIncrement:
        case HTOpCode.preDecrement:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
        case HTOpCode.postIncrement:
        case HTOpCode.postDecrement:
          _handleUnaryPostfixOp(instruction);
          break;
        case HTOpCode.debugInfo:
          curLine = _bytesReader.readUint32();
          curColumn = _bytesReader.readUint32();
          curFileName = _bytesReader.readShortUtf8String();
          break;
        // 错误处理
        case HTOpCode.error:
          _handleError();
          break;
        default:
          print('Unknown opcode: $instruction');
          break;
      }

      instruction = _bytesReader.read();
    }
  }
}
