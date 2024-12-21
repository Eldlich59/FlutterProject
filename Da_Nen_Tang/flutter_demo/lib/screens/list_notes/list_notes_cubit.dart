import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'list_notes_state.dart';

class ListNotesCubit extends Cubit<ListNotesState> {
  ListNotesCubit() : super(const ListNotesState()) {
    var newNotes = [
      NoteItem(dateTime: DateTime.now(), title: "1", content: "11"),
      NoteItem(
          dateTime: DateTime.now().subtract(const Duration(hours: 1)),
          title: "2",
          content: "22"),
    ];
    emit(state.copyWith(notes: newNotes));
  }

  void addNote(String title, String content) {
    var newNotes = [
      NoteItem(dateTime: DateTime.now(), title: title, content: content),
      ...state.notes,
    ];
    emit(state.copyWith(notes: newNotes));
  }

  void removeNote(int index) {
    var newNotes = [...state.notes];
    newNotes.removeAt(index);
    emit(state.copyWith(notes: newNotes));
  }

  void editNote(int index, String title, String content) {
    var newNotes = [...state.notes];
    newNotes[index] = newNotes[index].copyWith(title: title, content: content);
    emit(state.copyWith(notes: newNotes));
  }

  void setPageCount(int pageCount) {
    emit(state.copyWith(pageCount: pageCount));
  }

  void setSelectedIdx(int selectedIdx) {
    emit(state.copyWith(selectedIdx: selectedIdx));
  }
}
