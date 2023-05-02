import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:test2/services/location_service.dart';
import 'package:test2/services/sensor_service.dart';
import 'package:test2/services/mongo_service.dart';

class HomeScreenPage extends StatefulWidget {
  @override
  _HomeScreenPageState createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  late MongoService _mongoService;
  List<Map<String, dynamic>>? _dataObjects;
  late String grade = '-';
  String? finalGrade;
  late int _mistakes = 0;
  late List _mistakeList = [];

  LocationService _locationService = LocationService();
  SensorService _sensorService = SensorService();
  StreamSubscription<Position>? _locationSubscription;
  var _mistakeTimestamps;

  Stopwatch _stopwatch = Stopwatch();
  Timer _timer = Timer(Duration.zero, () {});

  Position? _currentPosition;

  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    print(status);
    if (status.isGranted) {
      return true;
    } else {
      print("Location permission denied.");
      return false;
    }
  }

  bool _isTracking = false;

  void _toggleTracking() async {
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      bool granted = await requestLocationPermission();
      if (granted) {
        _startLocationUpdates();
      } else {
        setState(() {
          _isTracking = false;
        });
      }
    } else {
      _stopLocationUpdates();
      int finalGrade = 100 - (10 * _mistakeList.length);
      print(_mistakes);
      if (_mistakeList.length > 0) {
        await _mongoService.addNewLog(_mistakeList);
      }
      clearVars();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Final Grade'),
            content: Text('Your final grade is ${finalGrade}%'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _startLocationUpdates() async {
    _locationService.getLocation().then((Position? position) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });

        _locationSubscription =
            Geolocator.getPositionStream().listen((Position newPosition) async {
          setState(() {
            _currentPosition = newPosition;
          });
          await fetchData();
        });
      }
    });
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
  }

  @override
  void initState() {
    super.initState();
    initializeServices();
  }

  Future<void> initializeServices() async {
    _mongoService = await MongoService.initialize();
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _stopwatch.stop();
    _stopLocationUpdates();
    _mongoService.close();
    super.dispose();
  }

  void clearVars() {
    _mistakes = 0;
    _mistakeTimestamps = [];
    _mistakeList = [];
    grade = '-';
    finalGrade = null;
  }

  Future<void> fetchData() async {
    final dataObjects = await _mongoService.dataObjectsWithinRadius(
        _currentPosition!.longitude, _currentPosition!.latitude, 10.0);

    if (_mistakeTimestamps == null) {
      _mistakeTimestamps = [];
    }
    setState(() {
      _dataObjects = dataObjects;
      double speedInKmPerHour = _currentPosition!.speed * 3.6;
      DateTime now = DateTime.now();
      bool isMistake = false;

      if (_dataObjects != null && _dataObjects!.isNotEmpty) {
        // Check if there were at least 2 previous speeding incidents
        if (_mistakeTimestamps.length >= 2) {
          // Get the timestamps of the last 2 speeding incidents
          DateTime lastTimestamp = _mistakeTimestamps.last;
          DateTime secondLastTimestamp =
              _mistakeTimestamps[_mistakeTimestamps.length - 2];

          // Check if the current speeding incident is the same as the last one
          if (now == lastTimestamp) {
            isMistake = false;
          }
          // Check if the current speeding incident is within 2 seconds of the last one
          else if (now.difference(lastTimestamp).inSeconds <= 10) {
            isMistake = false;
          }
          // Check if the current speeding incident is within 2 seconds of the second-last one
          else if (now.difference(secondLastTimestamp).inSeconds <= 10) {
            isMistake = false;
          } else {
            // Check if the current speed is greater than the speed limit
            if (speedInKmPerHour > _dataObjects![0]['speedLimit']) {
              isMistake = true;
            } else {
              isMistake = false;
            }
          }
        } else {
          // Check if the current speed is greater than the speed limit
          if (speedInKmPerHour > _dataObjects![0]['speedLimit']) {
            isMistake = true;
          } else {
            isMistake = false;
          }
        }

        if (isMistake) {
          grade = 'F';
          _mistakes += 1;
          _mistakeTimestamps.add(now);
          setState(() {
            _mistakeList.add({
              'location': {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              },
              'type': _dataObjects![0]['type'],
              'speedLimit': _dataObjects![0]['speedLimit'],
              'speed': speedInKmPerHour,
              'timestamp': now,
            });
          });
          print("${_mistakes} &&&& ${_mistakeTimestamps}");
          print("=====");
          print(_mistakeList);
        } else {
          grade = 'P';
          print("${speedInKmPerHour} && ${_dataObjects![0]['speedLimit']}");
        }
      } else {
        // Handle the case when there are no data objects
        print("No data objects found within radius");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_currentPosition != null)
              Text(
                'Location Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            if (_currentPosition != null)
              Text(
                'Latitude: ${_currentPosition!.latitude}\nLongitude: ${_currentPosition!.longitude}',
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 30),
            if (_currentPosition != null)
              Text(
                'Speed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            if (_currentPosition != null)
              Text(
                '${(_currentPosition!.speed * 3.6).toStringAsFixed(2)} km/h',
                textAlign: TextAlign.center,
              ),
            Text(
              'Grade',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '$grade',
              textAlign: TextAlign.center,
            ),
            _dataObjects != null
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _dataObjects!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text('Data Object ${index + 1}:'),
                          subtitle: Text(
                              'Type: ${_dataObjects![index]['type']}\nSpeed Limit: ${_dataObjects![index]['speedLimit']}'),
                        );
                      },
                    ),
                  )
                : CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleTracking,
        child: _isTracking ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
    );
  }
}
