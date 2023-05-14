import 'package:flutter/material.dart';
import 'package:test2/ui/home_screen_page.dart';
import 'package:test2/ui/logs_screen_page.dart';
import 'package:test2/ui/profile_screen_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomeScreenPage(),
    LogsScreenPage(),
    ProfileScreenPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Drive Habit',
          style: TextStyle(color: Color(0xFF44a7f4)),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black, // Set the background color to black
        unselectedItemColor:
            Colors.white, // Set the unselected icon color to white
        selectedItemColor:
            Color(0xFF44a7f4), // Set the selected icon color to white

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
