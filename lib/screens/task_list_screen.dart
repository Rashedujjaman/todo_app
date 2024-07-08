import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/screens/profile_screen.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key})
      : super(key: key); // No need for userId parameter

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? _user;
  String? _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  // Function to build the filtered query
  Stream<QuerySnapshot> _getFilteredTasksStream() {
    Query<Map<String, dynamic>> query =
        firestore.collection('tasks').where('userId', isEqualTo: _user!.uid);
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  void _navigateToEditScreen(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(task: task, userId: _user!.uid),
      ),
    ).then((value) => setState(() {}));
  }

  void _deleteTask(Task task) async {
    try {
      await firestore.collection('tasks').doc(task.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const LoginScreen();
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task List'),
          backgroundColor: const Color.fromARGB(255, 220, 214, 52),
          actions: [
            StreamBuilder<DocumentSnapshot>(
              // Get user data for profile image
              stream: firestore.collection('users').doc(_user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final photoURL = userData?['photoURL'] as String?;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage:
                          photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null ? const Icon(Icons.person) : null,
                    ),
                  );
                }
                return const CircleAvatar();
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(children: [
          // Category Filter Dropdown (Floating above task list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['All', 'General', 'Work', 'Personal', 'Other']
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.black),
                        ), // Set text color to black
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: InputDecoration(
                fillColor: const Color.fromARGB(
                    255, 207, 81, 81), // Lighten the fill color
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 0, 0, 0),
                    width: 1,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              // Customize the dropdown menu
              dropdownColor: Colors.grey[200],

              icon: const Icon(Icons.arrow_drop_down, color: Colors.yellow),
              isExpanded: false,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              selectedItemBuilder: (BuildContext context) {
                return ['All', 'General', 'Work', 'Personal', 'Other']
                    .map((String value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedCategory!,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList();
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredTasksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'Error fetching tasks: ${snapshot.error.toString()}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tasks yet.'));
                }

                final tasks = snapshot.data!.docs
                    .map((doc) => Task.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: UniqueKey(),
                      background: Container(color: Colors.red),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          _deleteTask(tasks[index]);
                        }
                      },
                      child: GestureDetector(
                        // Making card tappable for editing
                        onTap: () => _navigateToEditScreen(tasks[index]),
                        child: TaskCard(
                            task: tasks[index],
                            dueDate: task.dueDate,
                            status: task.status,
                            category: task.category),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddTaskScreen(
                        userId: _user!.uid,
                      )),
            ).then((value) => setState(() {}));
          },
          backgroundColor: const Color.fromARGB(255, 220, 214, 52),
          child: const Icon(Icons.add),
        ),
      );
    }
  }
}
