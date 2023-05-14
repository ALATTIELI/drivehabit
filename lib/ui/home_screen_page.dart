import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:test2/services/location_service.dart';
import 'package:test2/services/sensor_service.dart';
import 'package:test2/services/mongo_service.dart';
import 'package:test2/ui/profile_screen_page.dart';

import '../models/UserData.dart';

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

  UserData? userData = UserStorage.userData;

  LocationService _locationService = LocationService();
  SensorService _sensorService = SensorService();
  StreamSubscription<Position>? _locationSubscription;
  late List _mistakeTimestamps = [];

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
    if (userData == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black, // Set the background color to black
            title: Text(
              'You need to log in',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            content: Text(
              'Please log in to start tracking.',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

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
            backgroundColor: Colors.black, // Set the background color to black

            title: Text(
              'Final Grade',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            content: Text(
              'Your final grade is ${finalGrade}%',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
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
    setState(() {
      _mistakes = 0;
      _mistakeTimestamps = [];
      _mistakeList = [];
      grade = '-';
      finalGrade = null;
    });
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
          // Check if the current speeding incident is within 10 seconds of the last one
          else if (now.difference(lastTimestamp).inSeconds <= 10) {
            isMistake = false;
          }
          // Check if the current speeding incident is within 10 seconds of the second-last one
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
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_currentPosition != null)
                ListTile(
                  leading:
                      Icon(Icons.place, size: 48, color: Color(0xFF44a7f4)),
                  title: Text(
                    'Location',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44a7f4)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44a7f4)),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.speed, size: 48, color: Color(0xFF44a7f4)),
                title: Text(
                  'Speed',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                subtitle: Text(
                  '${(_currentPosition!.speed * 3.6).toStringAsFixed(2)} km/h',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44a7f4)),
                ),
              ),
              SizedBox(height: 16),
              if (_dataObjects != null && _dataObjects!.isNotEmpty)
                ListTile(
                  leading:
                      Icon(Icons.error, size: 48, color: Color(0xFF44a7f4)),
                  title: Text(
                    'Street Speed Limit',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  subtitle: Text(
                    '${_dataObjects![0]['speedLimit']} km/h',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44a7f4)),
                  ),
                ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.cancel_presentation,
                    size: 48, color: Color(0xFF44a7f4)),
                title: Text(
                  'Mistakes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                subtitle: Text(
                  '$_mistakes',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44a7f4)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleTracking,
        child: _isTracking ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
    );
  }
}
