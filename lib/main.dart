import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teletracker/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    print(e);
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize Firebase')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram Messages',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: MessagesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

          final messages = snapshot.data!.docs;
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

class MessageCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> messageDoc;
  const MessageCard({super.key, required this.messageDoc});

  @override
  Widget build(BuildContext context) {
    final String currentVersion = messageDoc.get('current_version') ?? 'N/A';
    final String userName = messageDoc.get('username') ?? 'Unknown User';

    return Card(
      margin: const EdgeInsets.all(8),
      child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future:
            messageDoc.reference
                .collection('versions')
                .orderBy("version")
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No versions found.'),
            );
          }

          final versions = snapshot.data!.docs;
          return ExpansionTile(
            title: Text("Name: $userName"),
            subtitle: Text("Current Version: $currentVersion"),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: versions.length,
                itemBuilder: (context, index) {
                  final versionData = versions[index].data();
                  final content = versionData['message'] ?? 'No content';
                  final versionNumber = versionData['version'] ?? index + 1;
                  final date = versionData['date']?.toString() ?? 'No date';

                  return ListTile(
                    title: Text(content),
                    subtitle: Text("Version: $versionNumber"),
                    trailing: Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
