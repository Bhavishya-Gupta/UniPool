import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String rideDestination;

  const ChatScreen({
    super.key, 
    required this.rideId, 
    required this.rideDestination
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    
    // 1. Save message to Firestore
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .collection('messages')
        .add({
      'text': message,
      'createdAt': Timestamp.now(),
      'senderId': user.uid,
      'senderEmail': user.email,
    });
    await FirebaseFirestore.instance
      .collection('rides')
      .doc(widget.rideId)
      .update({
    'participants': FieldValue.arrayUnion([user.uid])
  });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat: ${widget.rideDestination}'),
      ),
      body: Column(
        children: [
          // 1. The Message List (Expanded takes all available space)
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .doc(widget.rideId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true) // Newest at bottom
                  .snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Scroll from bottom
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final msgData = messages[index];
                    final isMe = msgData['senderId'] == currentUser.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo[100] : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: !isMe ? Radius.circular(0) : const Radius.circular(12),
                            bottomRight: isMe ? Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                             Text(
                              msgData['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMe ? 'You' : msgData['senderEmail'].toString().split('@')[0],
                              style: TextStyle(fontSize: 10, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. The Input Area
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Send a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.indigo),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}