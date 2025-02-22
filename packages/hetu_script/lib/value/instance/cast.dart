import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
import '../../type/nominal_type.dart';
import '../class/class.dart';
import '../entity.dart';
import 'instance.dart';

/// The implementation of a certain type cast of a object
class HTCast with HTEntity, HetuRef {
  @override
  final HTNominalType valueType;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTEntity castee, this.klass, Hetu interpreter,
      {List<HTType> typeArgs = const []})
      : valueType = HTNominalType(klass, typeArgs: typeArgs) {
    this.interpreter = interpreter;
    // final extended = <HTType>[];

    // HTClass? curSuper = klass;
    // var superClassType = HTType(klass.id, typeArgs: typeArgs);
    // while (curSuper != null) {
    // extended.add(superClassType);
    // curSuper = curSuper.superClass;
    // if (curSuper?.extendedType != null) {
    //   extended.add(curSuper!.extendedType!);
    // }
    // }

    if (castee.valueType.isNotA(valueType)) {
      throw HTError.typeCast(castee.valueType.toString(), valueType.toString());
    }

    if (castee is HTInstance) {
      object = castee;
    } else if (castee is HTCast) {
      object = castee.object;
    } else {
      throw HTError.castee(interpreter.localSymbol!);
    }
  }

  @override
  dynamic memberGet(String varName, {String? from}) =>
      object.memberGet(varName, cast: klass.id, from: from);

  @override
  void memberSet(String varName, dynamic varValue, {String? from}) =>
      object.memberSet(varName, varValue, cast: klass.id, from: from);
}
