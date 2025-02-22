import '../../binding/external_class.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../../value/namespace/namespace.dart';
import '../../type/type.dart';
import '../../declaration/variable/variable_declaration.dart';

/// Variable is a binding between an symbol and a value
class HTVariable extends HTVariableDeclaration with HetuRef, GotoInfo {
  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic _value;

  var _isInitialized = false;
  var _isInitializing = false;

  HTExternalClass? externalClass;

  // var _isTypeInitialized = false;

  /// Create a standard [HTVariable].
  /// has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be acessed within a script.
  HTVariable(String id,
      {Hetu? interpreter,
      String? fileName,
      String? moduleName,
      String? classId,
      HTNamespace? closure,
      HTType? declType,
      dynamic value,
      bool isExternal = false,
      bool isStatic = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateFinalize = false,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn})
      : super(id,
            classId: classId,
            closure: closure,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            isTopLevel: isTopLevel,
            lateFinalize: lateFinalize) {
    if (interpreter != null) {
      this.interpreter = interpreter;
    }
    if (fileName != null) {
      this.fileName = fileName;
    }
    if (moduleName != null) {
      this.moduleName = moduleName;
    }
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (value != null) {
      _value = value;
      _isInitialized = true;
    }

    // if (declType != null) {
    //   _declType = declType;

    //   if (_declType is HTFunctionDeclarationType ||
    //       _declType is HTObjectType ||
    //       (HTLexicon.primitiveType.contains(declType.id))) {
    //     _isTypeInitialized = true;
    //   }
    // } else {
    //   if (!typeInferrence || (definitionIp == null)) {
    //     _declType = HTType.ANY;
    //     _isTypeInitialized = true;
    //   }
    // }
  }

  /// Initialize this variable with its declared initializer bytecode
  void initialize() {
    // if (_value != null) return;

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            filename: fileName,
            moduleName: moduleName,
            ip: definitionIp!,
            namespace: closure,
            line: definitionLine,
            column: definitionColumn);
        value = initVal;
        _isInitialized = true;
        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      value = null; // assign it even if it's null, for type check
    }
  }

  /// Assign a new value to this variable.
  @override
  set value(dynamic value) {
    if (!isMutable && _isInitialized) {
      throw HTError.immutable(id);
    }
    _value = value;
    _isInitialized = true;
  }

  @override
  dynamic get value {
    if (lateFinalize && !_isInitialized) {
      throw HTError.uninitialized(id);
    }
    if (!isExternal) {
      if (_value == null && (definitionIp != null)) {
        initialize();
      }
      return _value;
    } else {
      final externalClass = interpreter.fetchExternalClass(classId!);
      final value = externalClass.memberGet(id);
      return value;
    }
  }

  // dynamic _computeValue(dynamic value, HTType type) {
  //   final resolvedType = type.isResolved ? type : type.resolve(interpreter);

  //   if (resolvedType is HTNominalType && value is Map) {
  //     return resolvedType.klass.createInstanceFromJson(value);
  //   }

  //   // basically doing a type erasure here.
  //   if ((value is List) &&
  //       (type.id == HTLexicon.list) &&
  //       (type.typeArgs.isNotEmpty)) {
  //     final computedValueList = [];
  //     for (final item in value) {
  //       final computedValue = _computeValue(item, type.typeArgs.first);
  //       computedValueList.add(computedValue);
  //     }
  //     return computedValueList;
  //   } else if ((value is Map) &&
  //       (type.id == HTLexicon.map) &&
  //       (type.typeArgs.length >= 2)) {
  //     final mapValueTypeResolveResult = type.typeArgs[1].resolve(interpreter);
  //     if (mapValueTypeResolveResult is HTNominalType) {
  //       final computedValueMap = {};
  //       for (final entry in value.entries) {
  //         final computedValue = mapValueTypeResolveResult.klass
  //             .createInstanceFromJson(entry.value);
  //         computedValueMap[entry.key] = computedValue;
  //       }
  //       return computedValueMap;
  //     }
  //   } else {
  //     final encapsulation = interpreter.encapsulate(value);
  //     final valueType = encapsulation.valueType;
  //     if (valueType.isNotA(resolvedType)) {
  //       throw HTError.type(id, valueType.toString(), type.toString());
  //     }
  //     return value;
  //   }
  // }

  @override
  HTVariable clone() => HTVariable(id,
      interpreter: interpreter,
      fileName: fileName,
      moduleName: moduleName,
      classId: classId,
      closure: closure,
      declType: declType,
      value: _value,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isTopLevel: isTopLevel,
      lateFinalize: lateFinalize,
      definitionIp: definitionIp,
      definitionLine: definitionLine,
      definitionColumn: definitionColumn);
}
