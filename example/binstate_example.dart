import 'dart:io';
import 'package:binstate/binstate.dart';

class Point implements BinarySerializable {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  void serialize(BinaryCodec codec) {
    codec.writeInt(x); // Tulis x secara langsung
    codec.writeInt(y); // Tulis y secara langsung
    print('Serialized Point: x=$x, y=$y'); // Debug
  }

  @override
  List<PropertyDescriptor> getPropertyDescriptors() => [
    PropertyDescriptor(
      name: 'x',
      type: int,
      reader: (codec) => codec.readInt(),
      writer: (obj, codec) => codec.writeInt((obj as Point).x),
    ),
    PropertyDescriptor(
      name: 'y',
      type: int,
      reader: (codec) => codec.readInt(),
      writer: (obj, codec) => codec.writeInt((obj as Point).y),
    ),
  ];

  static Point deserialize(BinaryCodec codec) {
    final x = codec.readInt();
    final y = codec.readInt();
    print('Deserialized Point: x=$x, y=$y'); // Debug
    return Point(x, y);
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class RobotState extends BinaryState {
  final int id;
  final double positionX;
  final double positionY;
  final bool isActive;
  final String? name;
  final List<double> coordinates;
  final List<String?> commandLog;
  final Point point;

  RobotState({
    required this.id,
    required this.positionX,
    required this.positionY,
    required this.isActive,
    this.name,
    required this.coordinates,
    required this.commandLog,
    required this.point,
  });

  @override
  void serialize(BinaryCodec codec) {
    for (var desc in getPropertyDescriptors()) {
      desc.writer(this, codec);
    }
  }

  @override
  List<PropertyDescriptor> getPropertyDescriptors() => [
    PropertyDescriptor(
      name: 'id',
      type: int,
      reader: (codec) => codec.readInt(),
      writer: (obj, codec) => codec.writeInt((obj as RobotState).id),
    ),
    PropertyDescriptor(
      name: 'positionX',
      type: double,
      reader: (codec) => codec.readDouble(),
      writer: (obj, codec) => codec.writeDouble((obj as RobotState).positionX),
    ),
    PropertyDescriptor(
      name: 'positionY',
      type: double,
      reader: (codec) => codec.readDouble(),
      writer: (obj, codec) => codec.writeDouble((obj as RobotState).positionY),
    ),
    PropertyDescriptor(
      name: 'isActive',
      type: bool,
      reader: (codec) => codec.readBool(),
      writer: (obj, codec) => codec.writeBool((obj as RobotState).isActive),
    ),
    PropertyDescriptor(
      name: 'name',
      type: String,
      reader: (codec) => codec.readString(),
      writer: (obj, codec) => codec.writeString((obj as RobotState).name),
      isNullable: true,
    ),
    PropertyDescriptor(
      name: 'coordinates',
      type: List,
      reader: (codec) => codec.readListDouble(),
      writer: (obj, codec) => codec.writeListDouble((obj as RobotState).coordinates),
      isList: true,
    ),
    PropertyDescriptor(
      name: 'commandLog',
      type: List,
      reader: (codec) => codec.readList((c) => c.readString()),
      writer: (obj, codec) => codec.writeList((obj as RobotState).commandLog, (item, c) => c.writeString(item)),
      isList: true,
      isNullable: true,
    ),
    PropertyDescriptor(
      name: 'point',
      type: Point,
      reader: (codec) => Point.deserialize(codec),
      writer: (obj, codec) {
        final p = (obj as RobotState).point;
        p.serialize(codec); // Pastikan serialize dipanggil
      },
    ),
  ];

  static RobotState deserialize(BinaryCodec codec) {
    final descriptors = RobotState(
      id: 0,
      positionX: 0,
      positionY: 0,
      isActive: false,
      coordinates: [],
      commandLog: [],
      point: Point(0, 0),
    ).getPropertyDescriptors();
    final values = <String, dynamic>{};
    for (var desc in descriptors) {
      values[desc.name] = desc.reader(codec);
    }
    return RobotState(
      id: values['id'],
      positionX: values['positionX'],
      positionY: values['positionY'],
      isActive: values['isActive'],
      name: values['name'],
      coordinates: values['coordinates'],
      commandLog: values['commandLog'],
      point: values['point'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'positionX': positionX,
    'positionY': positionY,
    'isActive': isActive,
    'name': name,
    'coordinates': coordinates,
    'commandLog': commandLog,
    'point': point.toJson(),
  };
}

void main(List<String> arguments) async {
  final enableCompression = arguments.isNotEmpty && arguments[0] == 'compress';
  print('Compression enabled: $enableCompression');

  final filename = 'robot_state.${enableCompression ? 'gz' : 'bin'}';
  final robot = RobotState(
    id: 1,
    positionX: 10.5,
    positionY: 20.3,
    isActive: true,
    name: null,
    coordinates: List.generate(10, (index) => 1.0),
    commandLog: ["move_forward", null, "stop"],
    point: Point(5, 10),
  );

  final jsonFilename = 'robot_state.json';
  final jsonFile = File(jsonFilename);
  if (await jsonFile.exists()) {
    await jsonFile.delete();
  }
  await jsonFile.writeAsString(robot.toJson().toString());

  final stopwatch = Stopwatch()..start();
  await robot.saveToFile(filename, compress: enableCompression);
  print('Save time: ${stopwatch.elapsedMicroseconds} µs');
  stopwatch.reset();
  final loadedRobot =
      await BinaryState.loadFromFile(filename, RobotState.deserialize, compress: enableCompression) as RobotState;
  print('Load time: ${stopwatch.elapsedMicroseconds} µs');

  print('ID: ${loadedRobot.id}');
  print('Position X: ${loadedRobot.positionX}');
  print('Position Y: ${loadedRobot.positionY}');
  print('Is Active: ${loadedRobot.isActive}');
  print('Name: ${loadedRobot.name}');
  print('Coordinates: ${loadedRobot.coordinates.length} items');
  print('Command Log: ${loadedRobot.commandLog}');
  print('Point: (${loadedRobot.point.x}, ${loadedRobot.point.y})');

  print('-' * 40);
  print('Comparison with JSON:');
  final binaryFile = File(filename);
  final binarySize = await binaryFile.length();
  print('Binary file size: $binarySize bytes');
  final jsonSize = await jsonFile.length();
  print('JSON file size: $jsonSize bytes');
  print('JSON size ${(jsonSize / binarySize).round()} times larger');
  final pctDifference = ((binarySize - jsonSize) / jsonSize * 100).abs();
  print('Binary size is ${pctDifference.toStringAsFixed(2)}% smaller than JSON size');
}
