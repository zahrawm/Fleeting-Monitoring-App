import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fleeting_monitoring_app/provider/car_storage_provider.dart';
import 'package:fleeting_monitoring_app/models/car_data.dart';
import 'package:intl/intl.dart';

class SavedCarsScreen extends StatelessWidget {
  const SavedCarsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Car Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearDataDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<CarStorageProvider>(
        builder: (context, provider, child) {
          if (provider.savedCars.isEmpty) {
            return const Center(
              child: Text(
                'No saved car data found',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Column(
            children: [
              if (provider.lastSavedCar != null)
                _buildLastSavedCarCard(provider.lastSavedCar!),
              
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
             
              Expanded(
                child: ListView.builder(
                  itemCount: provider.savedCars.length,
                  itemBuilder: (context, index) {
                    final carData = provider.savedCars[provider.savedCars.length - 1 - index];
                    return _buildCarListItem(carData);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.map),
      ),
    );
  }

  Widget _buildLastSavedCarCard(CarData carData) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Saved Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Car: ${carData.carName}'),
            Text('Latitude: ${carData.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${carData.longitude.toStringAsFixed(6)}'),
            Text('Saved: ${_formatDateTime(carData.timestamp)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCarListItem(CarData carData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        title: Text(carData.carName),
        subtitle: Text('${_formatDateTime(carData.timestamp)}\nLat: ${carData.latitude.toStringAsFixed(6)}, Lng: ${carData.longitude.toStringAsFixed(6)}'),
        isThreeLine: true,
        leading: const CircleAvatar(
          child: Icon(Icons.directions_car),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all saved car data?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CarStorageProvider>(context, listen: false).clearAllData();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}