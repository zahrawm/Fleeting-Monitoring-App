// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CarDataAdapter extends TypeAdapter<CarData> {
  @override
  final int typeId = 0;

  @override
  CarData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CarData(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      carName: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CarData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.carName)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
