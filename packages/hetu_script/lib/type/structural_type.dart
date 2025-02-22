import '../value/entity.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';
import '../value/namespace/namespace.dart';

/// A type checks interfaces rather than type ids.
class HTStructuralType extends HTType with HTEntity {
  late final Map<String, HTType> fieldTypes;

  HTStructuralType(HTNamespace closure,
      {Map<String, HTType> fieldTypes = const {}})
      : super(HTLexicon.kStruct) {
    this.fieldTypes =
        fieldTypes.map((key, value) => MapEntry(key, value.resolve(closure)));
  }

  @override
  String toString() {
    var output = StringBuffer();
    output.write('${HTLexicon.kStruct} ');
    if (fieldTypes.isEmpty) {
      output.write('${HTLexicon.bracesLeft}${HTLexicon.bracesRight}');
    } else {
      output.writeln(HTLexicon.bracesLeft);
      for (var i = 0; i < fieldTypes.length; ++i) {
        final key = fieldTypes.keys.elementAt(i);
        output.write('  $key${HTLexicon.colon}');
        final fieldTypeString = fieldTypes[key].toString();
        output.write(' $fieldTypeString');
        if (i < fieldTypes.length - 1) {
          output.write(HTLexicon.comma);
        }
        output.writeln();
      }
      output.write(HTLexicon.bracesRight);
    }
    return output.toString();
  }

  @override
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other == HTType.any) {
      return true;
    } else if (other is HTStructuralType) {
      if (other.fieldTypes.isEmpty) {
        return true;
      } else {
        if (other.fieldTypes.length != fieldTypes.length) {
          return false;
        } else {
          for (final key in other.fieldTypes.keys) {
            if (!fieldTypes.containsKey(key)) {
              return false;
            } else {
              if (fieldTypes[key]!.isNotA(other.fieldTypes[key])) {
                return false;
              }
            }
          }
          return true;
        }
      }
    } else {
      return false;
    }
  }
}
