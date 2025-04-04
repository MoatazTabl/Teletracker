import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teletracker/features/home_screen/widgets/message_card_widget.dart';

class MessagesPage extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> messagesRef =
      FirebaseFirestore.instance.collection('messages');

  MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Messages'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: messagesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages found.'));
          }

          final messages = snapshot.data!.docs.reversed.toList();
          return ListView.builder(
            itemCount: messages.length,
            
            itemBuilder: (context, index) {
              final messageDoc = messages[index];
              return MessageCard(messageDoc: messageDoc);
            },
          );
        },
      ),
    );
  }
}
