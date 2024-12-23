import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_demo/screens/edit_note/edit_note_screen.dart';
import 'package:flutter_demo/screens/list_notes/list_notes_cubit.dart';

class NoteDetailScreen extends StatelessWidget {
  static const String route = "NoteDetailScreen";

  const NoteDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListNotesCubit, ListNotesState>(
      builder: (context, state) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(state.notes[state.selectedIdx].dateTime.toIso8601String()),
          const SizedBox(height: 16),
          Text(state.notes[state.selectedIdx].title),
          const SizedBox(height: 16),
          Text(state.notes[state.selectedIdx].content),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                if (state.pageCount < 3) {
                  var cubit = context.read<ListNotesCubit>();
                  Navigator.of(context).pushNamed(EditNoteScreen.route,
                      arguments: {"cubit": cubit});
                }
              },
              child: const Text("Edit"))
        ]);
      },
    );
  }
}
