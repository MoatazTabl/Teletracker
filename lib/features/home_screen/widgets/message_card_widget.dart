import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> messageDoc;
  const MessageCard({super.key, required this.messageDoc});

  @override
  Widget build(BuildContext context) {
    // final String currentVersion = messageDoc.get('current_version') ?? '1';
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
            subtitle: Text("Current Version: 1"),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: versions.length,
                itemBuilder: (context, index) {
                  final versionData = versions[index].data();
                  final content = versionData['message'] ?? 'No content';
                  final versionNumber = versionData['version'] ?? index + 1;
                  final Timestamp date = versionData['date'] ?? 'No date';

                  final time=date.toDate();
                  return ListTile(
                    title: Text(content),
                    subtitle: Text("Version: $versionNumber"),
                    trailing: Text(
                      time.toString(),
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
