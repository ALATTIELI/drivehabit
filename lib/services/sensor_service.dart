import 'package:sensors/sensors.dart';

class SensorService {
  Stream<AccelerometerEvent> getAccelerometerStream() {
    return accelerometerEvents;
  }

  // Add more methods for other sensors as needed
}
