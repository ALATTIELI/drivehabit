import 'package:flutter/material.dart';

class ProfileScreenPage extends StatefulWidget {
  @override
  _ProfileScreenPageState createState() => _ProfileScreenPageState();
}

class _ProfileScreenPageState extends State<ProfileScreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Profile Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
