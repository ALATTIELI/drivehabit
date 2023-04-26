import 'dart:ffi';

import 'package:flutter/material.dart';

// db
import 'package:firebase_database/firebase_database.dart';

// auth
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

class ProfileScreenPage extends StatefulWidget {
  @override
  _ProfileScreenPageState createState() => _ProfileScreenPageState();
}

class _ProfileScreenPageState extends State<ProfileScreenPage> {
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  User? user;
  String? email;
  String get userId {
    return user?.uid ?? 'default';
  }

  Stream<User?> get authStateChanges => auth.authStateChanges();

  void login() async {
    try {
      UserCredential userCredential = await signInWithGoogle();
      user = userCredential.user;
      email = userCredential.user!.email!;
      setState(() {}); // Add this line to update the UI
    } catch (e) {
      print(e);
    }
  }

  // void writeToDB() async {
  //   DatabaseReference ref = FirebaseDatabase.instance.ref('users/$userId');

  //   await ref.set({
  //     "name": user?.displayName,
  //     "email": user?.email,
  //     "photo": user?.photoURL,
  //   });
  // }

  // void readDB() async {
  //   final ref = FirebaseDatabase.instance.ref();
  //   final snapshot = await ref.child('users/$userId').get();
  //   if (snapshot.exists) {
  //     print(snapshot.value);
  //     // set the value to the another string value name
  //     setState(() {
  //       another = (snapshot.value as Map<dynamic, dynamic>)['name'];
  //     });
  //   } else {
  //     print('No data available.');
  //   }
  // }

  void logoutState() {
    setState(() {
      email = null;
      user = null;
    });
  }

  void deleteAccount() async {
    try {
      await user?.delete();
      logoutState();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.hasData) {
            return Column(children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Profile Screen',
                      style: TextStyle(fontSize: 30),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        auth.signOut();
                        logoutState();
                      },
                      child: Text('Logout'),
                    ),
                    // View the user
                    Text('${user?.displayName}',
                        style: TextStyle(fontSize: 20)),
                    Text('${user?.email}', style: TextStyle(fontSize: 20)),
                    // img
                    Image.network(user?.photoURL ?? ''),
                    // add button to the bottom
                    ElevatedButton(
                      onPressed: () {
                        deleteAccount();
                      },
                      child: Text('Delete Account'),
                    ),
                  ],
                ),
              )
            ]);
          } else {
            return Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      login();
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            );
          }
        }
      },
    );
  }
}
