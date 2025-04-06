import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teletracker/core/notification_service.dart';
import 'package:teletracker/features/home_screen/widgets/message_card_widget.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  // Remove the limit from the base query
  final messagesQuery = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('created_at', descending: true);

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _highlightedMessageId = ValueNotifier<int?>(null);
  // Update these variables
  final ValueNotifier<double> _itemHeight = ValueNotifier<double>(150.0); // Default height
  bool _isFirstItemMeasured = false;

    @override
  void initState() {
    NotificationService.onMessageReceived = (msgId) {
      if (mounted) {
        jumpToMessage(msgId);
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.checkPendingMessage();
    });
    super.initState();
  }


  void jumpToMessage(int messageId) async {
    print("jump to message $messageId");
    final targetIndex = await _findMessageIndexById(messageId);
    print("Target index: $targetIndex");
    if (targetIndex != -1) {
      _highlightedMessageId.value = messageId;
      
      // Wait for height measurement if not already measured
      if (!_isFirstItemMeasured) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      await _scrollController.animateTo(
        targetIndex * _itemHeight.value+60,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Messages'), centerTitle: true),
      body: ValueListenableBuilder<int?>(
        valueListenable: _highlightedMessageId,
        builder: (context, highlightedMessageId, child) {
          return FirestoreListView<Map<String, dynamic>>(
            query: messagesQuery,
            controller: _scrollController,
            pageSize: 20,
            loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => Center(child: Text('Error: $error')),
            emptyBuilder: (context) => const Center(child: Text('No messages found.')),
            itemBuilder: (context, snapshot) {
              return MessageCardWidget(
                key: ValueKey(snapshot.id),
                messageDoc: snapshot,
                isHighlighted: int.tryParse(snapshot.get('msg_id') ?? '') == highlightedMessageId,
                onHeightChanged: (height) {
                  if (!_isFirstItemMeasured) {
                    _itemHeight.value = height;
                    _isFirstItemMeasured = true;
                    print("[Height] First item measured: ${height}px");
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _itemHeight.dispose();
    NotificationService.onMessageReceived = null;
    _scrollController.dispose();
    _highlightedMessageId.dispose();
    super.dispose();
  }

  Future<int> _findMessageIndexById(int messageId) async {
    try {
      // Use a larger batch size for searching
      Query<Map<String, dynamic>> query = messagesQuery.limit(50);
      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

      // Keep fetching until message is found or no more documents
      while (docs.isNotEmpty &&
          !docs.any((doc) => int.parse(doc.get('msg_id')) == messageId)) {
        final lastDoc = docs.last;
        query = messagesQuery.limit(50).startAfterDocument(lastDoc);
        snapshot = await query.get();
        if (snapshot.docs.isEmpty) break; // No more documents
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
}
