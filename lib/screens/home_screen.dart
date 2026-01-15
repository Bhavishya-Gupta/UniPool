import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unipool/screens/create_ride_screen.dart'; // We will make this
import 'package:unipool/screens/find_ride_screen.dart'; // We will make this

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniPool Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Where are we going today?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Option 1: BE A LEADER
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const CreateRideScreen()),
                );
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.indigo)
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.drive_eta, size: 50, color: Colors.indigo),
                    Text("Be a Leader", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("I'll book the cab, join me!", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Option 2: BE A POOLER
            InkWell(
              onTap: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const FindRideScreen()),
                );
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green)
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 50, color: Colors.green),
                    Text("Be a Pooler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("I'm looking for a ride.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}