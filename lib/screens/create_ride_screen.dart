import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();
  DateTime? _selectedDate;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submitRide() async {
    if (_sourceController.text.isEmpty || _destController.text.isEmpty || _selectedDate == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    // Get user details from Firestore
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    await FirebaseFirestore.instance.collection('rides').add({
      'leaderId': user.uid,
      'leaderName': userData['name'],
      'source': _sourceController.text,
      'destination': _destController.text,
      'rideDate': _selectedDate!.toIso8601String(),
      'status': 'open',
      'createdAt': Timestamp.now(),
    });

    Navigator.of(context).pop(); // Go back to home after creating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer a Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'From (Source)'),
            ),
            TextField(
              controller: _destController,
              decoration: const InputDecoration(labelText: 'To (Destination)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(_selectedDate == null 
                  ? 'No Date Chosen!' 
                  : 'Date: ${DateFormat.yMd().format(_selectedDate!)}'),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitRide,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Create Ride Post'),
            ),
          ],
        ),
      ),
    );
  }
}