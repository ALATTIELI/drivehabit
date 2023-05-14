import 'package:flutter/material.dart';
import 'package:test2/services/mongo_service.dart';

import '../models/UserData.dart';

class LogsScreenPage extends StatefulWidget {
  const LogsScreenPage({Key? key}) : super(key: key);

  @override
  _LogsScreenPageState createState() => _LogsScreenPageState();
}

class _LogsScreenPageState extends State<LogsScreenPage> {
  late MongoService _mongoService;

  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    initializeServices();
  }

  Future<void> initializeServices() async {
    _mongoService = await MongoService.initialize();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    // Wait until _mongoService is initialized
    while (_mongoService == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    UserData? userData = UserStorage.userData;
    // Fetch the logs from the logs collection
    final collection = _mongoService.db.collection('logs');
    final logs = await collection.find({'uid': userData?.id}).toList();

    setState(() {
      _logs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (BuildContext context, int index) {
          // Display the log item as a ListTile
          final log = _logs[index];
          final timestamp = log['timestamp'] as DateTime;
          final data = log['data'];

          return Padding(
            padding: EdgeInsets.all(8.0), // Adjust the padding as needed
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black), // Set the border color to black
                borderRadius: BorderRadius.circular(
                    8.0), // Adjust the border radius as needed
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF44a7f4),
                  child: Icon(
                    Icons.description,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Log ${index + 1}',
                  style: TextStyle(fontSize: 25, color: Color(0xFF44a7f4)),
                ),
                subtitle: Text(
                  'Timestamp: $timestamp',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                trailing: Icon(Icons.arrow_forward, color: Color(0xFF44a7f4)),
                onTap: () {
                  // Navigate to the log details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogDetailsPage(data: data),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class LogDetailsPage extends StatelessWidget {
  final List<dynamic> data;
  const LogDetailsPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Log Details',
          style: TextStyle(color: Color(0xFF44a7f4)),
        ),
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (BuildContext context, int index) {
          final log = data[index];
          final location = log['location'];
          final latitude = location['latitude'];
          final longitude = location['longitude'];
          final type = log['type'];
          final speedLimit = log['speedLimit'];
          final speed = log['speed'];
          final timestamp = log['timestamp'];
          final dateTime = timestamp;

          // Get the number of mistakes for the current log
          int mistakeCount = index + 1;

          return Card(
            child: ListTile(
              leading: Stack(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color(0xFF44a7f4),
                    size: 50, // Adjust the icon size as needed
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$mistakeCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text('Location: $latitude, $longitude'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: $type'),
                  Text('Speed Limit: $speedLimit'),
                  Text('Speed: $speed'),
                  Text('Timestamp: ${dateTime.toString()}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
