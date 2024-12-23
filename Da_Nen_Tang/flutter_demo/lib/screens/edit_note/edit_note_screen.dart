import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_demo/screens/list_notes/list_notes_screen.dart';

import '../list_notes/list_notes_cubit.dart';

class EditNoteScreen extends StatelessWidget {
  static const String route = "EditNoteScreen";
  final bool isAddMode;
  final int oldPageCount;

  const EditNoteScreen(
      {super.key, this.isAddMode = false, required this.oldPageCount});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListNotesCubit, ListNotesState>(
      builder: (context, state) {
        var titleController = TextEditingController(text: "");
        var contentController = TextEditingController(text: "");
        var cubit = context.read<ListNotesCubit>();
        if (!isAddMode) {
          titleController.text = state.notes[state.selectedIdx].title;
          contentController.text = state.notes[state.selectedIdx].content;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAddMode ? "Add" : "Edit"),
            const SizedBox(height: 16),
            TextField(controller: titleController),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!isAddMode) {
                  cubit.editNote(
                    state.selectedIdx,
                    titleController.text,
                    contentController.text,
                  );
                  if (oldPageCount < 3) {
                    if (oldPageCount == state.pageCount) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context)
                          .popUntil(ModalRoute.withName(ListNotesScreen.route));
                    }
                  }
                } else {
                  cubit.addNote(titleController.text, contentController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }
}
