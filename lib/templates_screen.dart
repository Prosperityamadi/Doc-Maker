import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:noteapp/document.dart';
import 'package:noteapp/editor.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class Template {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String contentJson;

  Template({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.contentJson,
  });
}

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  List<Template> get _templates => [
    Template(
      title: 'Blank Note',
      description: 'Start with a clean slate.',
      icon: Icons.note_add_outlined,
      color: Colors.grey,
      contentJson: '[{"insert":"\\n"}]',
    ),
    Template(
      title: 'Daily Standup',
      description: 'Track your yesterdays, todays, and blockers.',
      icon: Icons.today,
      color: Colors.blue,
      contentJson: jsonEncode([
        {
          "insert": "Daily Standup\\n",
          "attributes": {"header": 1},
        },
        {
          "insert": "\\nYesterday\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "What did you accomplish?\\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "\\nToday\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "What are your goals?\\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "\\nBlockers\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "Any impediments?\\n",
          "attributes": {"list": "bullet"},
        },
      ]),
    ),
    Template(
      title: 'Project Planner',
      description: 'Define scope, goals, and milestones.',
      icon: Icons.rocket_launch,
      color: Colors.orange,
      contentJson: jsonEncode([
        {
          "insert": "Project Name\\n",
          "attributes": {"header": 1},
        },
        {"insert": "Goal: Define the destination.\\n"},
        {
          "insert": "\\nScope\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "In Scope\\n",
          "attributes": {"list": "checked"},
        },
        {
          "insert": "Out of Scope\\n",
          "attributes": {"list": "checked"},
        },
        {
          "insert": "\\nMilestones\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "Phase 1: ...\\n",
          "attributes": {"list": "bullet"},
        },
      ]),
    ),
    Template(
      title: 'Meeting Notes',
      description: 'Attendees, agenda, and action items.',
      icon: Icons.groups,
      color: Colors.green,
      contentJson: jsonEncode([
        {
          "insert": "Meeting Minutes\\n",
          "attributes": {"header": 1},
        },
        {
          "insert": "\\nAttendees\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "@Name\\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "\\nAgenda\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "Topic 1\\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "\\nAction Items\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "Task 1\\n",
          "attributes": {"list": "checked"},
        },
      ]),
    ),
    Template(
      title: 'Weekly Review',
      description: 'Reflect on the week passed and plan ahead.',
      icon: Icons.calendar_view_week,
      color: Colors.purple,
      contentJson: jsonEncode([
        {
          "insert": "Weekly Review\\n",
          "attributes": {"header": 1},
        },
        {
          "insert": "\\nWins\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "What went well?\\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "\\nChallenges\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "What could be improved?\\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "\\nNext Week Focus\\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "Top 3 priorities\\n",
          "attributes": {"list": "ordered"},
        },
      ]),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Templates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final template = _templates[index];
            return _buildTemplateCard(context, template, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Template template,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to editor with this template content
        // We create a "New Document" but pre-fill it.
        // We pass a Document object with null ID (so it saves as new) but existing content.

        // However, EditorPage takes a Document? which usually implies an EXISTING doc with ID.
        // If we want new doc with content, we might need a way to pass content only.
        // Or we pass a Document object with null ID.

        final newDoc = Document(
          title: template.title == 'Blank Note' ? 'Untitled' : template.title,
          content: template.contentJson,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditorPage(document: newDoc)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(template.icon, color: template.color, size: 28),
              ),
              const Spacer(),
              Text(
                template.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
