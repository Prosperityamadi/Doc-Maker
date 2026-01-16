import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:noteapp/database.dart';
import 'package:noteapp/document.dart';
import 'package:noteapp/editor.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:noteapp/templates_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Document> allDocuments = [];
  List<Document> displayedDocuments = [];
  final TextEditingController searchController = TextEditingController();
  bool isSearchMode = false;

  // Stats
  int totalWords = 0;

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    final docs = await DatabaseHelper.instance.getAllDocuments();

    // Calculate stats
    int words = 0;
    for (var doc in docs) {
      try {
        final quillDoc = quill.Document.fromJson(jsonDecode(doc.content));
        words += quillDoc.toPlainText().trim().split(RegExp(r'\s+')).length;
      } catch (e) {
        // ignore
      }
    }

    setState(() {
      allDocuments = docs;
      displayedDocuments = docs;
      totalWords = words;
    });
  }

  void filterDocuments(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        displayedDocuments = allDocuments;
      });
      return;
    }

    final filtered = allDocuments.where((doc) {
      final titleMatch = doc.title.toLowerCase().contains(
        searchText.toLowerCase(),
      );
      final contentMatch = doc.content.toLowerCase().contains(
        searchText.toLowerCase(),
      );
      return titleMatch || contentMatch;
    }).toList();

    setState(() {
      displayedDocuments = filtered;
    });
  }

  Future<void> deleteDocument(int id) async {
    await DatabaseHelper.instance.deleteDocument(id);
    loadDocuments();
  }

  Future<void> openEditor({Document? document}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorPage(document: document)),
    );
    loadDocuments();
  }

  String getPreviewText(String jsonContent) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(jsonContent));
      final plainText = doc.toPlainText().trim();
      return plainText.length > 80
          ? '${plainText.substring(0, 80)}...'
          : plainText.isEmpty
          ? "Empty note"
          : plainText;
    } catch (e) {
      return 'No content';
    }
  }

  String formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today ${DateFormat('HH:mm').format(date)}';
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: isSearchMode
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onChanged: filterDocuments,
                  )
                : const Text('My Notes'),
            actions: [
              IconButton(
                icon: Icon(isSearchMode ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    isSearchMode = !isSearchMode;
                    if (!isSearchMode) {
                      searchController.clear();
                      displayedDocuments = allDocuments;
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => AdaptiveTheme.of(context).toggleThemeMode(),
              ),
            ],
          ),

          if (!isSearchMode && allDocuments.isNotEmpty)
            SliverToBoxAdapter(child: _buildStatsHeader(isDark)),

          if (displayedDocuments.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = displayedDocuments[index];
                  return _buildDocumentCard(doc, isDark);
                }, childCount: displayedDocuments.length),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TemplatesScreen()),
          );
          loadDocuments();
        },
        label: const Text('New Note'),
        icon: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            allDocuments.length.toString(),
            'Notes',
            Icons.description,
            isDark,
          ),
          _statItem(totalWords.toString(), 'Words', Icons.text_fields, isDark),
          _statItem(
            (totalWords / 200).ceil().toString(),
            'Min Read',
            Icons.timer,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey : Colors.grey.shade700,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(Document doc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openEditor(document: doc),
          onLongPress: () => _showDeleteDialog(doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatDate(doc.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  getPreviewText(doc.content),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Create your first note',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              deleteDocument(doc.id!);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
