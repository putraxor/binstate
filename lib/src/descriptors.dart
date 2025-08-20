part of '../binstate.dart';

class PropertyDescriptor {
  final String name;
  final Type type;
  final dynamic Function(BinaryCodec) reader;
  final void Function(dynamic, BinaryCodec) writer;
  final bool isList;
  final bool isNullable;

  PropertyDescriptor({
    required this.name,
    required this.type,
    required this.reader,
    required this.writer,
    this.isList = false,
    this.isNullable = false,
  });
}
