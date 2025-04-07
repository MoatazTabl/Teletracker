import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teletracker/features/home_screen/widgets/message_card_widget.dart';

import '../../core/notification_service.dart';

class MessagesPage extends StatefulWidget {
  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  final messagesQuery = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('created_at', descending: true);

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _highlightedMessageId = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    NotificationService.onMessageReceived = (msgId) {
      if (mounted) {
        jumpToMessage(msgId);
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.checkPendingMessage();
    });
  }

  @override
  void dispose() {
    NotificationService.onMessageReceived = null;
    _scrollController.dispose();
    _highlightedMessageId.dispose();
    super.dispose();
  }

  void jumpToMessage(int messageId) async {
    print("jump to message $messageId");
    final targetIndex = await _findMessageIndexById(messageId);
    print("Target index: $targetIndex");
    if (targetIndex != -1) {
      _highlightedMessageId.value = messageId;
      await _scrollController.animateTo(
        targetIndex * 100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<int> _findMessageIndexById(int messageId) async {
    try {
      Query<Map<String, dynamic>> query = messagesQuery.limit(50);
      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

      while (docs.isNotEmpty &&
          !docs.any((doc) => int.parse(doc.get('msg_id')) == messageId)) {
        final lastDoc = docs.last;
        query = messagesQuery.limit(50).startAfterDocument(lastDoc);
        snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;
        docs.addAll(snapshot.docs);
        print("[Search] Fetched additional batch, total docs: ${docs.length}");
      }

      for (int i = 0; i < docs.length; i++) {
        if (int.parse(docs[i].get('msg_id')) == messageId) {
          print("Found message at index $i");
          return i;
        }
      }
      print("Message not found after searching ${docs.length} documents");
      return -1;
    } catch (e) {
      print("Error finding message index: $e");
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Messages'), centerTitle: true),
      body: ValueListenableBuilder<int?>(
        valueListenable: _highlightedMessageId,
        builder: (context, highlightedMessageId, child) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: messagesQuery.snapshots(),
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

              return ListView.builder(
                controller: _scrollController,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var document = snapshot.data!.docs[index];
                  return MessageCardWidget(
                    key: ValueKey(document.id),
                    messageDoc: document,
                    isHighlighted: int.tryParse(document['msg_id']) == highlightedMessageId,
                    onHeightChanged: (height) {
                      // التعامل مع تغيير الارتفاع إذا لزم الأمر
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
