import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

class _MessageCardWidgetState extends State<MessageCardWidget> {
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
    if (renderBox != null && renderBox.hasSize) widget.onHeightChanged?.call(renderBox.size.height);
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

 String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
  final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
  final hourString = hour == 0 ? '12' : hour.toString();
  return '${dateTime.year}/${dateTime.month}/${dateTime.day} $hourString:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')} $amPm';
}

  List<InlineSpan> _buildTextWithEdits(String previous, String current) {
    final List<InlineSpan> spans = [];
    final minLength = previous.length < current.length ? previous.length : current.length;
    int i = 0;

    while (i < minLength) {
      if (previous[i] != current[i]) {
        final start = i;
        while (i < minLength && previous[i] != current[i]) i++;
        final changedText = current.substring(start, i);
        spans.add(TextSpan(
          text: changedText,
          style: const TextStyle(
            color: Colors.black,
            backgroundColor: Color.fromRGBO(255, 255, 0, 0.3), // اللون الأصفر مع شفافية
            decoration: TextDecoration.underline,
            decorationColor: Colors.amber,
            decorationThickness: 2,
          ),
        ));
        
      } else {
        final start = i;
        while (i < minLength && previous[i] == current[i]) i++;
        final unchangedText = current.substring(start, i);
        spans.add(TextSpan(text: unchangedText, style: const TextStyle(color: Colors.black)));
      }
    }

    if (i < current.length) {
      spans.add(TextSpan(text: current.substring(i), style: const TextStyle(color: Colors.black)));
    }
    return spans;
  }

  List<Widget> _buildMessageLines(String content, String previousContent, int index) {
    final lines = content.split('\n');
    final previousLines = previousContent.isNotEmpty ? previousContent.split('\n') : [];
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final currentLine = lines[i];
      final previousLine = i < previousLines.length ? previousLines[i] : '';
      lineWidgets.add(RichText(
        text: TextSpan(
          children: index > 0 && previousLine.isNotEmpty
              ? _buildTextWithEdits(previousLine, currentLine)
              : [TextSpan(text: currentLine, style: const TextStyle(color: Colors.black))],
        ),
        // maxLines: 1,
        // overflow: TextOverflow.ellipsis,
      ));
    }
    return lineWidgets;
  }

  @override
  Widget build(BuildContext context) {
    final int currentVersion = widget.messageDoc.get('current_version') ?? 1;
    final String msgId = widget.messageDoc.data().containsKey('msg_id') ? widget.messageDoc.get('msg_id') ?? '' : '';

    return ValueListenableBuilder<bool>(
      valueListenable: _isHighlightedNotifier,
      builder: (context, isHighlighted, child) {
        return Card(
          key: _cardKey,
          margin: const EdgeInsets.all(8),
          color: isHighlighted ? Colors.yellow.withValues(alpha: 0.3) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              border: isHighlighted ? Border.all(color: Colors.amber, width: 2.0) : null,
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
                if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(8.0), child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(8.0), child: Text('No versions found.'));
                }

                final versions = snapshot.data!.docs;
                return ExpansionTile(
                  title: Text("Message: $msgId", maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Current Edits: $currentVersion", maxLines: 1),
                  children: List.generate(versions.length, (index) {
                    final versionData = versions[index].data();
                    final content = versionData['message'] ?? 'No content';
                    final versionNumber = versionData['version'] ?? index + 1;
                    final Timestamp date = versionData['date'];
                    final Timestamp? editDate = versionData['edit_date'];
                    final DateTime displayTime = editDate?.toDate() ?? date.toDate();
                    final bool isEdited = editDate != null;
                    final String previousContent = index > 0 ? versions[index - 1].data()['message'] ?? '' : '';

    return ListTile(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _buildMessageLines(content, previousContent, index), // إزالة Divider من هنا
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(height: 5,),
      Text(
        "Version: $versionNumber",
        style: const TextStyle(color: Colors.lightBlue),
        // maxLines: 1,
        // overflow: TextOverflow.ellipsis,
      ),
      Container(height: 5,),
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Text(
          'Day: ',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${displayTime.year}/${displayTime.month}/${displayTime.day}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
    const SizedBox(height: 4),
    Row(
      children: [
        Text(
          'Time: ',
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${displayTime.hour > 12 ? displayTime.hour - 12 : displayTime.hour == 0 ? 12 : displayTime.hour}:${displayTime.minute.toString().padLeft(2, '0')}:${displayTime.second.toString().padLeft(2, '0')} ${displayTime.hour >= 12 ? 'PM' : 'AM'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
      ],
    ),
    if (isEdited)
      Row(
        children: [
          const Text(
      ' (edited)',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),    ),
        ],
      ),
  ],
),
Container(height: 5),    if (index < versions.length - 1) 
  const Divider(
    color: Colors.grey,
    indent: 80,
    endIndent: 80,
    thickness: 1,
    height: 10,
  ),
    ],
  ),
  
  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
);        }),
                
                );
              },
            ),
          ),
        );
      },
    );
  }
}