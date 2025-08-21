// lib/src/state.dart
part of '../binstate.dart';

// Interface untuk objek yang bisa diserialisasi
abstract class BinarySerializable {
  void serialize(BinaryCodec codec);
  List<PropertyDescriptor> get propertyDescriptors;
}

// Abstrak untuk state yang diserialisasi dalam biner
abstract class BinaryState implements BinarySerializable {
  static const int _protocolVersion = 1;

  Uint8List toBinary() {
    final codec = BinaryCodec.encode();
    codec.writeInt(_protocolVersion);
    serialize(codec);
    final bytes = codec.toBytes();
    return bytes;
  }

  Future<void> saveToFile(String path, {bool compress = false}) async {
    final file = File(path);
    // Hapus file lama untuk menghindari konflik format
    if (await file.exists()) {
      await file.delete();
    }
    final binary = toBinary();
    final data = compress ? GZipEncoder().encode(binary) : binary;
    await file.writeAsBytes(data);
  }

  static Future<BinaryState> loadFromFile(
    String path,
    BinaryState Function(BinaryCodec) factory, {
    bool compress = false,
  }) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('File not found: $path');
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw Exception('File is empty: $path');
    final binary = compress ? GZipDecoder().decodeBytes(bytes) : bytes;
    if (binary.length < 4) throw Exception('Invalid binary data: too short to read version');
    final codec = BinaryCodec.decode(ByteData.sublistView(binary));
    final version = codec.readInt();
    if (version != _protocolVersion) throw Exception('Unsupported protocol version: $version');
    return factory(codec);
  }
}
