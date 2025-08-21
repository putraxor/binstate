part of '../binstate.dart';

extension PropertyDescriptorsExt on List<PropertyDescriptor> {
  Map<String, dynamic> read(BinaryCodec codec) {
    final values = <String, dynamic>{};
    for (var desc in this) {
      values[desc.name] = desc.reader(codec);
    }
    return values;
  }
}
