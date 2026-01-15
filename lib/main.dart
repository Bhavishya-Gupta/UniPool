import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unipool/screens/auth_screen.dart';
import 'package:unipool/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const UnipoolApp());
}

class UnipoolApp extends StatelessWidget {
  const UnipoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniPool',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // Check if user is already logged in
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return const HomeScreen(); // User is logged in
          }
          return const AuthScreen(); // User needs to login
        },
      ),
    );
  }
}