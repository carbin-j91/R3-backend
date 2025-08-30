import 'dart:convert';

class RunEdit {
  final String? title;
  final String? notes;

  RunEdit({this.title, this.notes});

  String toJson() {
    return jsonEncode({'title': title, 'notes': notes});
  }
}
