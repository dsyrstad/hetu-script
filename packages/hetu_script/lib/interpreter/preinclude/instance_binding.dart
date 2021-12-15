part of '../abstract_interpreter.dart';

extension IntBinding on int {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'toStringAsFixed':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'modPow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modInverse(positionalArgs[0]);
      case 'gcd':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gcd(positionalArgs[0]);
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'bitLength':
        return bitLength;
      case 'toUnsigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSigned(positionalArgs[0]);
      case 'abs':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            abs();
      case 'sign':
        return sign;
      case 'round':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            round();
      case 'floor':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floor();
      case 'ceil':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceil();
      case 'truncate':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncate();
      case 'roundToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            roundToDouble();
      case 'floorToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floorToDouble();
      case 'ceilToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceilToDouble();
      case 'truncateToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncateToDouble();
      case 'toRadixString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toRadixString(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension BigIntBinding on BigInt {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'bitLength':
        return bitLength;
      case 'sign':
        return sign;
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'isNegative':
        return isNegative;
      case 'pow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            pow(positionalArgs.first);
      case 'modPow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modInverse(positionalArgs.first);
      case 'gcd':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gcd(positionalArgs.first);
      case 'toUnsigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUnsigned(positionalArgs.first);
      case 'toSigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSigned(positionalArgs.first);
      case 'isValidInt':
        return isValidInt;
      case 'toInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toInt();
      case 'toDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toDouble();
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'toRadixString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toRadixString(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension DoubleBinding on double {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'toStringAsFixed':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'abs':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            abs();
      case 'sign':
        return sign;
      case 'round':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            round();
      case 'floor':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floor();
      case 'ceil':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceil();
      case 'truncate':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncate();
      case 'roundToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            roundToDouble();
      case 'floorToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floorToDouble();
      case 'ceilToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceilToDouble();
      case 'truncateToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncateToDouble();
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension StringBinding on String {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'compareTo':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            codeUnitAt(positionalArgs[0]);
      case 'length':
        return length;
      case 'endsWith':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            endsWith(positionalArgs[0]);
      case 'startsWith':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'substring':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trim();
      case 'trimLeft':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimLeft();
      case 'trimRight':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimRight();
      case 'padLeft':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceFirst(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            split(positionalArgs[0]);
      case 'toLowerCase':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toLowerCase();
      case 'toUpperCase':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUpperCase();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart list.
extension ListBinding on List {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            stringify(this);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'contains':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs.first);
      case 'elementAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            elementAt(positionalArgs.first);
      case 'join':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            join(positionalArgs.first);
      case 'first':
        return first;
      case 'last':
        return last;
      case 'length':
        return length;
      case 'add':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            add(positionalArgs.first);
      case 'addAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'reversed':
        return reversed;
      case 'indexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      case 'removeAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeAt(positionalArgs.first);
      case 'removeLast':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeLast();
      case 'sublist':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            asMap();
      case 'sort':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          sort((a, b) {
            return func.call(positionalArgs: [a, b]) as int;
          });
        };
      case 'shuffle':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            shuffle();
      case 'indexWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          int start = 0;
          if (positionalArgs.length >= 2) {
            start = positionalArgs[1];
          }
          indexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'lastIndexWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          int? start = positionalArgs[1];
          lastIndexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'removeWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'getRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            getRange(positionalArgs[0], positionalArgs[1]);
      case 'setRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            setRange(positionalArgs[0], positionalArgs[1], positionalArgs[2],
                positionalArgs[3]);
      case 'removeRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeRange(positionalArgs[0], positionalArgs[1]);
      case 'fillRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            fillRange(positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'map':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          map((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'where':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          where((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'expand':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          expand((element) {
            return func.call(positionalArgs: [element]) as Iterable;
          });
        };
      case 'reduce':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          reduce((value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'fold':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final initialValue = positionalArgs[0];
          HTFunction func = positionalArgs[1];
          fold(initialValue, (value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'every':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          every((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'any':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          any((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'firstWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs[0];
          HTFunction? orElse = positionalArgs[1];
          firstWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'lastWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs[0];
          HTFunction? orElse = positionalArgs[1];
          lastWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'singleWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs[0];
          HTFunction? orElse = positionalArgs[1];
          singleWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      default:
        throw HTError.undefined(varName);
    }
  }

  dynamic htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'first':
        first = varValue;
        break;
      case 'last':
        last = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart map.
extension MapBinding on Map {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'keys':
        return keys.toList();
      case 'values':
        return values.toList();
      case 'containsKey':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsKey(positionalArgs.first);
      case 'containsValue':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsValue(positionalArgs.first);
      case 'addAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'clear':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart future.
extension FutureBinding on Future {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'then':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          then((value) {
            func.call(positionalArgs: [value]);
          });
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}
