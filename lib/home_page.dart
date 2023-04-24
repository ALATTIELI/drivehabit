import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors/sensors.dart';
import 'package:test2/models/driving_data.dart';
import 'package:test2/services/location_service.dart';
import 'package:test2/services/sensor_service.dart';
import 'package:test2/ui/logs_screen_page.dart';
import 'package:test2/ui/profile_screen_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomePage(),
    LogsScreenPage(),
    ProfileScreenPage(),
  ];

  LocationService _locationService = LocationService();
  SensorService _sensorService = SensorService();
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Stopwatch _stopwatch = Stopwatch();
  Timer _timer = Timer(Duration.zero, () {});

  Position? _currentPosition;
  AccelerometerEvent? _accelerometerEvent;

  void LogsScreen() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LogsScreenPage()));
  }

  void ProfileScreen() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ProfileScreenPage()));
  }

  void _startLocationUpdates() {
    _locationService.getLocation().then((Position? position) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });

        _locationSubscription =
            Geolocator.getPositionStream().listen((Position newPosition) {
          setState(() {
            _currentPosition = newPosition;
          });
        });
      }
    });
  }

  void _startAccelerometerUpdates() {
    _accelerometerSubscription = _sensorService
        .getAccelerometerStream()
        .listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerEvent = event;
      });
    });
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
  }

  void _stopAccelerometerUpdates() {
    _accelerometerSubscription?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startAccelerometerUpdates();
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _stopwatch.stop();
    _stopLocationUpdates();
    _stopAccelerometerUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driving Monitor'),
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
