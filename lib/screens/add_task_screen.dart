import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  final String userId;

  AddTaskScreen({this.task, required this.userId});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'General';
  DateTime? _dueDate;
  String _taskStatus = 'To-Do';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _descriptionController =
        TextEditingController(text: widget.task?.description);
    _selectedCategory = widget.task?.category ?? 'General';
    _dueDate = widget.task?.dueDate;
    _taskStatus = widget.task?.status ?? 'To-Do';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        backgroundColor: const Color.fromARGB(255, 220, 214, 52),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['General', 'Work', 'Personal', 'Other']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Due Date
                ListTile(
                  title: Text(
                    'Due Date: ${_dueDate != null ? DateFormat('dd-MM-yyyy').format(_dueDate!) : 'None'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _dueDate = selectedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: _taskStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['To-Do', 'Urgent', 'Done']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _taskStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 120),

                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 220, 214, 52),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (widget.task == null) {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .add({
                          'title': _titleController.text,
                          'description': _descriptionController.text,
                          'category': _selectedCategory,
                          'dueDate': _dueDate,
                          'status': _taskStatus,
                          'userId': widget.userId,
                        });
                      } else {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(widget.task!.id)
                            .update({
                          'title': _titleController.text,
                          'description': _descriptionController.text,
                          'category': _selectedCategory,
                          'dueDate': _dueDate,
                          'status': _taskStatus,
                          'userId': widget.userId,
                        });
                      }
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  child: Text(
                    widget.task == null ? 'Add Task' : 'Save Changes',
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
