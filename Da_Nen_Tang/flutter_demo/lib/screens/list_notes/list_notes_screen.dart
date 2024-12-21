import 'package:flutter/material.dart';
import 'package:flutter_demo/screens/edit_note/edit_note_screen.dart';
import 'package:flutter_demo/screens/list_notes/list_notes_cubit.dart';
import 'package:flutter_demo/screens/note_detail/note_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListNotesScreen extends StatelessWidget {
  static const String route = "ListNotes";

  const ListNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ListNotesCubit(),
      child: const Page(),
    );
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  @override
  Widget build(BuildContext context) {
    //https://api.flutter.dev/flutter/widgets/MediaQuery/sizeOf.html
    var width = MediaQuery.sizeOf(context).width;
    int pageCount = 0;
    if (width <= 600) {
      pageCount = 1;
    } else if (width <= 900) {
      pageCount = 2;
    } else {
      pageCount = 3;
    }
    context.read<ListNotesCubit>().setPageCount(pageCount);
    return Scaffold(
      body: switch (pageCount) {
        == 1 => const ListNotesPage(),
        == 2 => const ListNotesWithDetailPage(),
        == 3 => const ListNotesDetailEditPage(),
        _ => const ListNotesPage(),
      },
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(
            EditNoteScreen.route,
            arguments: {
              'cubit': context.read<ListNotesCubit>(),
              'isAddMode': true,
            },
          );
        },
      ),
    );
  }
}

class ListNotesPage extends StatelessWidget {
  const ListNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListNotesCubit, ListNotesState>(
      builder: (context, state) {
        var cubit = context.read<ListNotesCubit>();
        return ListView.builder(
          itemBuilder: (context, index) {
            var item = state.notes[index];
            return Card(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.dateTime.toString()),
                trailing: IconButton(
                    onPressed: () {
                      cubit.removeNote(index);
                    },
                    icon: const Icon(Icons.delete)),
                onTap: () {
                  cubit.setSelectedIdx(index);
                  if (state.pageCount == 1) {
                    Navigator.of(context).pushNamed(
                      NoteDetailScreen.route,
                      arguments: {"cubit": cubit},
                    );
                  }
                },
              ),
            );
          },
          itemCount: state.notes.length,
        );
      },
    );
  }
}

class ListNotesWithDetailPage extends StatelessWidget {
  const ListNotesWithDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: ListNotesPage()),
        Expanded(child: NoteDetailScreen()),
      ],
    );
  }
}

class ListNotesDetailEditPage extends StatelessWidget {
  const ListNotesDetailEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: ListNotesPage()),
        Expanded(child: NoteDetailScreen()),
        Expanded(
            child: EditNoteScreen(
          oldPageCount: 3,
        )),
      ],
    );
  }
}
