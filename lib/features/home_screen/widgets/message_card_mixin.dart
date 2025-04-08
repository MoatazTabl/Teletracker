import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

mixin MessageCardMixin {
  // دالة لتنسيق التاريخ فقط
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }

  // دالة لتنسيق الوقت فقط
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final hourString = hour == 0 ? '12' : hour.toString();
    return '$hourString:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')} $amPm';
  }

  // دالة قديمة للتوافق، لكن لن نستخدمها مباشرة في الواجهة
  String formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('yyyy/MM/dd h:mm:ss a');
    return dateFormat.format(dateTime);
  }

  // دالة جديدة لبناء واجهة التاريخ والوقت مع Edited
  Widget buildDateTimeWidget(BuildContext context, DateTime dateTime, bool isEdited) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Day: ',
              style: TextStyle(
                color: Colors.black87, // لون أسود داكن
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(dateTime),
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
              _formatTime(dateTime),
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
                'Edited',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<InlineSpan> _buildTextWithEdits(String previous, String current) {
    if (previous.isEmpty) {
      return [
        TextSpan(
          text: current,
          style: const TextStyle(color: Colors.black),
        )
      ];
    }

    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(previous, current);
    dmp.diffCleanupSemantic(diffs);

    final List<InlineSpan> spans = [];
    for (int i = 0; i < diffs.length; i++) {
      final diff = diffs[i];
      final text = diff.text;
      switch (diff.operation) {
        case DIFF_EQUAL:
          spans.add(TextSpan(text: text, style: const TextStyle(color: Colors.black)));
          break;
        case DIFF_INSERT:
          spans.add(
            TextSpan(
              text: text,
              style: TextStyle(
                backgroundColor: Colors.green.withValues(alpha :0.3),
                color: Colors.black,
              ),
            ),
          );
          break;
        case DIFF_DELETE:
          if (i + 1 < diffs.length && diffs[i + 1].operation == DIFF_INSERT) {
            final insertedText = diffs[i + 1].text;
            spans.add(
              TextSpan(
                text: insertedText,
                style: TextStyle(
                  backgroundColor: Colors.red.withValues(alpha :0.3),
                  color: Colors.black,
                ),
              ),
            );
            i++;
          }
          break;
      }
    }
    return spans;
  }

  List<Widget> buildMessageLines(String content, String previousContent, int index) {
    final lines = content.split('\n');
    final previousLines = previousContent.isNotEmpty ? previousContent.split('\n') : [];
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final currentLine = lines[i];
      final previousLine = i < previousLines.length ? previousLines[i] : '';
      lineWidgets.add(
        RichText(
          text: TextSpan(
            children: index > 0 && previousLine.isNotEmpty
                ? _buildTextWithEdits(previousLine, currentLine)
                : [
                    TextSpan(
                      text: currentLine,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
          ),
        ),
      );
    }
    return lineWidgets;
  }
}