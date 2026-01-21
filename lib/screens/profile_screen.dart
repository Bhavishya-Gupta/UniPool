import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isUploading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (userData.exists) {
final data = userData.data() as Map<String, dynamic>;
    setState(() {
      _nameController.text = data.containsKey('name') ? data['name'] : '';
      _imageUrl = data.containsKey('photoUrl') ? data['photoUrl'] : null;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${user.uid}.jpg');
      
      await storageRef.putFile(File(pickedFile.path));
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));

      setState(() => _imageUrl = url);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
    }, SetOptions(merge: true));
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    child: _imageUrl == null ? const Icon(Icons.person, size: 60) : null,
                  ),
                  if (_isUploading) const Positioned.fill(child: CircularProgressIndicator()),
                  const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, child: Icon(Icons.camera_alt, size: 18))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            // TRUST STAT (From SRS)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
  builder: (ctx, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    // Safely get the data map
    final data = snapshot.data?.data() as Map<String, dynamic>?;
    
    // Check if the key exists, otherwise default to 0
    final rides = (data != null && data.containsKey('ridesCompleted')) 
        ? data['ridesCompleted'] 
        : 0;
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Text('Rides Completed: $rides', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}