import 'package:hive/hive.dart';

part 'car_data.g.dart';

@HiveType(typeId: 0)
class CarData extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final String carName;

  @HiveField(4)
  final DateTime timestamp;

  CarData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.carName,
    required this.timestamp,
  });


  factory CarData.fromCarLocation(Map<String, dynamic> data) {
    return CarData(
      id: data['id'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      carName: data['carName'] ?? 'Unknown',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'carName': carName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}