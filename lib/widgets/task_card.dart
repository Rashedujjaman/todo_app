import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String status;
  final String category;
  final DateTime? dueDate;

  const TaskCard({
    super.key,
    required this.task,
    required this.status,
    required this.category,
    this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.yellow[50],
      child: ListTile(
        title: Text(task.title),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        dense: false,
        subtitle: Text(task.description),
        subtitleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 10,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (dueDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(category),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                color: _getStatusColor(status),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        leadingAndTrailingTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To-Do':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      case 'Done':
        return Colors.green;
      default:
        return Colors.white; // Or another default color
    }
  }
}
