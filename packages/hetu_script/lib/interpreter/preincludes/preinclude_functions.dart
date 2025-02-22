import 'dart:convert';

import '../../value/entity.dart';
import '../../type/type.dart';
import '../../shared/jsonify.dart';
import '../../shared/stringify.dart';
import '../../value/struct/struct.dart';
import '../../value/instance/instance.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> preincludeFunctions = {
  'print': (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      print(positionalArgs.map((e) => stringify(e)).join(' ')),
  'stringify': (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      stringify(positionalArgs.first),
  'jsonify': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return jsonifyStruct(object);
    } else if (object is Iterable) {
      return jsonifyList(object);
    } else if (isJsonDataType(object)) {
      return stringify(object);
    } else {
      return jsonEncode(object);
    }
  },
  'range': (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      [
        for (var i = positionalArgs[1];
            i < positionalArgs[0];
            i += positionalArgs[2])
          i
      ],
  'prototype.keys': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.keys;
  },
  'prototype.values': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.values;
  },
  'prototype.contains': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.contains(positionalArgs.first);
  },
  'prototype.containsKey': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.containsKey(positionalArgs.first);
  },
  'prototype.isEmpty': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.isEmpty;
  },
  'prototype.isNotEmpty': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.isNotEmpty;
  },
  'prototype.length': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.length;
  },
  'prototype.clone': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.clone();
  },
  'prototype.assign': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    final other = positionalArgs.first as HTStruct;
    obj.assign(other);
  },
  'object.toString': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTInstance).getTypeString();
  },
};
