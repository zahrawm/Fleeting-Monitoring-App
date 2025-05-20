import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:fleeting_monitoring_app/models/car_data.dart';

class CarStorageProvider with ChangeNotifier {
  static const String _boxName = 'car_data_box';
  Box<CarData>? _box;
  List<CarData> _savedCars = [];
  CarData? _lastSavedCar;

  List<CarData> get savedCars => _savedCars;
  CarData? get lastSavedCar => _lastSavedCar;

 
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<CarData>(_boxName);
    } else {
      _box = Hive.box<CarData>(_boxName);
    }
    _loadSavedCars();
  }


  void _loadSavedCars() {
    if (_box != null) {
      _savedCars = _box!.values.toList();
      _lastSavedCar = _savedCars.isNotEmpty ? _savedCars.last : null;
      notifyListeners();
    }
  }

  Future<void> saveCarData(CarData carData) async {
    if (_box != null) {
      await _box!.add(carData);
      _lastSavedCar = carData;
      _loadSavedCars();
    }
  }

 
  Future<void> saveCarDataFromMap(Map<String, dynamic> carLocationData) async {
    final carData = CarData.fromCarLocation(carLocationData);
    await saveCarData(carData);
  }

 
  Future<void> clearAllData() async {
    if (_box != null) {
      await _box!.clear();
      _loadSavedCars();
    }
  }

  Future<void> closeBox() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}