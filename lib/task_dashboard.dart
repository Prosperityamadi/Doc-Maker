import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:noteapp/database.dart';
import 'package:noteapp/document.dart';
import 'package:noteapp/editor.dart';

class TaskItem {
  final String text;
  final Document sourceDocument;
  final bool isChecked;

  TaskItem({
    required this.text,
    required this.sourceDocument,
    required this.isChecked,
  });
}

class TaskDashboard extends StatefulWidget {
  const TaskDashboard({super.key});

  @override
  State<TaskDashboard> createState() => _TaskDashboardState();
}

class _TaskDashboardState extends State<TaskDashboard> {
  List<TaskItem> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => isLoading = true);

    try {
      final docs = await DatabaseHelper.instance.getAllDocuments();
      final extractedTasks = <TaskItem>[];

      for (var doc in docs) {
        try {
          final List<dynamic> jsonContent = jsonDecode(doc.content);

          // Helper to rebuild text from delta operations
          // Quill Delta is a list of operations.
          // Usually: [{"insert": "Milk"}, {"insert": "\n", "attributes": {"list": "checked"}}]
          // We need to buffer text until we hit a newline with list attribute.

          StringBuffer buffer = StringBuffer();

          for (var op in jsonContent) {
            final data = op['insert'];
            final attributes = op['attributes'];

            if (data is String) {
              if (data == '\n') {
                // Check if this newline is a checkbox
                if (attributes != null &&
                    (attributes['list'] == 'checked' ||
                        attributes['list'] == 'unchecked')) {
                  final isChecked = attributes['list'] == 'checked';
                  final text = buffer.toString().trim();

                  if (text.isNotEmpty) {
                    extractedTasks.add(
                      TaskItem(
                        text: text,
                        sourceDocument: doc,
                        isChecked: isChecked,
                      ),
                    );
                  }
                }
                // Reset buffer after newline regardless
                buffer.clear();
              } else {
                buffer.write(data);
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing doc ${doc.id}: $e');
        }
      }

      setState(() {
        tasks = extractedTasks;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadTasks),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? _buildEmptyState()
          : _buildTaskList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add checkboxes to your documents to see them here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              task.isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: task.isChecked ? Colors.green : Colors.grey,
            ),
            title: Text(
              task.text,
              style: TextStyle(
                decoration: task.isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              'From: ${task.sourceDocument.title}',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              // Navigate to doc
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditorPage(document: task.sourceDocument),
                ),
              ).then((_) => loadTasks()); // Search again after return
            },
          ),
        );
      },
    );
  }
}
