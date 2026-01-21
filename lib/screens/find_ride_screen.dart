import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipool/screens/chat_screen.dart';

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

 void _showRideDetails(BuildContext context, DocumentSnapshot ride) async {
  // 1. Fetch the leader's data from the 'users' collection
  final leaderData = await FirebaseFirestore.instance
      .collection('users')
      .doc(ride['leaderId'])
      .get();

  final ridesCount = (leaderData.exists && (leaderData.data() as Map).containsKey('ridesCompleted'))
      ? leaderData['ridesCompleted']
      : 0;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ride Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From: ${ride['source']}'),
          Text('To: ${ride['destination']}'),
          Text('Date: ${ride['rideDate'].toString().split('T')[0]}'),
          const Divider(),
          const Text('Leader Info:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)), // Default icon since we skipped upload
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride['leaderName'], style: const TextStyle(fontSize: 16)),
                  Text('Rides Completed: $ridesCount', 
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ChatScreen(
                  rideId: ride.id,
                  rideDestination: ride['destination'],
                ),
              ),
            );
          },
          child: const Text('Join & Chat'),
        ),
      ],
    ),
  );
}
}