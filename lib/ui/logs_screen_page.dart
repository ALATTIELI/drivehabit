import 'package:flutter/material.dart';
import 'package:test2/services/mongo_service.dart';

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

    // Fetch the logs from the logs collection
    final collection = _mongoService.db.collection('logs');
    final logs = await collection.find().toList();

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

          return ListTile(
            title: Text('Log ${index + 1}'),
            subtitle: Text('Timestamp: $timestamp'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Navigate to the log details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogDetailsPage(data: data),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LogDetailsPage extends StatelessWidget {
  final dynamic data;
  const LogDetailsPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Details'),
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (BuildContext context, dynamic index) {
          final log = data[index];
          final location = log['location'];
          final latitude = location['latitude'];
          final longitude = location['longitude'];
          final type = log['type'];
          final speedLimit = log['speedLimit'];
          final speed = log['speed'];
          final timestamp = log['timestamp'];
          final dateTime = timestamp;

          return Card(
            child: ListTile(
              leading: Icon(Icons.location_on),
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
