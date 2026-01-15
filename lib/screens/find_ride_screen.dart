import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FindRideScreen extends StatelessWidget {
  const FindRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: StreamBuilder(
        // Listen to the 'rides' collection in real-time
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rides available right now.'));
          }

          final rideDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rideDocs.length,
            itemBuilder: (ctx, index) {
              var ride = rideDocs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${ride['source']} ➔ ${ride['destination']}'),
                  subtitle: Text('Leader: ${ride['leaderName']}\nDate: ${ride['rideDate'].split('T')[0]}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // This is where we will navigate to the Chat Screen later
                    _showRideDetails(context, ride);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRideDetails(BuildContext context, DocumentSnapshot ride) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Ride?'),
        content: Text('Do you want to chat with ${ride['leaderName']} about this ride?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // NEXT STEP: Navigate to Chat
            }, 
            child: const Text('Let\'s Chat')
          ),
        ],
      ),
    );
  }
}