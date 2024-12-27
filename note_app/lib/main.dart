import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_app/services/database_helper.dart';
import 'package:note_app/models/note_model.dart';

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  _NoteAppState createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Note> _notes = [];
  int _themeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadTheme();
  }

  Future<void> _loadNotes() async {
    final notes = await _databaseHelper.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _addNote() async {
    final note = Note(
      title: _titleController.text,
      content: _contentController.text,
    );
    await _databaseHelper.insertNote(note);
    _titleController.clear();
    _contentController.clear();
    _loadNotes();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeIndex = prefs.getInt('theme_index') ?? 0;
    });
  }

  Future<void> _saveTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
    setState(() {
      _themeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = [
      ThemeData.light(),
      ThemeData.dark(),
      ThemeData(primarySwatch: Colors.green),
    ];

    return MaterialApp(
      theme: themes[_themeIndex],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ghi Chú'),
          actions: [
            PopupMenuButton<int>(
              onSelected: _saveTheme,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 0, child: Text('Sáng')),
                const PopupMenuItem(value: 1, child: Text('Tối')),
                const PopupMenuItem(value: 2, child: Text('Xanh lá')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            ElevatedButton(
              onPressed: _addNote,
              child: const Text('Lưu Ghi Chú'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text(note.content),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _databaseHelper.deleteNote(note.id!);
                        _loadNotes();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(NoteApp());
}
