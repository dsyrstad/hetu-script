import 'dart:typed_data';

import 'package:hetu_script/type/structural_type.dart';
import 'package:path/path.dart' as path;

import '../binding/external_function.dart';
import '../value/namespace/namespace.dart';
import '../value/struct/named_struct.dart';
import '../value/entity.dart';
import '../value/class/class.dart';
import '../value/instance/cast.dart';
import '../value/function/function.dart';
import '../value/function/parameter.dart';
import '../value/variable/variable.dart';
import '../value/struct/struct.dart';
import '../value/external_enum/external_enum.dart';
import '../value/const.dart';
import '../binding/external_class.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';
import '../type/function_type.dart';
import '../type/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../analyzer/analyzer.dart';
import '../parser/parser.dart';
import '../shared/constants.dart';
import 'bytecode_module.dart';
import 'abstract_interpreter.dart';
import 'compiler.dart';
import 'preincludes/preinclude_module.dart';
import '../version.dart';

part 'binding/interpreter_binding.dart';

/// Mixin for classes that holds a ref of Interpreter
mixin HetuRef {
  late final Hetu interpreter;
}

class _LoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  _LoopInfo(this.startIp, this.continueIp, this.breakIp, this.namespace);
}

/// A bytecode implementation of a Hetu script interpreter
class Hetu extends HTAbstractInterpreter {
  @override
  final stackTrace = <String>[];

  final _cachedModules = <String, HTBytecodeModule>{};

  late final HTAnalyzer _analyzer;

  @override
  InterpreterConfig config;

  late HTResourceContext<HTSource> _sourceContext;

  @override
  HTResourceContext<HTSource> get sourceContext => _sourceContext;

  set sourceContext(HTResourceContext<HTSource> context) {
    _analyzer.sourceContext = _sourceContext = context;
  }

  @override
  ErrorHandlerConfig get errorConfig => config;

  var _line = 0;
  @override
  int get line => _line;

  var _column = 0;
  @override
  int get column => _column;

  @override
  final HTNamespace global;

  late HTNamespace _namespace;
  @override
  HTNamespace get namespace => _namespace;

  String _fileName = '';
  @override
  String get fileName => _fileName;

  bool _isModuleEntryScript = false;
  late ResourceType _currentFileResourceType;

  late HTBytecodeModule _bytecodeModule;
  HTBytecodeModule get bytecodeModule => _bytecodeModule;

  HTClass? _class;
  HTFunction? _function;

  bool _isStrictMode = false;

  var _currentStackIndex = -1;

  /// Register values are stored by groups.
  /// Every group have 16 values, they are HTRegIdx.
  /// A such group can be understanded as the stack frame of a runtime function.
  final _stackFrames = <List>[];

  void _setRegVal(int index, dynamic value) =>
      _stackFrames[_currentStackIndex][index] = value;
  dynamic _getRegVal(int index) => _stackFrames[_currentStackIndex][index];
  set _localValue(dynamic value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.value] = value;
  dynamic get _localValue => _stackFrames[_currentStackIndex][HTRegIdx.value];
  set _localSymbol(String? value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier] = value;
  String? get localSymbol =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier];
  set _localTypeArgs(List<HTType> value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] = value;
  List<HTType> get _localTypeArgs =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] ?? const [];
  set _loopCount(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] = value;
  int get _loopCount =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] ?? 0;
  set _anchor(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.anchor] = value;
  int get _anchor => _stackFrames[_currentStackIndex][HTRegIdx.anchor] ?? 0;

  /// Loop point is stored as stack form.
  /// Break statement will jump to the last loop point,
  /// and remove it from this stack.
  /// Return statement will clear loop points by
  /// [_loopCount] in current stack frame.
  final _loops = <_LoopInfo>[];

  /// inexpicit type conversion for zero or null values
  bool _isZero(dynamic condition) {
    if (_isStrictMode) {
      return condition == 0;
    } else {
      return condition == 0 || condition == null;
    }
  }

  /// inexpicit type conversion for truthy values
  bool _truthy(dynamic condition) {
    if (_isStrictMode || condition is bool) {
      return condition;
    } else if (condition == null ||
        condition == 0 ||
        condition == '' ||
        condition == '0' ||
        condition == 'false' ||
        (condition is Iterable && condition.isEmpty) ||
        (condition is Map && condition.isEmpty) ||
        (condition is HTStruct && condition.isEmpty)) {
      return false;
    } else {
      return true;
    }
  }

  /// A bytecode interpreter.
  Hetu(
      {HTResourceContext<HTSource>? sourceContext,
      this.config = const InterpreterConfig()})
      : global = HTNamespace(id: Semantic.global) {
    _sourceContext = sourceContext ?? HTOverlayContext();
    _analyzer = HTAnalyzer(sourceContext: _sourceContext);
    _namespace = global;
  }

  @override
  void init({
    List<HTSource> preincludes = const [],
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    if (config.doStaticAnalyze) {
      _analyzer.init(
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef,
        externalClasses: externalClasses,
      );
    }
    super.init(
      externalFunctions: externalFunctions,
      externalFunctionTypedef: externalFunctionTypedef,
      externalClasses: externalClasses,
    );
    bindExternalClass(HTHetuClassBinding());
    // load precompiled core module.
    final coreModule = Uint8List.fromList(hetuCoreModule);
    loadBytecode(
        bytes: coreModule, moduleName: 'hetu_main', globallyImport: true);
    invoke('setInterpreter', positionalArgs: [this]);
    for (final file in preincludes) {
      evalSource(file, globallyImport: true);
    }
  }

  /// Catch errors throwed by other code, and wrap them with detailed informations.
  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    final sb = StringBuffer();
    if (stackTrace.isNotEmpty && errorConfig.showDartStackTrace) {
      sb.writeln('${HTLexicon.scriptStackTrace}${HTLexicon.colon}');
      if (stackTrace.length > errorConfig.hetuStackTraceDisplayCountLimit * 2) {
        for (var i = stackTrace.length - 1;
            i >=
                stackTrace.length -
                    1 -
                    errorConfig.hetuStackTraceDisplayCountLimit;
            --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
        sb.writeln('...\n...');
        for (var i = errorConfig.hetuStackTraceDisplayCountLimit - 1;
            i >= 0;
            --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
      } else {
        for (var i = stackTrace.length - 1; i >= 0; --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
      }
    }
    if (externalStackTrace != null) {
      sb.writeln('${HTLexicon.externalStackTrace}${HTLexicon.colon}');
      sb.writeln(externalStackTrace);
    }
    final stackTraceString = sb.toString().trimRight();
    if (error is HTError) {
      final wrappedError = HTError(
        error.code,
        error.type,
        message: error.message,
        extra: errorConfig.showDartStackTrace ? stackTraceString : null,
        filename: error.filename ?? _fileName,
        line: error.line ?? _line,
        column: error.column ?? _column,
      );
      throw wrappedError;
    } else {
      final hetuError = HTError.extern(
        error.toString(),
        extra: errorConfig.showDartStackTrace ? stackTraceString : null,
        filename: _fileName,
        line: line,
        column: column,
      );
      throw hetuError;
    }
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  dynamic evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    if (source.content.isEmpty) {
      return null;
    }
    _fileName = source.fullName;
    _isStrictMode = isStrictMode;
    try {
      final bytes = compileSource(
        source,
        moduleName: moduleName,
        config: config,
        errorHandled: true,
      );
      final result = loadBytecode(
          bytes: bytes,
          moduleName: moduleName ?? source.fullName,
          globallyImport: globallyImport,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
          errorHandled: true);
      return result;
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  /// Call a function within current [HTNamespace].
  @override
  dynamic invoke(String funcName,
      {String? moduleName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      if (moduleName != null) {
        _bytecodeModule = _cachedModules[moduleName]!;
        _namespace = _bytecodeModule.namespaces[moduleName]!;
      }
      final func = _namespace.memberGet(funcName);
      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        HTError.notCallable(funcName);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  bool switchModule(String id) {
    if (_cachedModules.containsKey(id)) {
      newStackFrame(moduleName: id);
      return true;
    } else {
      return false;
    }
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List compileSource(HTSource source,
      {String? moduleName, CompilerConfig? config, bool errorHandled = false}) {
    try {
      final compileConfig = config ?? this.config;
      final compiler = HTCompiler(config: compileConfig);
      if (this.config.doStaticAnalyze) {
        _analyzer.evalSource(source);
        if (_analyzer.errors.isNotEmpty) {
          for (final error in _analyzer.errors) {
            if (errorHandled) {
              throw error;
            } else {
              handleError(error);
            }
          }
        }
        final bytes = compiler.compile(_analyzer.compilation);
        return bytes;
      } else {
        final parser = HTParser(context: _sourceContext);
        final module = parser.parseToModule(source);
        final bytes = compiler.compile(module);
        return bytes;
      }
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
        return Uint8List.fromList([]);
      }
    }
  }

  Uint8List? compile(String content,
      {String? filename,
      String? moduleName,
      bool isModule = false,
      bool errorHandled = false}) {
    final source = HTSource(content,
        fullName: filename,
        type: isModule ? ResourceType.hetuModule : ResourceType.hetuScript);
    final result = compileSource(source,
        moduleName: moduleName, errorHandled: errorHandled);
    return result;
  }

  /// Compile a script content into bytecode for later use.
  Uint8List? compileFile(String key,
      {String? moduleName, CompilerConfig? config, bool errorHandled = false}) {
    final source = _sourceContext.getResource(key);
    final bytes = compileSource(source,
        moduleName: moduleName, config: config, errorHandled: errorHandled);
    return bytes;
  }

  HTBytecodeModule? getBytecode(String moduleName) {
    return _cachedModules[moduleName];
  }

  dynamic toStructValue(dynamic value) {
    if (value is Iterable) {
      final list = [];
      for (final item in value) {
        final result = toStructValue(item);
        list.add(result);
      }
      return list;
    } else if (value is Map) {
      final prototype =
          _namespace.memberGet(HTLexicon.prototype, recursive: true);
      final struct = HTStruct(this, prototype: prototype, closure: namespace);
      for (final key in value.keys) {
        final fieldKey = key.toString();
        final fieldValue = toStructValue(value[key]);
        struct.define(fieldKey, fieldValue);
      }
      return struct;
    } else if (value is HTStruct) {
      return value.clone();
    } else {
      return value;
    }
  }

  HTStruct createStructfromJson(Map<dynamic, dynamic> jsonData) {
    final prototype =
        _namespace.memberGet(HTLexicon.prototype, recursive: true);
    final struct = HTStruct(this, prototype: prototype, closure: namespace);
    for (final key in jsonData.keys) {
      var value = toStructValue(jsonData[key]);
      struct.define(key.toString(), value);
    }
    return struct;
  }

  void _handleNamespaceImport(HTNamespace nsp, ImportDeclaration decl) {
    final importNamespace = _bytecodeModule.namespaces[decl.fromPath]!;
    if (_currentFileResourceType == ResourceType.hetuScript) {
      for (final importDecl in importNamespace.imports.values) {
        _handleNamespaceImport(importNamespace, importDecl);
      }
      for (final declaration in importNamespace.declarations.values) {
        declaration.resolve();
      }
    }

    if (decl.alias == null) {
      if (decl.showList.isEmpty) {
        nsp.import(importNamespace,
            isExported: decl.isExported, showList: decl.showList);
      } else {
        for (final id in decl.showList) {
          final decl = importNamespace.declarations[id]!;
          nsp.defineImport(id, decl);
        }
      }
    } else {
      if (decl.showList.isEmpty) {
        final aliasNamespace = HTNamespace(id: decl.alias!, closure: global);
        aliasNamespace.import(importNamespace);
        nsp.defineImport(decl.alias!, aliasNamespace);
      } else {
        final aliasNamespace = HTNamespace(id: decl.alias!, closure: global);
        for (final id in decl.showList) {
          final decl = importNamespace.declarations[id]!;
          aliasNamespace.define(id, decl);
        }
        nsp.defineImport(decl.alias!, aliasNamespace);
      }
    }
  }

  /// Load a pre-compiled bytecode file as a module.
  /// If [invokeFunc] is true, execute the bytecode immediately.
  dynamic loadBytecode(
      {required Uint8List bytes,
      required String moduleName,
      bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    _isStrictMode = isStrictMode;
    try {
      _bytecodeModule = HTBytecodeModule(moduleName, bytes);
      final signature = _bytecodeModule.readUint32();
      if (signature != HTCompiler.hetuSignature) {
        throw HTError.bytecode(
            filename: _fileName, line: _line, column: _column);
      }
      final major = _bytecodeModule.read();
      final minor = _bytecodeModule.read();
      final patch = _bytecodeModule.readUint16();
      var incompatible = false;
      if (major > 0) {
        if (major != kHetuVersion.major) {
          incompatible = true;
        }
      } else {
        if (major != kHetuVersion.major ||
            minor != kHetuVersion.minor ||
            patch != kHetuVersion.patch) {
          incompatible = true;
        }
      }
      if (incompatible) {
        throw HTError.version('$major.$minor.$patch', '$kHetuVersion',
            filename: _fileName, line: _line, column: _column);
      }
      final sourceType = ResourceType.values.elementAt(_bytecodeModule.read());
      _isModuleEntryScript = sourceType == ResourceType.hetuScript ||
          sourceType == ResourceType.hetuLiteralCode ||
          sourceType == ResourceType.hetuValue;
      if (sourceType == ResourceType.hetuLiteralCode) {
        _namespace = global;
      }
      while (_bytecodeModule.ip < _bytecodeModule.bytes.length) {
        final result = execute(clearStack: false);
        if (result is HTNamespace && result != global) {
          _bytecodeModule.namespaces[result.id!] = result;
        } else if (result is HTValueSource) {
          _bytecodeModule.expressions[result.id] = result.value;
        }
        // TODO: import binary bytes
      }
      if (!_isModuleEntryScript) {
        // handles imports
        for (final nsp in _bytecodeModule.namespaces.values) {
          for (final decl in nsp.imports.values) {
            _handleNamespaceImport(nsp, decl);
          }
        }
      }
      if (_bytecodeModule.namespaces.isNotEmpty) {
        _namespace = _bytecodeModule.namespaces.values.last;
        if (globallyImport) {
          global.import(_namespace);
        }
      }
      if (!_isModuleEntryScript) {
        // resolve each declaration after we get all declarations
        for (final namespace in _bytecodeModule.namespaces.values) {
          for (final decl in namespace.declarations.values) {
            decl.resolve();
          }
        }
      }
      _cachedModules[_bytecodeModule.id] = _bytecodeModule;
      if (invokeFunc != null) {
        final result = invoke(invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            errorHandled: true);
        return result;
      }
      if (_isModuleEntryScript) {
        return _stackFrames.last.first;
      }
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
      }
    }
  }

  void newStackFrame(
      {String? filename,
      String? moduleName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    // var ipChanged = false;
    var libChanged = false;
    if (filename != null) {
      _fileName = filename;
    }
    if (moduleName != null && (_bytecodeModule.id != moduleName)) {
      _bytecodeModule = _cachedModules[moduleName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _namespace = namespace;
    } else if (libChanged) {
      _namespace = _bytecodeModule.namespaces.values.last;
    }
    if (function != null) {
      _function = function;
    }
    if (ip != null) {
      _bytecodeModule.ip = ip;
    } else if (libChanged) {
      _bytecodeModule.ip = 0;
    }
    if (line != null) {
      _line = line;
    } else if (libChanged) {
      _line = 0;
    }
    if (column != null) {
      _column = column;
    } else if (libChanged) {
      _column = 0;
    }
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
    }
  }

  void restoreStackFrame(
      {String? savedFileName,
      String? savedModuleName,
      HTNamespace? savedNamespace,
      HTFunction? savedFunction,
      int? savedIp,
      int? savedLine,
      int? savedColumn}) {
    if (savedFileName != null) {
      _fileName = savedFileName;
    }
    if (savedModuleName != null) {
      if (_bytecodeModule.id != savedModuleName) {
        _bytecodeModule = _cachedModules[savedModuleName]!;
      }
    }
    if (savedNamespace != null) {
      _namespace = savedNamespace;
    }
    if (savedFunction != null) {
      _function = savedFunction;
    }
    if (savedIp != null) {
      _bytecodeModule.ip = savedIp;
    }
    if (savedLine != null) {
      _line = savedLine;
    }
    if (savedColumn != null) {
      _column = savedColumn;
    }
    --_currentStackIndex;
  }

  /// Interpret a loaded module with the key of [moduleName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [HTOpCode.endOfExec] or [HTOpCode.endOfFunc].
  ///
  /// Changing library will create new stack frame for new register values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {bool clearStack = true,
      String? filename,
      String? moduleName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    final savedFileName = _fileName;
    final savedLibrary = _bytecodeModule;
    final savedNamespace = _namespace;
    final savedFunction = _function;
    final savedIp = _bytecodeModule.ip;
    final savedLine = _line;
    final savedColumn = _column;
    var libChanged = false;
    var ipChanged = false;
    if (filename != null) {
      _fileName = filename;
    }
    if (moduleName != null && (_bytecodeModule.id != moduleName)) {
      _bytecodeModule = _cachedModules[moduleName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _namespace = namespace;
    }
    if (function != null) {
      _function = function;
    }
    if (ip != null) {
      _bytecodeModule.ip = ip;
      ipChanged = true;
    } else if (libChanged) {
      _bytecodeModule.ip = 0;
      ipChanged = true;
    }
    if (line != null) {
      _line = line;
    } else if (libChanged) {
      _line = 0;
    }
    if (column != null) {
      _column = column;
    } else if (libChanged) {
      _column = 0;
    }
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
    }

    final result = _execute();

    _fileName = savedFileName;
    _bytecodeModule = savedLibrary;
    _namespace = savedNamespace;
    _function = savedFunction;
    if (ipChanged) {
      _bytecodeModule.ip = savedIp;
    }
    _line = savedLine;
    _column = savedColumn;
    --_currentStackIndex;
    if (clearStack) {
      _stackFrames.removeLast();
    }
    return result;
  }

  void _clearLocals() {
    _localValue = null;
    _localSymbol = null;
    _localTypeArgs = [];
  }

  dynamic _execute() {
    var instruction = _bytecodeModule.read();
    while (instruction != HTOpCode.endOfCode) {
      switch (instruction) {
        case HTOpCode.lineInfo:
          _line = _bytecodeModule.readUint16();
          _column = _bytecodeModule.readUint16();
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _bytecodeModule.read();
          _setRegVal(index, _localValue);
          break;
        case HTOpCode.skip:
          final distance = _bytecodeModule.readInt16();
          _bytecodeModule.ip += distance;
          break;
        case HTOpCode.anchor:
          _anchor = _bytecodeModule.ip;
          break;
        case HTOpCode.goto:
          final distance = _bytecodeModule.readInt16();
          _bytecodeModule.ip = _anchor + distance;
          break;
        case HTOpCode.file:
          _fileName = _bytecodeModule.readString();
          final resourceTypeIndex = _bytecodeModule.read();
          _currentFileResourceType =
              ResourceType.values.elementAt(resourceTypeIndex);
          if (_currentFileResourceType != ResourceType.hetuLiteralCode) {
            _namespace = HTNamespace(id: _fileName, closure: global);
          }
          break;
        case HTOpCode.loopPoint:
          final continueLength = _bytecodeModule.readUint16();
          final breakLength = _bytecodeModule.readUint16();
          _loops.add(_LoopInfo(
              _bytecodeModule.ip,
              _bytecodeModule.ip + continueLength,
              _bytecodeModule.ip + breakLength,
              _namespace));
          ++_loopCount;
          break;
        case HTOpCode.breakLoop:
          _bytecodeModule.ip = _loops.last.breakIp;
          _namespace = _loops.last.namespace;
          _loops.removeLast();
          --_loopCount;
          _clearLocals();
          break;
        case HTOpCode.continueLoop:
          _bytecodeModule.ip = _loops.last.continueIp;
          break;
        case HTOpCode.assertion:
          final text = _bytecodeModule.readString();
          final value = execute();
          if (!value) {
            throw HTError.assertionFailed(text);
          }
          break;
        case HTOpCode.throws:
          throw HTError.scriptThrows(_localValue);
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _bytecodeModule.readString();
          _namespace = HTNamespace(id: id, closure: _namespace);
          _clearLocals();
          break;
        case HTOpCode.endOfBlock:
          _namespace = _namespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _clearLocals();
          break;
        case HTOpCode.endOfExec:
          return _localValue;
        case HTOpCode.endOfFunc:
          final loopCount = _loopCount;
          for (var i = 0; i < loopCount; ++i) {
            _loops.removeLast();
          }
          _loopCount = 0;
          return _localValue;
        case HTOpCode.endOfFile:
          if (_currentFileResourceType == ResourceType.hetuValue) {
            final module = HTValueSource(
                id: _fileName,
                moduleName: _bytecodeModule.id,
                value: _localValue);
            return module;
          } else {
            return _namespace;
          }
        case HTOpCode.constTable:
          final int64Length = _bytecodeModule.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _bytecodeModule.addInt(_bytecodeModule.readInt32());
            // _bytecodeModule.addInt(_bytecodeModule.readInt64());
          }
          final float64Length = _bytecodeModule.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _bytecodeModule.addFloat(_bytecodeModule.readFloat32());
            // _bytecodeModule.addFloat(_bytecodeModule.readFloat64());
          }
          final utf8StringLength = _bytecodeModule.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _bytecodeModule.addString(_bytecodeModule.readLongString());
          }
          break;
        case HTOpCode.importExportDecl:
          _handleImportExport();
          break;
        case HTOpCode.typeAliasDecl:
          _handleTypeAliasDecl();
          break;
        case HTOpCode.funcDecl:
          _handleFuncDecl();
          break;
        case HTOpCode.classDecl:
          _handleClassDecl();
          break;
        case HTOpCode.externalEnumDecl:
          _handleExternalEnumDecl();
          break;
        case HTOpCode.structDecl:
          _handleStructDecl();
          break;
        case HTOpCode.varDecl:
          _handleVarDecl();
          break;
        case HTOpCode.constDecl:
          _handleConstDecl();
          break;
        case HTOpCode.namespaceDecl:
          final internalName = _bytecodeModule.readString();
          String? classId;
          final hasClassId = _bytecodeModule.readBool();
          if (hasClassId) {
            classId = _bytecodeModule.readString();
          }
          final namespace = HTNamespace(
              id: internalName, classId: classId, closure: _namespace);
          execute(namespace: namespace);
          _namespace.define(internalName, namespace);
          _localValue = namespace;
          break;
        case HTOpCode.delete:
          final deletingType = _bytecodeModule.read();
          if (deletingType == DeletingTypeCode.member) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = _bytecodeModule.readString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _fileName, line: _line, column: _column);
            }
          } else if (deletingType == DeletingTypeCode.sub) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = execute().toString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _fileName, line: _line, column: _column);
            }
          } else {
            final symbol = _bytecodeModule.readString();
            _namespace.delete(symbol);
          }
          _clearLocals();
          break;
        case HTOpCode.ifStmt:
          final thenBranchLength = _bytecodeModule.readUint16();
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _bytecodeModule.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _bytecodeModule.ip = _loops.last.breakIp;
            _namespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
          break;
        case HTOpCode.doStmt:
          final hasCondition = _bytecodeModule.readBool();
          final truthValue = hasCondition ? _truthy(_localValue) : false;
          if (truthValue) {
            _bytecodeModule.ip = _loops.last.startIp;
          } else {
            _bytecodeModule.ip = _loops.last.breakIp;
            _namespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhen();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          _namespace.memberSet(localSymbol!, value, recursive: true);
          _localValue = value;
          break;
        case HTOpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          if (object == null) {
            throw HTError.nullObject(
                localSymbol ?? HTLexicon.kNull, Semantic.setter,
                filename: _fileName, line: _line, column: _column);
          } else {
            final key = _getRegVal(HTRegIdx.postfixKey);
            final value = execute();
            final encap = encapsulate(object);
            encap.memberSet(key, value);
            _localValue = value;
          }
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          if (object == null) {
            throw HTError.nullObject(
                localSymbol ?? HTLexicon.kNull, Semantic.subSetter,
                filename: _fileName, line: _line, column: _column);
          } else {
            final key = execute();
            final value = execute();
            if (object is HTEntity) {
              object.subSet(key, value);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(key,
                      filename: _fileName, line: _line, column: _column);
                } else if (key < 0 || key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      filename: _fileName, line: _line, column: _column);
                }
                object[key] = value;
              } else if (object is Map) {
                object[key] = value;
              }
            }
            _localValue = value;
          }
          break;
        case HTOpCode.ifNull:
        case HTOpCode.logicalOr:
        case HTOpCode.logicalAnd:
        case HTOpCode.equal:
        case HTOpCode.notEqual:
        case HTOpCode.lesser:
        case HTOpCode.greater:
        case HTOpCode.lesserOrEqual:
        case HTOpCode.greaterOrEqual:
        case HTOpCode.typeAs:
        case HTOpCode.typeIs:
        case HTOpCode.typeIsNot:
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.truncatingDevide:
        case HTOpCode.modulo:
          _handleBinaryOp(instruction);
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.typeOf:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _bytecodeModule.readBool();
          final keyBytesLength = _bytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _bytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? HTLexicon.kNull, Semantic.getter,
                  filename: _fileName, line: _line, column: _column);
            }
          } else {
            final key = execute();
            _localSymbol = key;
            final encap = encapsulate(object);
            _localValue = encap.memberGet(key, from: _namespace.fullName);
          }
          break;
        case HTOpCode.subGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _bytecodeModule.readBool();
          final keyBytesLength = _bytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _bytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? HTLexicon.kNull, Semantic.subGetter,
                  filename: _fileName, line: _line, column: _column);
            }
          } else {
            final key = execute();
            if (object is HTEntity) {
              _localValue = object.subGet(key, from: _namespace.fullName);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(key,
                      filename: _fileName, line: _line, column: _column);
                } else if (key < 0 || key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      filename: _fileName, line: _line, column: _column);
                }
              }
              _localValue = object[key];
            }
          }
          break;
        case HTOpCode.call:
          _handleCallExpr();
          break;
        default:
          throw HTError.unknownOpCode(instruction,
              filename: _fileName, line: _line, column: _column);
      }
      instruction = _bytecodeModule.read();
    }
  }

  void _handleImportExport() {
    final isExported = _bytecodeModule.readBool();
    final isPreloadedModule = _bytecodeModule.readBool();
    final showList = <String>{};
    final showListLength = _bytecodeModule.read();
    for (var i = 0; i < showListLength; ++i) {
      final id = _bytecodeModule.readString();
      showList.add(id);
      if (isExported) {
        _namespace.declareExport(id);
      }
    }
    final hasFromPath = _bytecodeModule.readBool();
    String? fromPath;
    if (hasFromPath) {
      fromPath = _bytecodeModule.readString();
    }
    String? alias;
    final hasAlias = _bytecodeModule.readBool();
    if (hasAlias) {
      alias = _bytecodeModule.readString();
    }
    if (isPreloadedModule) {
      assert(fromPath != null);
      final importedModule = _cachedModules[fromPath]!;
      final importedNamespace = importedModule.namespaces.values.last;
      _namespace.import(importedNamespace);
    } else {
      if (fromPath != null) {
        final ext = path.extension(fromPath);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          // TODO: binary bytes import
          final value = _bytecodeModule.expressions[fromPath];
          assert(value != null);
          _namespace.define(alias!, HTVariable(alias, value: value));
          if (isExported) {
            _namespace.declareExport(alias);
          }
        } else {
          final decl = ImportDeclaration(
            fromPath,
            alias: alias,
            showList: showList,
            isExported: isExported,
          );
          if (_currentFileResourceType == ResourceType.hetuModule) {
            _namespace.declareImport(decl);
          } else {
            _handleNamespaceImport(_namespace, decl);
          }
        }
      }
    }
    _clearLocals();
  }

  void _storeLocal() {
    final valueType = _bytecodeModule.read();
    switch (valueType) {
      case HTValueTypeCode.nullValue:
        _localValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_bytecodeModule.read() == 0)
            ? _localValue = false
            : _localValue = true;
        break;
      case HTValueTypeCode.constInt:
        final index = _bytecodeModule.readUint16();
        _localValue = _bytecodeModule.getInt64(index);
        break;
      case HTValueTypeCode.constFloat:
        final index = _bytecodeModule.readUint16();
        _localValue = _bytecodeModule.getFloat64(index);
        break;
      case HTValueTypeCode.constString:
        final index = _bytecodeModule.readUint16();
        _localValue = _bytecodeModule.getUtf8String(index);
        break;
      case HTValueTypeCode.longString:
        _localValue = _bytecodeModule.readLongString();
        break;
      case HTValueTypeCode.stringInterpolation:
        var literal = _bytecodeModule.readLongString();
        final interpolationLength = _bytecodeModule.read();
        for (var i = 0; i < interpolationLength; ++i) {
          final value = execute();
          literal = literal.replaceAll('{$i}', value.toString());
        }
        _localValue = literal;
        break;
      case HTValueTypeCode.identifier:
        final symbol = _localSymbol = _bytecodeModule.readString();
        final isLocal = _bytecodeModule.readBool();
        if (isLocal) {
          _localValue = _namespace.memberGet(symbol, recursive: true);
          // _curLeftValue = _curNamespace;
        } else {
          _localValue = symbol;
        }
        // final hasTypeArgs = _curLibrary.readBool();
        // if (hasTypeArgs) {
        //   final typeArgsLength = _curLibrary.read();
        //   final typeArgs = <HTType>[];
        //   for (var i = 0; i < typeArgsLength; ++i) {
        //     final arg = _handleTypeExpr();
        //     typeArgs.add(arg);
        //   }
        //   _curTypeArgs = typeArgs;
        // }
        break;
      case HTValueTypeCode.group:
        _localValue = execute();
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _bytecodeModule.readUint16();
        for (var i = 0; i < length; ++i) {
          final isSpread = _bytecodeModule.readBool();
          if (!isSpread) {
            final listItem = execute();
            list.add(listItem);
          } else {
            final List spreadValue = execute();
            list.addAll(spreadValue);
          }
        }
        _localValue = list;
        break;
      case HTValueTypeCode.struct:
        String? id;
        final hasId = _bytecodeModule.readBool();
        if (hasId) {
          id = _bytecodeModule.readString();
        }
        HTStruct? prototype;
        final hasPrototypeId = _bytecodeModule.readBool();
        if (hasPrototypeId) {
          final prototypeId = _bytecodeModule.readString();
          prototype = _namespace.memberGet(prototypeId,
              from: _namespace.fullName, recursive: true);
        }
        final struct =
            HTStruct(this, id: id, prototype: prototype, closure: _namespace);
        final fieldsCount = _bytecodeModule.read();
        for (var i = 0; i < fieldsCount; ++i) {
          final fieldType = _bytecodeModule.read();
          if (fieldType == StructObjFieldTypeCode.normal ||
              fieldType == StructObjFieldTypeCode.objectIdentifier) {
            final key = _bytecodeModule.readString();
            final value = execute();
            struct[key] = value;
          } else if (fieldType == StructObjFieldTypeCode.spread) {
            final HTStruct spreadingStruct = execute();
            for (final key in spreadingStruct.keys) {
              // skip internal apis
              if (key.startsWith(HTLexicon.internalPrefix)) continue;
              final copiedValue = toStructValue(spreadingStruct[key]);
              struct.define(key, copiedValue);
            }
          }
        }
        // _curNamespace = savedCurNamespace;
        _localValue = struct;
        break;
      // case HTValueTypeCode.map:
      //   final map = {};
      //   final length = _curLibrary.readUint16();
      //   for (var i = 0; i < length; ++i) {
      //     final key = execute();
      //     final value = execute();
      //     map[key] = value;
      //   }
      //   _curValue = map;
      //   break;
      case HTValueTypeCode.function:
        final internalName = _bytecodeModule.readString();
        final hasExternalTypedef = _bytecodeModule.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _bytecodeModule.readString();
        }
        final hasParamDecls = _bytecodeModule.readBool();
        final isVariadic = _bytecodeModule.readBool();
        final minArity = _bytecodeModule.read();
        final maxArity = _bytecodeModule.read();
        final paramDecls = _getParams(_bytecodeModule.read());
        int? line, column, definitionIp;
        final hasDefinition = _bytecodeModule.readBool();
        if (hasDefinition) {
          line = _bytecodeModule.readUint16();
          column = _bytecodeModule.readUint16();
          final length = _bytecodeModule.readUint16();
          definitionIp = _bytecodeModule.ip;
          _bytecodeModule.skip(length);
        }
        final func = HTFunction(
            internalName, _fileName, _bytecodeModule.id, this,
            closure: _namespace,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            namespace: _namespace);
        if (!hasExternalTypedef) {
          _localValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _localValue = externalFunc;
        }
        break;
      case HTValueTypeCode.type:
        _localValue = _handleTypeExpr();
        break;
      default:
        throw HTError.unkownValueType(valueType,
            filename: _fileName, line: _line, column: _column);
    }
  }

  void _handleWhen() {
    var condition = _localValue;
    final hasCondition = _bytecodeModule.readBool();
    final casesCount = _bytecodeModule.read();
    for (var i = 0; i < casesCount; ++i) {
      final caseType = _bytecodeModule.read();
      // If condition expression is provided,
      // jump to the first case branch where its value equals condition.
      // If condition expression is not provided,
      // jump to the first case branch where its value is true.
      // If no case branch matches condition and else branch is provided,
      // will jump to else branch.
      if (caseType == WhenCaseTypeCode.equals) {
        final value = execute();
        if (hasCondition) {
          if (condition == value) {
            break;
          }
        } else if (value) {
          break;
        }
        // skip jumpping to branch
        _bytecodeModule.skip(3);
      } else if (caseType == WhenCaseTypeCode.eigherEquals) {
        assert(hasCondition);
        final count = _bytecodeModule.read();
        final values = [];
        for (var i = 0; i < count; ++i) {
          values.add(execute());
        }
        if (values.contains(condition)) {
          break;
        } else {
          // skip jumpping to branch
          _bytecodeModule.skip(3);
        }
      } else if (caseType == WhenCaseTypeCode.elementIn) {
        assert(hasCondition);
        final Iterable value = execute();
        if (value.contains(condition)) {
          break;
        } else {
          // skip jumpping to branch
          _bytecodeModule.skip(3);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.ifNull:
        final left = _getRegVal(HTRegIdx.orLeft);
        final rightValueLength = _bytecodeModule.readUint16();
        if (left != null) {
          _bytecodeModule.skip(rightValueLength);
          _localValue = left;
        } else {
          final right = execute();
          _localValue = right;
        }
        break;
      case HTOpCode.logicalOr:
        final left = _getRegVal(HTRegIdx.orLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _bytecodeModule.readUint16();
        if (leftTruthValue) {
          _bytecodeModule.skip(rightValueLength);
          if (_isStrictMode) {
            _localValue = true;
          } else {
            _localValue = left;
          }
        } else {
          final right = execute();
          if (_isStrictMode) {
            final rightTruthValue = _truthy(right);
            _localValue = rightTruthValue;
          } else {
            _localValue = right;
          }
        }
        break;
      case HTOpCode.logicalAnd:
        final left = _getRegVal(HTRegIdx.andLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _bytecodeModule.readUint16();
        if (!leftTruthValue) {
          _bytecodeModule.skip(rightValueLength);
          _localValue = false;
        } else {
          final right = execute();
          final rightTruthValue = _truthy(right);
          _localValue = leftTruthValue && rightTruthValue;
        }
        break;
      case HTOpCode.equal:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left == _localValue;
        break;
      case HTOpCode.notEqual:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left != _localValue;
        break;
      case HTOpCode.lesser:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left < _localValue;
        break;
      case HTOpCode.greater:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left > _localValue;
        break;
      case HTOpCode.lesserOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left <= _localValue;
        break;
      case HTOpCode.greaterOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left >= _localValue;
        break;
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_localValue as HTType).resolve(_namespace);
        final HTClass klass = _namespace.memberGet(type.id,
            from: _namespace.fullName, recursive: true);
        _localValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_localValue as HTType).resolve(_namespace);
        final encapsulated = encapsulate(object);
        _localValue = encapsulated.valueType.isA(type);
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_localValue as HTType).resolve(_namespace);
        final encapsulated = encapsulate(object);
        _localValue = encapsulated.valueType.isNotA(type);
        break;
      case HTOpCode.add:
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left + right;
        break;
      case HTOpCode.subtract:
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left - right;
        break;
      case HTOpCode.multiply:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left * right;
        break;
      case HTOpCode.devide:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left / right;
        break;
      case HTOpCode.truncatingDevide:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left ~/ right;
        break;
      case HTOpCode.modulo:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left % right;
        break;
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final object = _localValue;
    switch (op) {
      case HTOpCode.negative:
        _localValue = -object;
        break;
      case HTOpCode.logicalNot:
        final truthValue = _truthy(object);
        _localValue = !truthValue;
        break;
      case HTOpCode.typeOf:
        final encap = encapsulate(object);
        _localValue = encap.valueType;
        break;
    }
  }

  void _handleCallExpr() {
    final isNullable = _bytecodeModule.readBool();
    final callee = _getRegVal(HTRegIdx.postfixObject);
    final argsBytesLength = _bytecodeModule.readUint16();
    if (callee == null) {
      if (isNullable) {
        _bytecodeModule.skip(argsBytesLength);
        _localValue = null;
        return;
      } else {
        throw HTError.nullObject(localSymbol ?? HTLexicon.kNull, Semantic.call,
            filename: _fileName, line: _line, column: _column);
      }
    }
    final positionalArgs = [];
    final positionalArgsLength = _bytecodeModule.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final isSpread = _bytecodeModule.readBool();
      if (!isSpread) {
        final arg = execute();
        positionalArgs.add(arg);
      } else {
        final List spreadValue = execute();
        positionalArgs.addAll(spreadValue);
      }
    }
    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _bytecodeModule.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _bytecodeModule.readString();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }
    final typeArgs = _localTypeArgs;
    // calle is a script function
    if (callee is HTFunction) {
      _localValue = callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    }
    // calle is a dart function
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _localValue = callee(_namespace,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        _localValue = Function.apply(
            callee,
            positionalArgs,
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
      }
    } else if ((callee is HTClass) || (callee is HTType)) {
      late HTClass klass;
      if (callee is HTType) {
        final resolvedType = callee.resolve(_namespace);
        if (resolvedType is! HTNominalType) {
          throw HTError.notCallable(callee.toString(),
              filename: _fileName, line: _line, column: _column);
        }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }
      if (klass.isAbstract) {
        throw HTError.abstracted(
            filename: _fileName, line: _line, column: _column);
      }
      if (klass.contains(Semantic.constructor)) {
        final constructor = klass.memberGet(klass.id!) as HTFunction;
        _localValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(klass.id!,
            filename: _fileName, line: _line, column: _column);
      }
    } else if (callee is HTStruct && callee.declaration != null) {
      HTNamedStruct def = callee.declaration!;
      _localValue = def.createObject(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
      );
    } else {
      throw HTError.notCallable(callee.toString(),
          filename: _fileName, line: _line, column: _column);
    }
  }

  HTType _handleTypeExpr() {
    final index = _bytecodeModule.read();
    final typeType = TypeType.values.elementAt(index);
    switch (typeType) {
      case TypeType.normal:
        final typeName = _bytecodeModule.readString();
        final typeArgsLength = _bytecodeModule.read();
        final typeArgs = <HTUnresolvedType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          final typearg = _handleTypeExpr() as HTUnresolvedType;
          typeArgs.add(typearg);
        }
        final isNullable = (_bytecodeModule.read() == 0) ? false : true;
        return HTUnresolvedType(typeName,
            typeArgs: typeArgs, isNullable: isNullable);
      case TypeType.function:
        final paramsLength = _bytecodeModule.read();
        final parameterTypes = <HTParameterType>[];
        for (var i = 0; i < paramsLength; ++i) {
          final declType = _handleTypeExpr();
          final isOptional = _bytecodeModule.read() == 0 ? false : true;
          final isVariadic = _bytecodeModule.read() == 0 ? false : true;
          final isNamed = _bytecodeModule.read() == 0 ? false : true;
          String? paramId;
          if (isNamed) {
            paramId = _bytecodeModule.readString();
          }
          final decl = HTParameterType(declType,
              isOptional: isOptional, isVariadic: isVariadic, id: paramId);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterTypes: parameterTypes, returnType: returnType);
      case TypeType.structural:
        final fieldsLength = _bytecodeModule.readUint16();
        final fieldTypes = <String, HTType>{};
        for (var i = 0; i < fieldsLength; ++i) {
          final id = _bytecodeModule.readString();
          final typeExpr = _handleTypeExpr();
          fieldTypes[id] = typeExpr;
        }
        return HTStructuralType(namespace, fieldTypes: fieldTypes);
      case TypeType.union:
        throw 'Union Type is not implemented yet in this version of Hetu.';
    }
  }

  void _handleTypeAliasDecl() {
    final id = _bytecodeModule.readString();
    String? classId;
    final hasClassId = _bytecodeModule.readBool();
    if (hasClassId) {
      classId = _bytecodeModule.readString();
    }
    final value = _handleTypeExpr();
    final decl =
        HTVariable(id, classId: classId, closure: _namespace, value: value);
    _namespace.define(id, decl);
    _clearLocals();
  }

  void _handleConstDecl() {
    final id = _bytecodeModule.readString();
    String? classId;
    final hasClassId = _bytecodeModule.readBool();
    if (hasClassId) {
      classId = _bytecodeModule.readString();
    }
    final isStatic = _bytecodeModule.readBool();
    final typeIndex = _bytecodeModule.read();
    final type = ConstType.values.elementAt(typeIndex);
    final index = _bytecodeModule.readInt16();
    final decl = HTConst(id, type, index, _bytecodeModule,
        classId: classId, isStatic: isStatic);
    _namespace.define(id, decl);
    _clearLocals();
  }

  void _handleVarDecl() {
    final id = _bytecodeModule.readString();
    String? classId;
    final hasClassId = _bytecodeModule.readBool();
    if (hasClassId) {
      classId = _bytecodeModule.readString();
    }
    final isField = _bytecodeModule.readBool();
    final isExternal = _bytecodeModule.readBool();
    final isStatic = _bytecodeModule.readBool();
    final isMutable = _bytecodeModule.readBool();
    final lateFinalize = _bytecodeModule.readBool();
    final lateInitialize = _bytecodeModule.readBool();
    HTType? declType;
    final hasTypeDecl = _bytecodeModule.readBool();
    if (hasTypeDecl) {
      declType = _handleTypeExpr();
    }
    late final HTVariable decl;
    final hasInitializer = _bytecodeModule.readBool();
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _bytecodeModule.readUint16();
        final definitionColumn = _bytecodeModule.readUint16();
        final length = _bytecodeModule.readUint16();
        final definitionIp = _bytecodeModule.ip;
        _bytecodeModule.skip(length);
        decl = HTVariable(id,
            interpreter: this,
            fileName: _fileName,
            moduleName: _bytecodeModule.id,
            classId: classId,
            closure: _namespace,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final initValue = execute();
        decl = HTVariable(id,
            interpreter: this,
            fileName: _fileName,
            moduleName: _bytecodeModule.id,
            classId: classId,
            closure: _namespace,
            declType: declType,
            value: initValue,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable);
      }
    } else {
      decl = HTVariable(id,
          interpreter: this,
          fileName: _fileName,
          moduleName: _bytecodeModule.id,
          classId: classId,
          closure: _namespace,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isMutable: isMutable,
          lateFinalize: lateFinalize);
    }
    if (!isField) {
      _namespace.define(id, decl, override: true);
    }
    _clearLocals();
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _bytecodeModule.readString();
      final isOptional = _bytecodeModule.readBool();
      final isVariadic = _bytecodeModule.readBool();
      final isNamed = _bytecodeModule.readBool();
      HTType? declType;
      final hasTypeDecl = _bytecodeModule.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      int? definitionIp;
      int? definitionLine;
      int? definitionColumn;
      final hasInitializer = _bytecodeModule.readBool();
      if (hasInitializer) {
        definitionLine = _bytecodeModule.readUint16();
        definitionColumn = _bytecodeModule.readUint16();
        final length = _bytecodeModule.readUint16();
        definitionIp = _bytecodeModule.ip;
        _bytecodeModule.skip(length);
      }
      paramDecls[id] = HTParameter(id,
          interpreter: this,
          fileName: _fileName,
          moduleName: _bytecodeModule.id,
          closure: _namespace,
          declType: declType,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }
    return paramDecls;
  }

  void _handleFuncDecl() {
    final internalName = _bytecodeModule.readString();
    String? id;
    final hasId = _bytecodeModule.readBool();
    if (hasId) {
      id = _bytecodeModule.readString();
    }
    String? classId;
    final hasClassId = _bytecodeModule.readBool();
    if (hasClassId) {
      classId = _bytecodeModule.readString();
    }
    String? externalTypeId;
    final hasExternalTypedef = _bytecodeModule.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _bytecodeModule.readString();
    }
    final category = FunctionCategory.values[_bytecodeModule.read()];
    final isField = _bytecodeModule.readBool();
    final isExternal = _bytecodeModule.readBool();
    final isStatic = _bytecodeModule.readBool();
    final isConst = _bytecodeModule.readBool();
    final hasParamDecls = _bytecodeModule.readBool();
    final isVariadic = _bytecodeModule.readBool();
    final minArity = _bytecodeModule.read();
    final maxArity = _bytecodeModule.read();
    final paramLength = _bytecodeModule.read();
    final paramDecls = _getParams(paramLength);
    RedirectingConstructor? redirCtor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRedirectingCtor = _bytecodeModule.readBool();
      if (hasRedirectingCtor) {
        final calleeId = _bytecodeModule.readString();
        final hasCtorName = _bytecodeModule.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _bytecodeModule.readString();
        }
        final positionalArgIpsLength = _bytecodeModule.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _bytecodeModule.readUint16();
          positionalArgIps.add(_bytecodeModule.ip);
          _bytecodeModule.skip(argLength);
        }
        final namedArgsLength = _bytecodeModule.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _bytecodeModule.readString();
          final argLength = _bytecodeModule.readUint16();
          namedArgIps[argName] = _bytecodeModule.ip;
          _bytecodeModule.skip(argLength);
        }
        redirCtor = RedirectingConstructor(calleeId,
            key: ctorName,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }
    int? line, column, definitionIp;
    final hasDefinition = _bytecodeModule.readBool();
    if (hasDefinition) {
      line = _bytecodeModule.readUint16();
      column = _bytecodeModule.readUint16();
      final length = _bytecodeModule.readUint16();
      definitionIp = _bytecodeModule.ip;
      _bytecodeModule.skip(length);
    }
    final func = HTFunction(internalName, _fileName, _bytecodeModule.id, this,
        id: id,
        classId: classId,
        closure: _namespace,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        category: category,
        externalTypeId: externalTypeId,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        redirectingConstructor: redirCtor);
    if (isField) {
      _localValue = func;
    } else {
      if ((category != FunctionCategory.constructor) || isStatic) {
        func.namespace = _namespace;
      }
      _namespace.define(func.internalName, func);
    }
    _localValue = func;
  }

  void _handleClassDecl() {
    final id = _bytecodeModule.readString();
    final isExternal = _bytecodeModule.readBool();
    final isAbstract = _bytecodeModule.readBool();
    final hasUserDefinedConstructor = _bytecodeModule.readBool();
    HTType? superType;
    final hasSuperClass = _bytecodeModule.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTEntity.type;
      }
    }
    final isEnum = _bytecodeModule.readBool();
    final klass = HTClass(this,
        id: id,
        closure: _namespace,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isEnum: isEnum);
    _namespace.define(id, klass);
    final savedClass = _class;
    _class = klass;
    // deal with definition block
    execute(namespace: klass.namespace);
    // Add default constructor if non-exist.
    if (!isAbstract && !hasUserDefinedConstructor && !isExternal) {
      final ctor = HTFunction(
          Semantic.constructor, _fileName, _bytecodeModule.id, this,
          classId: klass.id,
          category: FunctionCategory.constructor,
          closure: klass.namespace);
      klass.namespace.define(Semantic.constructor, ctor);
    }
    if (_isModuleEntryScript || _function != null) {
      klass.resolve();
    }
    _class = savedClass;
    _localValue = klass;
  }

  void _handleExternalEnumDecl() {
    final id = _bytecodeModule.readString();
    final enumClass = HTExternalEnum(id, this);
    _namespace.define(id, enumClass);
    _localValue = enumClass;
  }

  void _handleStructDecl() {
    final id = _bytecodeModule.readString();
    String? prototypeId;
    final hasPrototypeId = _bytecodeModule.readBool();
    if (hasPrototypeId) {
      prototypeId = _bytecodeModule.readString();
    }
    final lateInitialize = _bytecodeModule.readBool();
    final staticFieldsLength = _bytecodeModule.readUint16();
    final staticDefinitionIp = _bytecodeModule.ip;
    _bytecodeModule.skip(staticFieldsLength);
    final fieldsLength = _bytecodeModule.readUint16();
    final definitionIp = _bytecodeModule.ip;
    _bytecodeModule.skip(fieldsLength);
    final struct = HTNamedStruct(
      id,
      this,
      _fileName,
      _bytecodeModule.id,
      _namespace,
      prototypeId: prototypeId,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    if (!lateInitialize) {
      struct.resolve();
    }
    _namespace.define(id, struct);
    _localValue = struct;
  }
}
