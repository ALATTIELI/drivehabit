import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/UserData.dart';

class ProfileScreenPage extends StatefulWidget {
  @override
  _ProfileScreenPageState createState() => _ProfileScreenPageState();
}

class _ProfileScreenPageState extends State<ProfileScreenPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  UserData? userData = UserStorage.userData;
  User? _user = FirebaseAuth.instance.currentUser;

  String? _error;

  @override
  void initState() {
    super.initState();
    // _user = _auth.currentUser;
  }

  Future<void> _login() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        setState(() {
          _error = null;
        });
        UserData newUserData = UserData(
            displayName: _auth.currentUser!.displayName,
            email: _auth.currentUser!.email,
            id: _auth.currentUser!.uid,
            photoURL: _auth.currentUser!.photoURL);
        setState(() {
          userData = newUserData;
        });
        UserStorage.saveUserData(newUserData);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      setState(() {
        // _user = null;
        _error = null;
      });
      UserStorage.clearUserData();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _auth.currentUser?.delete();
        setState(() {
          // _user = null;
          _error = null;
        });
        UserStorage.clearUserData();
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: userData == null
          ? Center(
              child: OutlinedButton(
                onPressed: _login,
                child: Text('Login with Google'),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20.0),
                  CircleAvatar(
                      radius: 70.0,
                      backgroundImage: NetworkImage(userData?.photoURL ?? '')),
                  SizedBox(height: 20.0),
                  Text(
                    userData?.displayName ?? '',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    userData?.email ?? '',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _logout,
                    child: Text('Logout'),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _deleteAccount,
                    child: Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                    ),
                  ),
                  if (_error != null) Text(_error!),
                ],
              ),
            ),
    );
  }
}
