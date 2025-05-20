import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
// At the top of the file with other imports
import 'package:intl/intl.dart';

class Car {
  final String id;
  final String name;
  final LatLng location;
  final String status;
  final String driver;
  final double speed;
  final DateTime lastUpdated;
  final List<LatLng> routeHistory;

  Car({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.driver,
    required this.speed,
    required this.lastUpdated,
    this.routeHistory = const [],
  });

  factory Car.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    double latitude = -1.94995;
    double longitude = 30.05885;
    
    if (data.containsKey('latitude') && data.containsKey('longitude')) {
      latitude = (data['latitude'] as num).toDouble();
      longitude = (data['longitude'] as num).toDouble();
    } else if (data['location'] is GeoPoint) {
      GeoPoint geoPoint = data['location'] as GeoPoint;
      latitude = geoPoint.latitude;
      longitude = geoPoint.longitude;
    } else if (data.containsKey('location') && data['location'] is Map) {
      Map<String, dynamic> locationData = data['location'] as Map<String, dynamic>;
      latitude = (locationData['latitude'] as num).toDouble();
      longitude = (locationData['longitude'] as num).toDouble();
    }

    DateTime lastUpdated = DateTime.now();
    if (data.containsKey('lastUpdated')) {
      if (data['lastUpdated'] is Timestamp) {
        lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      } else if (data['lastUpdated'] is String) {
        try {
          lastUpdated = DateFormat("MMM d, yyyy 'at' h:mm:ss a 'UTC'").parse(data['lastUpdated']);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    List<LatLng> routeHistory = [];
    if (data.containsKey('routeHistory') && data['routeHistory'] is List) {
      routeHistory = (data['routeHistory'] as List).map((point) {
        if (point is GeoPoint) {
          return LatLng(point.latitude, point.longitude);
        } else if (point is Map<String, dynamic>) {
          return LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          );
        }
        return null;
      }).where((point) => point != null).cast<LatLng>().toList();
    }

    return Car(
      id: doc.id,
      name: data['name'] ?? 'Unknown Vehicle',
      location: LatLng(latitude, longitude),
      status: data['status'] ?? 'Unknown',
      driver: data['driver'] ?? 'Unassigned',
      speed: data.containsKey('speed') ? (data['speed'] as num).toDouble() : 0.0,
      lastUpdated: lastUpdated,
      routeHistory: routeHistory,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'status': status,
      'driver': driver,
      'speed': speed,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'routeHistory': routeHistory.map((point) => GeoPoint(point.latitude, point.longitude)).toList(),
    };
  }

  String get formattedLastUpdated {
    return DateFormat('MMM d, yyyy - h:mm a').format(lastUpdated.toLocal());
  }

  Car copyWithNewLocation(LatLng newLocation) {
    List<LatLng> updatedHistory = List.from(routeHistory);
 
    updatedHistory.add(location);
    
  
    if (updatedHistory.length > 50) {
      updatedHistory = updatedHistory.skip(updatedHistory.length - 50).toList();
    }

    return Car(
      id: id,
      name: name,
      location: newLocation,
      status: status,
      driver: driver,
      speed: speed,
      lastUpdated: DateTime.now(),
      routeHistory: updatedHistory,
    );
  }
}

class CarLocationProvider with ChangeNotifier {
  List<Car> _cars = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  bool isLoading = false;
  bool _showRoutes = true; 
  String? _selectedCarId;
  StreamSubscription? _carsSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<LatLng>> _carRouteHistory = {};

  List<Car> get cars => _cars;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get showRoutes => _showRoutes;
  String? get selectedCarId => _selectedCarId;

  set mapController(GoogleMapController controller) {
    _mapController = controller;
    _updateCameraPosition();
  }

  CarLocationProvider() {
    _initializeFirestore();
  }

  @override
  void dispose() {
    _carsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeFirestore() {
    isLoading = true;
    notifyListeners();

   
    _carsSubscription = _firestore
        .collection('cars')
        .snapshots()
        .listen(
          (snapshot) {
            _handleCarUpdates(snapshot);
          },
          onError: (error) {
            print('Error listening to car updates: $error');
            isLoading = false;
            notifyListeners();
          },
        );
  }

  void _handleCarUpdates(QuerySnapshot snapshot) {
    List<Car> updatedCars = [];
    
    for (var doc in snapshot.docs) {
      Car newCar = Car.fromFirestore(doc);
      
      
      if (!_carRouteHistory.containsKey(newCar.id)) {
        _carRouteHistory[newCar.id] = [];
      }
      
      List<LatLng> existingHistory = _carRouteHistory[newCar.id]!;
    
      
      if (existingHistory.isEmpty || 
          !_isSameLocation(existingHistory.last, newCar.location)) {
        existingHistory.add(newCar.location);
        
        
        if (existingHistory.length > 100) {
          existingHistory.removeAt(0);
        }
      }
      
      Car updatedCar = Car(
        id: newCar.id,
        name: newCar.name,
        location: newCar.location,
        status: newCar.status,
        driver: newCar.driver,
        speed: newCar.speed,
        lastUpdated: newCar.lastUpdated,
        routeHistory: List.from(existingHistory),
      );
      
      updatedCars.add(updatedCar);

      
      if (_selectedCarId == newCar.id) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newCar.location)
        );
      }
    }
    
    _cars = updatedCars;
    _updateMarkers();
    _updatePolylines();
    
    isLoading = false;
    notifyListeners();
  }


  bool _isSameLocation(LatLng loc1, LatLng loc2) {
    return loc1.latitude == loc2.latitude && 
           loc1.longitude == loc2.longitude;
  }

  
  Future<void> _updateMarkers() async {
    Set<Marker> newMarkers = {};

    for (var car in _cars) {
      final icon = await _createCustomMarkerBitmap(car.status, car.speed);

      newMarkers.add(
        Marker(
          markerId: MarkerId(car.id),
          position: car.location,
          icon: icon,
          infoWindow: InfoWindow(
            title: '${car.name} (${car.id})',
            snippet: 'Status: ${car.status} • Speed: ${car.speed} km/h\n' +
                     'Location: ${car.location.latitude.toStringAsFixed(6)}, ' +
                     '${car.location.longitude.toStringAsFixed(6)}\n' +
                     'Last Updated: ${car.formattedLastUpdated}',
          ),
          onTap: () {
            selectCar(car.id);
            _mapController?.showMarkerInfoWindow(MarkerId(car.id));
          },
        ),
      );
    }

    _markers = newMarkers;
    notifyListeners();
  }

  Future<void> addCar(Car car) async {
    try {
      await _firestore.collection('cars').add(car.toFirestore());
      
      _carRouteHistory[car.id] = [car.location];
    } catch (e) {
      print('Error adding car: $e');
      throw e;
    }
  }

  Future<void> updateCar(String carId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('cars').doc(carId).update(data);
      
      
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        LatLng newLocation = LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
        
        if (!_carRouteHistory.containsKey(carId)) {
          _carRouteHistory[carId] = [];
        }
        _carRouteHistory[carId]!.add(newLocation);
        
        if (_carRouteHistory[carId]!.length > 100) {
          _carRouteHistory[carId]!.removeAt(0);
        }
      }
    } catch (e) {
      print('Error updating car: $e');
      throw e;
    }
  }

  Future<void> deleteCar(String carId) async {
    try {
      await _firestore.collection('cars').doc(carId).delete();
      _carRouteHistory.remove(carId); // Clean up route history
    } catch (e) {
      print('Error deleting car: $e');
      throw e;
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String status, double speed) async {
    Color iconColor;
    switch (status.toLowerCase()) {
      case 'available':
        iconColor = Colors.green;
        break;
      case 'moving':
      case 'in transit':
        iconColor = Colors.blue;
        break;
      case 'maintenance':
        iconColor = Colors.red;
        break;
      case 'stopped':
        iconColor = Colors.orange;
        break;
      default:
        iconColor = Colors.grey;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = iconColor;
    final double radius = 20.0;

    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '🚗',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(
      radius.toInt() * 2,
      radius.toInt() * 2,
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  void _updatePolylines() {
    Set<Polyline> newPolylines = {};

    for (var car in _cars) {
    
      List<LatLng> routePoints = _carRouteHistory[car.id] ?? car.routeHistory;
      
     
      if (routePoints.length > 1) {
        Color routeColor = _getRouteColor(car.status);
        
      
        if (_selectedCarId != null) {
          if (car.id == _selectedCarId) {
            routeColor = routeColor.withOpacity(1.0); 
            routeColor = routeColor.withOpacity(0.3); 
          }
        } else if (_showRoutes) {
          routeColor = routeColor.withOpacity(0.7); 
        } else {
          continue; 
        }

        newPolylines.add(
          Polyline(
            polylineId: PolylineId('route_${car.id}'),
            points: routePoints,
            color: routeColor,
            width: car.id == _selectedCarId ? 6 : 4, 
            patterns: car.status.toLowerCase() == 'moving' 
                ? [] 
                : [PatternItem.dash(10), PatternItem.gap(5)], 
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    }

    _polylines = newPolylines;
  }

  Color _getRouteColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'moving':
      case 'in transit':
        return Colors.blue;
      case 'maintenance':
        return Colors.red;
      case 'stopped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void toggleRouteVisibility() {
    _showRoutes = !_showRoutes;
    _updatePolylines();
    notifyListeners();
  }

  void selectCar(String carId) {
    _selectedCarId = _selectedCarId == carId ? null : carId;
    _updatePolylines();
    
    
    final selectedCar = _cars.firstWhere(
      (car) => car.id == carId,
      orElse: () => _cars.first,
    );
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selectedCar.location, 16.0),
    );
    
    notifyListeners();
  }

  void clearSelectedCar() {
    _selectedCarId = null;
    _updatePolylines();
    notifyListeners();
  }

  void clearCarRoute(String carId) {
    if (_carRouteHistory.containsKey(carId)) {
      
      Car? car = _cars.firstWhere(
        (c) => c.id == carId,
        orElse: () => null as Car, 
      );
      if (car != null) {
        _carRouteHistory[carId] = [car.location];
      } else {
        _carRouteHistory[carId] = [];
      }
    }
    _updatePolylines();
    notifyListeners();
  }

  void clearAllRoutes() {
   
    for (var car in _cars) {
      _carRouteHistory[car.id] = [car.location];
    }
    _updatePolylines();
    notifyListeners();
  }

  void _updateCameraPosition() {
    if (_mapController == null || _cars.isEmpty) return;

    if (_cars.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_cars.first.location, 15),
      );
      return;
    }

   
    double minLat = _cars.first.location.latitude;
    double maxLat = _cars.first.location.latitude;
    double minLng = _cars.first.location.longitude;
    double maxLng = _cars.first.location.longitude;

    for (var car in _cars) {
      if (car.location.latitude < minLat) minLat = car.location.latitude;
      if (car.location.latitude > maxLat) maxLat = car.location.latitude;
      if (car.location.longitude < minLng) minLng = car.location.longitude;
      if (car.location.longitude > maxLng) maxLng = car.location.longitude;
    }

    
    final padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, 
      ),
    );
  }

  void showCarDetails(String carId) {
    if (_mapController == null) return;

    final car = _cars.firstWhere(
      (car) => car.id == carId,
      orElse: () => _cars.first,
    );

    selectCar(carId);
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(car.location, 17));
    _mapController!.showMarkerInfoWindow(MarkerId(carId));
  }

  void refreshCarLocations() {
    isLoading = true;
    notifyListeners();

   
    _firestore
        .collection('cars')
        .get()
        .then((snapshot) {
          _handleCarUpdates(snapshot);
        })
        .catchError((error) {
          print('Error refreshing car locations: $error');
          isLoading = false;
          notifyListeners();
        });
  }
  
 
  Future<void> updateCarLocation(String carId, LatLng newLocation) async {
    try {
      await _firestore.collection('cars').doc(carId).update({
        'latitude': newLocation.latitude,
        'longitude': newLocation.longitude,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating car location: $e');
      throw e;
    }
  }
  
  List<Car> searchCars(String query) {
    if (query.isEmpty) {
      return _cars;
    }
    
    final lowercaseQuery = query.toLowerCase().trim();
    
    return _cars.where((car) {
      final carId = car.id.toLowerCase();
      final carName = car.name.toLowerCase();
      final carStatus = car.status.toLowerCase();
      final carDriver = car.driver.toLowerCase();
      
      return carId.contains(lowercaseQuery) ||
             carName.contains(lowercaseQuery) ||
             carStatus.contains(lowercaseQuery) ||
             carDriver.contains(lowercaseQuery);
    }).toList();
  }
}