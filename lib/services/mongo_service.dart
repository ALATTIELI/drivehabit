import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test2/models/UserData.dart';

class MongoService {
  final Db db;

  UserData? userData = UserStorage.userData;
  MongoService._(this.db);

  static Future<MongoService> initialize() async {
    final db = await Db.create(
        'mongodb+srv://adil:adil@cluster0.nuhysoi.mongodb.net/dh');
    await db.open();
    final mongoService = MongoService._(db);
    await mongoService.createIndex();
    return mongoService;
  }

  Future<void> open() async {
    await db.open();
  }

  Future<void> close() async {
    await db.close();
  }

  Future<void> createIndex() async {
    final collection = db.collection('data');
    await collection.createIndex(keys: {'geometry': '2dsphere'});
  }

  Future<List<Map<String, dynamic>>> dataObjectsWithinRadius(
      double longitude, double latitude, double radiusInMeters) async {
    // final longitude = 55.542871;
    // final latitude = 25.531272;
    final collection = db.collection('data');

    final dataObjects = await collection.find({
      'geometry': {
        r'$nearSphere': {
          r'$geometry': {
            'type': 'Point',
            'coordinates': [longitude, latitude]
          },
          r'$maxDistance': radiusInMeters
        }
      }
    }).toList();

    return dataObjects;
  }

  Future<void> addNewLog(List<dynamic> data) async {
    // Create a new map with the data list and the current timestamp
    Map<String, dynamic> logData = {
      'data': data,
      'timestamp': DateTime.now(),
      'uid': userData?.id
    };

    // Insert the map into the logs collection
    final collection = db.collection('logs');
    await collection.insert(logData);
  }
}
