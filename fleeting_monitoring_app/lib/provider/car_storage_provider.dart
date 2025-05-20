import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:fleeting_monitoring_app/models/car_data.dart';

class CarStorageProvider with ChangeNotifier {
  static const String _boxName = 'car_data_box';
  Box<CarData>? _box;
  List<CarData> _savedCars = [];
  CarData? _lastSavedCar;
  String? _errorMessage;
  bool _isLoading = false;

  List<CarData> get savedCars => _savedCars;
  CarData? get lastSavedCar => _lastSavedCar;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

 
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

 
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
 
  Future<void> init() async {
    _setLoading(true);
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<CarData>(_boxName);
      } else {
        _box = Hive.box<CarData>(_boxName);
      }
      _loadSavedCars();
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to initialize storage: ${e.toString()}');
      if (kDebugMode) {
        print('Error initializing CarStorageProvider: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void _loadSavedCars() {
    if (_box != null) {
      try {
        _savedCars = _box!.values.toList();
        _lastSavedCar = _savedCars.isNotEmpty ? _savedCars.last : null;
        notifyListeners();
      } catch (e) {
        _setError('Failed to load saved cars: ${e.toString()}');
        if (kDebugMode) {
          print('Error loading saved cars: $e');
        }
      }
    }
  }

  Future<bool> saveCarData(CarData carData) async {
    _setLoading(true);
    try {
      if (_box != null) {
        await _box!.add(carData);
        _lastSavedCar = carData;
        _loadSavedCars();
        return true;
      } else {
        _setError('Storage not initialized');
        return false;
      }
    } catch (e) {
      _setError('Failed to save car data: ${e.toString()}');
      if (kDebugMode) {
        print('Error saving car data: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
 
  Future<bool> saveCarDataFromMap(Map<String, dynamic> carLocationData) async {
    _setLoading(true);
    try {
      final carData = CarData.fromCarLocation(carLocationData);
      return await saveCarData(carData);
    } catch (e) {
      _setError('Failed to process car data: ${e.toString()}');
      if (kDebugMode) {
        print('Error processing car data from map: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
 
  Future<bool> clearAllData() async {
    _setLoading(true);
    try {
      if (_box != null) {
        await _box!.clear();
        _loadSavedCars();
        return true;
      } else {
        _setError('Storage not initialized');
        return false;
      }
    } catch (e) {
      _setError('Failed to clear data: ${e.toString()}');
      if (kDebugMode) {
        print('Error clearing all data: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeBox() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
    } catch (e) {
      _setError('Failed to close storage: ${e.toString()}');
      if (kDebugMode) {
        print('Error closing box: $e');
      }
    }
  }
}