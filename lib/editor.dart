import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:noteapp/database.dart';
import 'package:noteapp/document.dart';
import 'package:noteapp/services/snippet_service.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class EditorPage extends StatefulWidget {
  final Document? document; // Null if creating new document

  const EditorPage({super.key, this.document});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // Controller for title
  late TextEditingController titleController;
  // Quill editor controller
  late quill.QuillController quillController;
  // Focus node for editor to maintain cursor
  late FocusNode editorFocusNode;
  // Track if document has changes
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize focus node
    editorFocusNode = FocusNode();

    // Initialize title
    titleController = TextEditingController(text: widget.document?.title ?? '');

    // Initialize Quill editor
    if (widget.document != null) {
      // Load existing document
      try {
        final doc = quill.Document.fromJson(
          jsonDecode(widget.document!.content),
        );
        quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If error loading, create empty document
        quillController = quill.QuillController.basic();
      }
    } else {
      // Create new empty document
      quillController = quill.QuillController.basic();
    }

    // Listen for changes
    titleController.addListener(() => hasChanges = true);
    quillController.addListener(_onEditorChanged);
  }

  void _onEditorChanged() {
    hasChanges = true;

    // Smart Snippet Logic
    final selection = quillController.selection;
    if (!selection.isCollapsed)
      return; // Only trigger on typing, not range selection

    final cursorPos = selection.baseOffset;
    if (cursorPos <= 0) return;

    final docText = quillController.document.toPlainText();
    if (cursorPos > docText.length) return; // Safety check

    // Check character just typed (preceding cursor)
    // We want to trigger ON space or new line
    final lastChar = docText[cursorPos - 1];

    if (lastChar == ' ' || lastChar == '\n') {
      _checkAndExpandSnippet(cursorPos - 1, docText);
    }
  }

  void _checkAndExpandSnippet(int triggerPos, String fullText) {
    // Find the word before the trigger character
    // Walk back from triggerPos-1 until whitespace or start
    int start = triggerPos - 1;
    while (start >= 0) {
      final char = fullText[start];
      if (char == ' ' || char == '\n') {
        break;
      }
      start--;
    }
    start++; // Position of the first character of the word

    if (start >= triggerPos) return; // Empty word

    final word = fullText.substring(start, triggerPos);

    // Check service
    final replacement = SnippetService().getReplacement(word);

    if (replacement != null) {
      // Perform replacement
      // Pause listener to avoid recursive loops
      quillController.removeListener(_onEditorChanged);

      quillController.replaceText(
        start,
        triggerPos - start,
        replacement,
        const TextSelection.collapsed(offset: 0),
      );

      final newCursorPos = start + replacement.length + 1;

      quillController.updateSelection(
        TextSelection.collapsed(offset: newCursorPos),
        quill.ChangeSource.local,
      );

      quillController.addListener(_onEditorChanged);
    }
  }

  // Save document to database
  Future<void> saveDocument() async {
    final title = titleController.text.trim().isEmpty
        ? 'Untitled'
        : titleController.text.trim();

    // Convert Quill document to JSON
    final content = jsonEncode(quillController.document.toDelta().toJson());
    final now = DateTime.now().toIso8601String();

    if (widget.document == null) {
      // Create new document
      final newDoc = Document(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseHelper.instance.saveDocument(newDoc);
    } else {
      // Update existing document
      final updatedDoc = Document(
        id: widget.document!.id,
        title: title,
        content: content,
        createdAt: widget.document!.createdAt,
        updatedAt: now,
      );
      await DatabaseHelper.instance.updateDocument(updatedDoc);
    }

    hasChanges = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved locally'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Handle back button press
  Future<bool> onWillPop() async {
    if (hasChanges) {
      await saveDocument(); // Auto-save on exit for premium feel
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await onWillPop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () async {
              await onWillPop();
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            // Word count pill
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${quillController.document.toPlainText().trim().split(RegExp(r'\s+')).length} words',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [
                    // Minimal Title Field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Untitled',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Editor Area
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: quillController,
                        focusNode: editorFocusNode,
                        config: quill.QuillEditorConfig(
                          padding: const EdgeInsets.only(
                            bottom: 80,
                          ), // Space for FAB/Keyboard
                          autoFocus: true,
                          placeholder:
                              'Type something amazing... Try !date or !todo',
                          expands: false,
                          scrollable: true,
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 18,
                                height: 1.6,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                              ),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                            h1: quill.DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              const quill.VerticalSpacing(16, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Floating-style Toolbar at bottom
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: quill.QuillSimpleToolbar(
                  controller: quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showAlignmentButtons: false,
                    showFontFamily: false,
                    showFontSize: false,
                    toolbarSize: 40,
                    buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                      base: quill.QuillToolbarBaseButtonOptions(
                        iconTheme: quill.QuillIconTheme(
                          iconButtonSelectedData: quill.IconButtonData(
                            color: Colors.blue,
                          ),
                          iconButtonUnselectedData: quill.IconButtonData(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.dispose();
    editorFocusNode.dispose();
    super.dispose();
  }
}
