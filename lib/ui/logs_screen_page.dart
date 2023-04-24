import 'package:flutter/material.dart';

class LogsScreenPage extends StatefulWidget {
  const LogsScreenPage({Key? key}) : super(key: key);

  @override
  _LogsScreenPageState createState() => _LogsScreenPageState();
}

class _LogsScreenPageState extends State<LogsScreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Logs Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
