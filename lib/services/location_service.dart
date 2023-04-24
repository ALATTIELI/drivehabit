import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getLocation() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (isLocationServiceEnabled) {
      Position position = await Geolocator.getCurrentPosition();
      return position;
    } else {
      return null;
    }
  }
}
