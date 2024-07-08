import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String title;
  String description;
  String category;
  String status;
  String userId;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.status = 'To-Do',
    required this.userId,
    this.dueDate,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'To-Do',
      userId: data['userId'] ?? '',
      dueDate: (data['dueDate'] != null)
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'userId': userId,
      'dueDate': dueDate,
    };
  }
}
