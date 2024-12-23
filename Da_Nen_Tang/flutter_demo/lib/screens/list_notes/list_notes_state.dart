part of 'list_notes_cubit.dart';

class NoteItem extends Equatable {
  final DateTime dateTime;
  final String title;
  final String content;

  @override
  List<Object?> get props => [dateTime, title, content];

  const NoteItem({
    required this.dateTime,
    required this.title,
    required this.content,
  });

  NoteItem copyWith({
    DateTime? dateTime,
    String? title,
    String? content,
  }) {
    return NoteItem(
      dateTime: dateTime ?? this.dateTime,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}

class ListNotesState extends Equatable {
  final List<NoteItem> notes;
  final int selectedIdx;
  final int pageCount;

  @override
  List<Object> get props => [notes, selectedIdx, pageCount];

  const ListNotesState({
    this.notes = const [],
    this.selectedIdx = 0,
    this.pageCount = 1,
  });

  ListNotesState copyWith({
    List<NoteItem>? notes,
    int? selectedIdx,
    int? pageCount,
  }) {
    return ListNotesState(
      notes: notes ?? this.notes,
      selectedIdx: selectedIdx ?? this.selectedIdx,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
