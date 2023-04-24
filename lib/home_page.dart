import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors/sensors.dart';
import 'package:test2/models/driving_data.dart';
import 'package:test2/services/location_service.dart';
import 'package:test2/services/sensor_service.dart';
import 'package:test2/ui/logs_screen_page.dart';
import 'package:test2/ui/profile_screen_page.dart';

// db
import 'package:firebase_database/firebase_database.dart';

// auth
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

// Add this new widget at the beginning of your HomePage file
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Home Screen'),
    );
  }
}

class FirebaseScreen extends StatefulWidget {
  @override
  _FirebaseScreenState createState() => _FirebaseScreenState();
}

class _FirebaseScreenState extends State<FirebaseScreen> {
  final String text = 'Firebase Screen';
  String another = "";

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  User? user;
  String? email;
  String get userId {
    return user?.uid ?? 'default';
  }

  void login() async {
    try {
      UserCredential userCredential = await signInWithGoogle();
      user = userCredential.user;
      email = userCredential.user!.email!;
      print(user);
      setState(() {}); // Add this line to update the UI
    } catch (e) {
      print(e);
    }
  }

  void writeToDB() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('users/$userId');

    await ref.set({
      "name": user?.displayName,
      "email": user?.email,
      "photo": user?.photoURL,
    });
  }

  void readDB() async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$userId').get();
    if (snapshot.exists) {
      print(snapshot.value);
      // set the value to the another string value name
      setState(() {
        another = (snapshot.value as Map<dynamic, dynamic>)['name'];
      });
    } else {
      print('No data available.');
    }
  }

  void logoutState() {
    setState(() {
      email = null;
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(text),
          ElevatedButton(
            onPressed: () {
              writeToDB();
            },
            child: Text('Write to DB'),
          ),
          ElevatedButton(
            onPressed: () {
              readDB();
            },
            child: Text('Read from DB'),
          ),
          Text(another),
          ElevatedButton(
            onPressed: () {
              login();
            },
            child: Text('Login'),
          ),
          ElevatedButton(
            onPressed: () {
              auth.signOut();
              logoutState();
            },
            child: Text('Logout'),
          ),
          // View the user
          Text(email ?? ""),
          // show the img
          Image.network(user?.photoURL ?? ""),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomeScreen(),
    LogsScreenPage(),
    ProfileScreenPage(),
    FirebaseScreen(),
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
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.fire_extinguisher),
            label: 'Firebase',
          )
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
