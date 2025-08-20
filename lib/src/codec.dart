// lib/src/codec.dart
part of '../binstate.dart';

// Pool untuk BytesBuilder
final _bytesBuilderPool = <BytesBuilder>[];

BytesBuilder _getBytesBuilder() {
  return _bytesBuilderPool.isNotEmpty ? _bytesBuilderPool.removeLast() : BytesBuilder();
}

void _releaseBytesBuilder(BytesBuilder builder) {
  builder.clear();
  _bytesBuilderPool.add(builder);
}

// Codec untuk serialisasi dan deserialisasi biner
class BinaryCodec {
  final BytesBuilder? _buffer;
  final ByteData? _byteData;
  int _offset = 0;

  BinaryCodec.encode() : _buffer = _getBytesBuilder(), _byteData = null;
  BinaryCodec.decode(this._byteData) : _buffer = null;

  // Map untuk tipe data primitive
  static final _typeHandlers = {
    int: _TypeHandler(
      write: (value, codec) {
        final byteData = ByteData(4);
        byteData.setInt32(0, value, Endian.little);
        codec._writeRaw(byteData.buffer.asUint8List(), 4);
      },
      read: (codec) => codec._readRaw(4, (data, offset) => data.getInt32(offset, Endian.little)),
    ),
    double: _TypeHandler(
      write: (value, codec) {
        final byteData = ByteData(8);
        byteData.setFloat64(0, value, Endian.little);
        codec._writeRaw(byteData.buffer.asUint8List(), 8);
      },
      read: (codec) => codec._readRaw(8, (data, offset) => data.getFloat64(offset, Endian.little)),
    ),
    bool: _TypeHandler(
      write: (value, codec) => codec._writeRaw([value ? 1 : 0], 1),
      read: (codec) => codec._readRaw(1, (data, offset) => data.getUint8(offset) == 1),
    ),
    String: _TypeHandler(
      write: (value, codec) {
        if (value == null) {
          codec._writeRaw([0], 1);
        } else {
          codec._writeRaw([1], 1);
          final bytes = value.codeUnits;
          codec.writeInt(bytes.length);
          codec._writeRaw(bytes, bytes.length);
        }
      },
      read: (codec) {
        if (codec._readRaw(1, (data, offset) => data.getUint8(offset)) == 0) {
          return null;
        }
        final length = codec.readInt();
        return codec._readRaw(length, (data, offset) => String.fromCharCodes(data.buffer.asUint8List(offset, length)));
      },
    ),
  };

  // Handler untuk tipe list
  static final _listHandlers = {
    double: _TypeHandler(
      write: (value, codec) {
        final list = value as List<double>;
        codec.writeInt(list.length);
        if (list.isNotEmpty) {
          final byteData = ByteData(list.length * 8);
          for (var i = 0; i < list.length; i++) {
            byteData.setFloat64(i * 8, list[i], Endian.little);
          }
          codec._writeRaw(byteData.buffer.asUint8List(), list.length * 8);
        }
      },
      read: (codec) {
        final length = codec.readInt();
        final list = <double>[];
        if (length > 0) {
          final bytes = codec._readRaw(length * 8, (data, offset) => data.buffer.asUint8List(offset, length * 8));
          final byteData = ByteData.sublistView(bytes);
          for (var i = 0; i < length; i++) {
            list.add(byteData.getFloat64(i * 8, Endian.little));
          }
        }
        return list;
      },
    ),
  };

  // Raw write/read untuk mengurangi duplikasi
  void _writeRaw(List<int> bytes, int size) {
    if (_buffer == null) throw Exception('Codec is in decode mode');
    _buffer.add(bytes);
    _offset += size; // Perbarui offset
  }

  T _readRaw<T>(int size, T Function(ByteData, int) reader) {
    if (_byteData == null) throw Exception('Codec is in encode mode');
    if (_offset + size > _byteData.lengthInBytes) {
      throw Exception('Buffer overflow: cannot read $size bytes at offset $_offset');
    }
    final value = reader(_byteData, _offset);
    _offset += size; // Perbarui offset
    return value;
  }

  // Metode publik
  void writeInt(int value) => _typeHandlers[int]!.write(value, this);
  int readInt() => _typeHandlers[int]!.read(this);

  void writeDouble(double value) => _typeHandlers[double]!.write(value, this);
  double readDouble() => _typeHandlers[double]!.read(this);

  void writeBool(bool value) => _typeHandlers[bool]!.write(value, this);
  bool readBool() => _typeHandlers[bool]!.read(this);

  void writeString(String? value) => _typeHandlers[String]!.write(value, this);
  String? readString() => _typeHandlers[String]!.read(this);

  void writeListDouble(List<double> list) => _listHandlers[double]!.write(list, this);
  List<double> readListDouble() => _listHandlers[double]!.read(this);

  void writeList<T>(List<T> list, void Function(T, BinaryCodec) writeItem) {
    writeInt(list.length);
    for (var item in list) {
      writeItem(item, this);
    }
  }

  List<T> readList<T>(T Function(BinaryCodec) readItem) {
    final length = readInt();
    final list = <T>[];
    for (var i = 0; i < length; i++) {
      list.add(readItem(this));
    }
    return list;
  }

  void writeObject<T>(T object, void Function(T, BinaryCodec) writeObject) => writeObject(object, this);
  T readObject<T>(T Function(BinaryCodec) readObject) => readObject(this);

  Uint8List toBytes() {
    if (_buffer == null) throw Exception('Codec is in decode mode');
    final bytes = _buffer.toBytes();
    _releaseBytesBuilder(_buffer);
    return bytes;
  }
}

class _TypeHandler {
  final void Function(dynamic, BinaryCodec) write;
  final dynamic Function(BinaryCodec) read;

  _TypeHandler({required this.write, required this.read});
}
