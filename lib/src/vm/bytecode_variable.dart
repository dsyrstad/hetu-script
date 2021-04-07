import 'vm.dart';
import '../variable.dart';
import '../type.dart';
import '../errors.dart';

/// Bytecode implementation of [HTVariable].
class HTBytecodeVariable extends HTVariable with HetuRef {
  /// The module this variable declared in.
  final String moduleUniqueKey;

  /// Whether this variable have [HTType].
  final bool isDynamic;

  /// Whether this variable is immutable.
  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTType? _declType;

  /// The [HTType] of this variable, will be used to
  /// determine wether an assignment is legal.
  HTType? get declType => _declType;

  /// The instructor pointer of the initializer's bytecode.
  int? initializerIp;

  /// Create a standard [HTBytecodeVariable].
  ///
  /// A [HTVariable] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be used within a script.
  HTBytecodeVariable(String id, Hetu interpreter, this.moduleUniqueKey,
      {String? classId,
      dynamic value,
      HTType? declType,
      this.initializerIp,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            classId: classId,
            value: value,
            getter: getter,
            setter: setter,
            isExtern: isExtern,
            isMember: isMember,
            isStatic: isStatic) {
    this.interpreter = interpreter;
    if (declType == null) {
      if (initializerIp == null) {
        _declType = HTType.ANY;
      } else {
        // 初始化时也会尝试对 _declType 赋值
        // TODO: 这里挪到 vm 里面进行？
        // initialize();
      }
    } else {
      _declType = declType;
    }
  }

  /// Initialize this variable with its declared initializer bytecode
  @override
  void initialize() {
    if (isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleUniqueKey: moduleUniqueKey,
            ip: initializerIp!,
            namespace: closure);

        assign(initVal);

        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  /// Assign a new value to this variable,
  /// will perform [HTType] check during this process.
  @override
  void assign(dynamic value) {
    if (_declType != null) {
      final encapsulation = interpreter.encapsulate(value);
      if (encapsulation.rtType.isNotA(_declType!)) {
        final valType = interpreter.encapsulate(value).rtType;
        throw HTError.typeCheck(id, valType.toString(), _declType.toString());
      }
    } else if (!isDynamic && value != null) {
      _declType = interpreter.encapsulate(value).rtType;
    }

    super.assign(value);
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  @override
  HTBytecodeVariable clone() =>
      HTBytecodeVariable(id, interpreter, moduleUniqueKey,
          classId: classId,
          value: value,
          declType: declType,
          initializerIp: initializerIp,
          getter: getter,
          setter: setter,
          isDynamic: isDynamic,
          isExtern: isExtern,
          isImmutable: isImmutable,
          isMember: isMember,
          isStatic: isStatic);
}

/// An implementation of [HTVariable] for function parameter declaration.
class HTBytecodeParameter extends HTBytecodeVariable {
  @override
  late final HTType declType;

  late final HTParameterType paramType;

  /// Create a standard [HTBytecodeParameter].
  HTBytecodeParameter(String id, Hetu interpreter, String module,
      {dynamic value,
      this.declType = HTType.ANY,
      int? initializerIp,
      bool isOptional = false,
      bool isNamed = false,
      bool isVariadic = false})
      : super(id, interpreter, module,
            value: value, initializerIp: initializerIp, isImmutable: true) {
    paramType = HTParameterType(declType.typeName,
        typeArgs: declType.typeArgs,
        isNullable: declType.isNullable,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }

  @override
  HTBytecodeParameter clone() {
    return HTBytecodeParameter(id, interpreter, moduleUniqueKey,
        value: value,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: paramType.isOptional,
        isNamed: paramType.isNamed,
        isVariadic: paramType.isVariadic);
  }
}
