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
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('My Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            indicatorColor: Color(0xFF9D8FFF),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.outbox_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('I am Leading'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.move_to_inbox_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('I joined'),
                  ],
                ),
              ),
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

  // --- LOGIC: Complete Ride ---
  Future<void> _completeRide(BuildContext context, String rideId, String leaderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .update({'status': 'completed'});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(leaderId)
          .update({
        'ridesCompleted': FieldValue.increment(1),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride marked as completed!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIC: Delete Ride ---
  Future<void> _deleteRide(BuildContext context, String rideId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ride?'),
        content: const Text('Are you sure you want to cancel and delete this ride? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride deleted successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    final query = isLeader
        ? FirebaseFirestore.instance.collection('rides').where('leaderId', isEqualTo: user.uid)
        : FirebaseFirestore.instance.collection('rides').where('participants', arrayContains: user.uid);

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isLeader ? Icons.drive_eta_rounded : Icons.person_search_rounded, size: 42, color: Colors.grey),
                const SizedBox(height: 16),
                Text(isLeader ? 'No rides posted' : 'No joined rides'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(15),
          itemBuilder: (ctx, index) {
            final ride = docs[index];
            final String status = ride['status'] ?? 'open';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text('${ride['source']} → ${ride['destination']}', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: ${status.toUpperCase()}",
                    style: TextStyle(color: status == 'open' ? Colors.green : Colors.grey, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DELETE BUTTON (Only for Leaders)
                    if (isLeader)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _deleteRide(context, ride.id),
                      ),
                    
                    // COMPLETE BUTTON (Only if Open)
                    if (isLeader && status == 'open')
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                        onPressed: () => _completeRide(context, ride.id, user.uid),
                      ),

                    // CHAT BUTTON
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6C63FF)),
                      onPressed: () {
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}