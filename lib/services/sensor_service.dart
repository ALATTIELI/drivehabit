import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  Stream<AccelerometerEvent> getAccelerometerStream() {
    return accelerometerEvents;
  }

  // Add more methods for other sensors as needed
}
