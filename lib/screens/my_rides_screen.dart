import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.outbox), text: 'I am Leading'),
              Tab(icon: Icon(Icons.move_to_inbox), text: 'I joined'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RideList(isLeader: true),
            RideList(isLeader: false),
          ],
        ),
      ),
    );
  }
}

class RideList extends StatelessWidget {
  final bool isLeader;
  const RideList({super.key, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    
    // Define the query based on whether we are looking for Leader or Pooler rides
    final query = isLeader 
      ? FirebaseFirestore.instance.collection('rides').where('leaderId', isEqualTo: user.uid)
      : FirebaseFirestore.instance.collection('rides').where('participants', arrayContains: user.uid);

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(child: Text(isLeader ? 'No rides posted yet.' : 'No joined rides yet.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            final ride = docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text('${ride['source']} to ${ride['destination']}'),
                subtitle: Text('Leader: ${ride['leaderName']}'),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ChatScreen(
                        rideId: ride.id,
                        rideDestination: ride['destination'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}