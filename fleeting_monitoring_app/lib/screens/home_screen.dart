import 'package:fleeting_monitoring_app/models/car_data.dart';
import 'package:fleeting_monitoring_app/provider/car_storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fleeting_monitoring_app/provider/car_location_provider.dart';

import 'package:fleeting_monitoring_app/widgets/button.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<Car> _filteredCars = [];
  bool _isSearching = false;
  Car? _selectedCar;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCars);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carProvider = Provider.of<CarLocationProvider>(
        context,
        listen: false,
      );
      setState(() {
        _filteredCars = carProvider.cars;
      });

      _autoRefreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
        if (mounted) {
          carProvider.refreshCarLocations();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCars);
    _searchController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final carProvider = Provider.of<CarLocationProvider>(
      context,
      listen: false,
    );
    carProvider.mapController = controller;

    carProvider.refreshCarLocations();
  }

  void _filterCars() {
    final carProvider = Provider.of<CarLocationProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _filteredCars = carProvider.cars;
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;

        _filteredCars = carProvider.searchCars(query);
      });
    }
  }

  void _selectCar(Car car) {
    setState(() {
      _selectedCar = car;
      _isSearching = false;
    });

    final carProvider = Provider.of<CarLocationProvider>(
      context,
      listen: false,
    );
    carProvider.selectCar(car.id);
    _searchController.clear();
  }

  void _clearSelectedCar() {
    setState(() {
      _selectedCar = null;
    });

    Provider.of<CarLocationProvider>(context, listen: false).clearSelectedCar();
  }

  void _showSimulateMovementDialog(Car car) {
    final TextEditingController latController = TextEditingController(
      text: car.location.latitude.toStringAsFixed(6),
    );
    final TextEditingController lngController = TextEditingController(
      text: car.location.longitude.toStringAsFixed(6),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Simulate Movement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Location:\n${car.location.latitude.toStringAsFixed(6)}, ${car.location.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              TextField(
                controller: latController,
                decoration: InputDecoration(
                  labelText: 'New Latitude',
                  hintText: 'e.g. -1.949950',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 8),
              TextField(
                controller: lngController,
                decoration: InputDecoration(
                  labelText: 'New Longitude',
                  hintText: 'e.g. 30.058850',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (latController.text.isNotEmpty &&
                    lngController.text.isNotEmpty) {
                  try {
                    final newLat = double.parse(latController.text);
                    final newLng = double.parse(lngController.text);
                    final newLocation = LatLng(newLat, newLng);

                    await Provider.of<CarLocationProvider>(
                      context,
                      listen: false,
                    ).updateCarLocation(car.id, newLocation);

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Car location updated successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invalid coordinates: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Update Location'),
            ),
          ],
        );
      },
    );
  }

  Set<Marker> _getFilteredMarkers(CarLocationProvider carProvider) {
    if (!_isSearching || _searchController.text.isEmpty) {
      return carProvider.markers;
    }

    Set<String> filteredCarIds = _filteredCars.map((car) => car.id).toSet();

    return carProvider.markers.where((marker) {
      return filteredCarIds.contains(marker.markerId.value);
    }).toSet();
  }

  Set<Polyline> _getFilteredPolylines(CarLocationProvider carProvider) {
    if (!_isSearching || _searchController.text.isEmpty) {
      return carProvider.polylines;
    }

    Set<String> filteredCarIds = _filteredCars.map((car) => car.id).toSet();

    return carProvider.polylines.where((polyline) {
      String polylineId = polyline.polylineId.value;
      String carId = polylineId.replaceFirst('route_', '');
      return filteredCarIds.contains(carId);
    }).toSet();
  }

  void _saveCurrentLocation() {
    final carProvider = Provider.of<CarLocationProvider>(
      context,
      listen: false,
    );
    final storageProvider = Provider.of<CarStorageProvider>(
      context,
      listen: false,
    );

    final cars = carProvider.cars;

    if (cars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cars available to save')),
      );
      return;
    }

  
    if (_selectedCar != null) {
      _saveSingleCar(_selectedCar!, storageProvider);
    } else {
     
      for (var car in cars) {
        _saveSingleCar(car, storageProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All car locations saved locally')),
      );
    }
  }

  void _saveSingleCar(Car car, CarStorageProvider storageProvider) {
    try {
      final carData = CarData(
        id: car.id,
        carName: car.name,
        latitude: car.location.latitude,
        longitude: car.location.longitude,
        
        timestamp: DateTime.now(),
      );

     
      if (_selectedCar != null && _selectedCar!.id == car.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${car.name} location saved locally')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving car data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToSavedCars() {
    Navigator.of(context).pushNamed('/saved_cars');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<CarLocationProvider>(
                context,
                listen: false,
              ).refreshCarLocations();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing car locations...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a car by ID, name, driver or status',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                Consumer<CarLocationProvider>(
                  builder: (context, carProvider, child) {
                    return GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target:
                            carProvider.cars.isNotEmpty
                                ? carProvider.cars.first.location
                                : LatLng(-1.94995, 30.05885),
                        zoom: 14,
                      ),

                      markers: _getFilteredMarkers(carProvider),
                      polylines: _getFilteredPolylines(carProvider),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapToolbarEnabled: true,
                      zoomControlsEnabled: true,
                      onTap: (_) {
                        _clearSelectedCar();
                      },
                    );
                  },
                ),

                Consumer<CarLocationProvider>(
                  builder: (context, carProvider, child) {
                    if (carProvider.isLoading) {
                      return Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                if (_isSearching)
                  Positioned(
                    top: 10,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_filteredCars.length} car(s) found',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),

                if (_isSearching && _filteredCars.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredCars.length,
                        itemBuilder: (context, index) {
                          final car = _filteredCars[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(car.status),
                              child: Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                            ),
                            title: Text('${car.name} (${car.id})'),
                            subtitle: Text(
                              'Driver: ${car.driver} • Status: ${car.status}',
                            ),
                            onTap: () => _selectCar(car),
                          );
                        },
                      ),
                    ),
                  ),

                if (_isSearching && _filteredCars.isEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Text(
                        'No cars found matching "${_searchController.text}"',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                if (_selectedCar != null)
                  Positioned(
                    bottom: 120,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCar!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text('ID: ${_selectedCar!.id}'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: _clearSelectedCar,
                              ),
                            ],
                          ),
                          Divider(),
                          _detailRow('Driver', _selectedCar!.driver),
                          _detailRow('Status', _selectedCar!.status),
                          _detailRow('Speed', '${_selectedCar!.speed} km/h'),
                          _detailRow(
                            'Last updated',
                            _selectedCar!.formattedLastUpdated,
                          ),
                          _detailRow(
                            'Location',
                            '${_selectedCar!.location.latitude.toStringAsFixed(6)}, ${_selectedCar!.location.longitude.toStringAsFixed(6)}',
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(Icons.map),
                                label: Text('Show Route'),
                                onPressed: () {
                                  Provider.of<CarLocationProvider>(
                                    context,
                                    listen: false,
                                  ).selectCar(_selectedCar!.id);
                                },
                              ),
                              SizedBox(width: 8),
                              TextButton.icon(
                                icon: Icon(Icons.clear_all),
                                label: Text('Clear Route'),
                                onPressed: () {
                                  Provider.of<CarLocationProvider>(
                                    context,
                                    listen: false,
                                  ).clearCarRoute(_selectedCar!.id);
                                },
                              ),
                              SizedBox(width: 8),
                              TextButton.icon(
                                icon: Icon(Icons.edit_location_alt),
                                label: Text('Simulate'),
                                onPressed:
                                    () => _showSimulateMovementDialog(
                                      _selectedCar!,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Consumer<CarLocationProvider>(
            builder: (context, carProvider, child) {
              List<Car> carsToCount =
                  _isSearching ? _filteredCars : carProvider.cars;

              int movingCount =
                  carsToCount
                      .where((car) => car.status.toLowerCase() == 'moving')
                      .length;
              int availableCount =
                  carsToCount
                      .where((car) => car.status.toLowerCase() == 'available')
                      .length;
              int maintenanceCount =
                  carsToCount
                      .where((car) => car.status.toLowerCase() == 'maintenance')
                      .length;
              int stoppedCount =
                  carsToCount
                      .where((car) => car.status.toLowerCase() == 'stopped')
                      .length;

              return Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Showing statistics for filtered results',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatusIndicator(
                          'Available',
                          Colors.green,
                          availableCount,
                        ),
                        _buildStatusIndicator(
                          'Moving',
                          Colors.blue,
                          movingCount,
                        ),
                        _buildStatusIndicator(
                          'Stopped',
                          Colors.orange,
                          stoppedCount,
                        ),
                        _buildStatusIndicator(
                          'Maintenance',
                          Colors.red,
                          maintenanceCount,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MyButton(
                            text:
                                carProvider.showRoutes
                                    ? 'Hide Routes'
                                    : 'Show Routes',
                            color: Colors.blueAccent,
                            onPressed: () {
                              carProvider.toggleRouteVisibility();
                              setState(() {});
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: MyButton(
                            text: 'Clear All Routes',
                            color: Colors.redAccent,
                            onPressed: () {
                              carProvider.clearAllRoutes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('All routes cleared')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveCurrentLocation,
                            child: Text('Save Current Location'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _navigateToSavedCars,
                            child: Text('View Saved Locations'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCarDialog(context),
        tooltip: 'Add New Vehicle',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showAddCarDialog(BuildContext context) {
    final nameController = TextEditingController();
    final driverController = TextEditingController();
    String selectedStatus = 'Available';
    double speed = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Name',
                    hintText: 'e.g. Toyota Camry',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: driverController,
                  decoration: InputDecoration(
                    labelText: 'Driver ID',
                    hintText: 'e.g. driver123',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(labelText: 'Status'),
                  items:
                      ['Available', 'Moving', 'Stopped', 'Maintenance']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    selectedStatus = value!;

                    if (value.toLowerCase() == 'moving') {
                      speed = 45.0;
                    } else {
                      speed = 0.0;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addNewCar(
                    context,
                    nameController.text,
                    selectedStatus,
                    driverController.text.isEmpty
                        ? 'Unassigned'
                        : driverController.text,
                    speed,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNewCar(
    BuildContext context,
    String name,
    String status,
    String driver,
    double speed,
  ) {
    LatLng location =
        _mapController?.cameraPosition?.target ?? LatLng(-1.94995, 30.05885);

    final newCar = Car(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      status: status,
      driver: driver,
      speed: speed,
      lastUpdated: DateTime.now(),
    );

    try {
      Provider.of<CarLocationProvider>(context, listen: false).addCar(newCar);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('New vehicle added successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add vehicle: $e')));
    }
  }

  Widget _buildStatusIndicator(String status, Color color, int count) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 4),
            Text(status),
          ],
        ),
        SizedBox(height: 4),
        Text('$count cars', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(String status) {
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
}

extension GoogleMapControllerExtension on GoogleMapController? {
  CameraPosition? get cameraPosition => null;
}
