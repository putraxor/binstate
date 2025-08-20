# BinState

A lightweight Dart library for efficient binary serialization and deserialization of objects, with optional GZIP compression.

## Features
- Compact binary serialization
- GZIP compression support
- Handles `int`, `double`, `bool`, `String`, `List<double>`, `List<String?>`, and custom objects
- Nullable fields
- Memory-efficient with `BytesBuilder` pooling
- Robust error handling and protocol versioning

## Performance
For a `RobotState` with a `List<double>` of 10,000 constant values:
- Binary size: ~217 bytes (uncompressed)
- JSON size: ~50,146 bytes
- Binary is 99.57% smaller than JSON
- Save time: ~15,550 µs
- Load time: ~10,541 µs

## Installation
Add to `pubspec.yaml`:
```yaml
dependencies:
  binstate: ^1.0.0
```
Run:
```bash
dart pub get
```

## Usage
```dart
import 'package:binstate/binstate.dart';

class Point implements BinarySerializable {
  final int x, y;
  Point(this.x, this.y);

  @override
  void serialize(BinaryCodec codec) {
    for (var desc in getPropertyDescriptors()) {
      desc.writer(this, codec);
    }
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
    final descriptors = Point(0, 0).getPropertyDescriptors();
    final values = <String, dynamic>{};
    for (var desc in descriptors) {
      values[desc.name] = desc.reader(codec);
    }
    return Point(values['x'], values['y']);
  }
}

class RobotState extends BinaryState {
  final int id;
  final double positionX, positionY;
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
  List<PropertyDescriptors> getPropertyDescriptors() => [
        PropertyDescriptor(
          name: 'id',
          type: int,
          reader: (codec) => codec.readInt(),
          writer: (obj, codec) => codec.writeInt((obj as RobotState).id),
        ),
        // Other descriptors...
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
}

void main() async {
  final robot = RobotState(
    id: 1,
    positionX: 10.5,
    positionY: 20.3,
    isActive: true,
    name: null,
    coordinates: List.generate(10000, (_) => 1.0),
    commandLog: ["move_forward", null, "stop"],
    point: Point(5, 10),
  );

  await robot.saveToFile('robot_state.bin', compress: true);
  final loadedRobot = await BinaryState.loadFromFile('robot_state.bin', RobotState.deserialize, compress: true);
  print('ID: ${loadedRobot.id}, Coordinates: ${loadedRobot.coordinates.length} items');
}
```

## Notes
- Use `compress: false` for faster processing with small or random data.
- Best compression with repetitive data (e.g., constant lists).
