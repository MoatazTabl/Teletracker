import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageCardWidget extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> messageDoc;
  final bool isHighlighted;
  final Function(double)? onHeightChanged; // Add callback for height

  const MessageCardWidget({
    super.key,
    required this.messageDoc,
    this.isHighlighted = false,
    this.onHeightChanged,
  });

  @override
  State<MessageCardWidget> createState() => _MessageCardWidgetState();
}

class _MessageCardWidgetState extends State<MessageCardWidget> {
  late ValueNotifier<bool> _isHighlightedNotifier;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isHighlightedNotifier = ValueNotifier(widget.isHighlighted);
    // Add post-frame callback to measure height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureAndReportHeight();
    });
    if (widget.isHighlighted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isHighlightedNotifier.value = false;
        }
      });
    }
  }

  void _measureAndReportHeight() {
    if (!mounted) return;
    
    final RenderBox? renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final height = renderBox.size.height;
      widget.onHeightChanged?.call(height);
      print('MessageCard height: $height');
    }
  }

  @override
  void didUpdateWidget(MessageCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Measure height after widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureAndReportHeight();
    });
    if (widget.isHighlighted != oldWidget.isHighlighted && widget.isHighlighted) {
      _isHighlightedNotifier.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isHighlightedNotifier.value = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _isHighlightedNotifier.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final hourString = hour == 0 ? '12' : hour.toString();
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} $hourString:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.second} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final int currentVersion = widget.messageDoc.get('current_version') ?? 1;
    final String msgId =
        widget.messageDoc.data().containsKey('msg_id')
            ? widget.messageDoc.get('msg_id') ?? ''
            : '';

    return ValueListenableBuilder<bool>(
      valueListenable: _isHighlightedNotifier,
      builder: (context, isHighlighted, child) {
        return Card(
          key: _cardKey, // Add the key here
          margin: const EdgeInsets.all(8),
          color: isHighlighted ? Colors.yellow.withValues(alpha: .3) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              border:
                  isHighlighted
                      ? Border.all(color: Colors.amber, width: 2.0)
                      : null,
            ),
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future:
                  widget.messageDoc.reference
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
                  title: Text("Message: $msgId"),
                  subtitle: Text("Current Edits: $currentVersion"),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: versions.length,
                      itemBuilder: (context, index) {
                        final versionData = versions[index].data();
                        final content = versionData['message'] ?? 'No content';
                        final versionNumber =
                            versionData['version'] ?? index + 1;
                        final Timestamp date = versionData['date'];
                        final Timestamp? editDate = versionData['edit_date'];

                        final DateTime displayTime =
                            editDate?.toDate() ?? date.toDate();
                        final bool isEdited = editDate != null;

                        return ListTile(
                          title: Text(content, softWrap: true),
                          subtitle: Text(
                            "Version: $versionNumber",
                            style: const TextStyle(color: Colors.lightBlue),
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDateTime(displayTime),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (isEdited)
                                Text(
                                  '(edited)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}