import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletracker/features/home_screen/widgets/message_card_mixin.dart';


class MessageCardWidget extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> messageDoc;
  final bool isHighlighted;
  final Function(double)? onHeightChanged;

  const MessageCardWidget({
    super.key,
    required this.messageDoc,
    this.isHighlighted = false,
    this.onHeightChanged,
  });

  @override
  State<MessageCardWidget> createState() => _MessageCardWidgetState();
}

class _MessageCardWidgetState extends State<MessageCardWidget> with MessageCardMixin {
  late ValueNotifier<bool> _isHighlightedNotifier;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isHighlightedNotifier = ValueNotifier(widget.isHighlighted);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndReportHeight());
    if (widget.isHighlighted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _isHighlightedNotifier.value = false;
      });
    }
  }

  void _measureAndReportHeight() {
    if (!mounted) return;
    final RenderBox? renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onHeightChanged?.call(renderBox.size.height);
    }
  }

  @override
  void didUpdateWidget(covariant MessageCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndReportHeight());
    if (widget.isHighlighted != oldWidget.isHighlighted && widget.isHighlighted) {
      _isHighlightedNotifier.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _isHighlightedNotifier.value = false;
      });
    }
  }

  @override
  void dispose() {
    _isHighlightedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentVersion = (widget.messageDoc.data()['current_version'] as num?)?.toInt() ?? 1;
    final msgId = widget.messageDoc.data()['msg_id']?.toString() ?? '';
    
    return ValueListenableBuilder<bool>(
      valueListenable: _isHighlightedNotifier,
      builder: (context, isHighlighted, child) {
        return Card(
          key: _cardKey,
          margin: const EdgeInsets.all(8),
          color: isHighlighted ? Colors.yellow.withValues(alpha: 0.1) : Colors.white,
          elevation: 2,
          child: AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              border: isHighlighted ? Border.all(color: Colors.amber, width: 1.5) : null,
            ),
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: widget.messageDoc.reference.collection('versions').orderBy("version").get(),
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
                  title: Text(
                    "Message: $msgId",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Edits: $currentVersion"),
                  children: List.generate(versions.length, (index) {
                    final versionData = versions[index].data();
                    final content = versionData['message'] ?? 'No content';
                    final versionNumber = versionData['version'] ?? index + 1;
                    final Timestamp date = versionData['date'];
                    final Timestamp? editDate = versionData['edit_date'];
                    final DateTime displayTime = editDate?.toDate() ?? date.toDate();
                    final bool isEdited = editDate != null;
                    final String previousContent =
                        index > 0 ? versions[index - 1].data()['message'] ?? '' : '';

      return ListTile(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: buildMessageLines(content, previousContent, index),
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(
        "Version: $versionNumber",
        style: const TextStyle(color: Colors.blueAccent),
      ),
      const SizedBox(height: 4),
      // The changed part
      buildDateTimeWidget(context, displayTime, isEdited), 
      if (index < versions.length - 1)
        Divider(
          color: Colors.grey,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
        ),
    ],
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);    
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }
}