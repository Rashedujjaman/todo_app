import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_app/screens/login_screen.dart'; // Make sure this path is correct
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  DocumentSnapshot? _userData;
  File? _imageFile;
  bool _isUpdatingImage = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc;
        });
      } else {}
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUpdatingImage = true;
      });

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${_user!.uid}.jpg');

        // Ensure the upload task completes before getting the download URL
        UploadTask uploadTask = ref.putFile(_imageFile!);
        await uploadTask.whenComplete(() => null);

        final photoURL = await ref.getDownloadURL();

        await _firestore.collection('users').doc(_user!.uid).update({
          'photoURL': photoURL,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh _userData correctly after the update
        _userData = await _firestore.collection('users').doc(_user!.uid).get();

        setState(() {
          _isUpdatingImage = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    String newName = _userData?['name'] ?? _user?.displayName ?? '';
    String newMobile = _userData?['mobile'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.yellow[100],
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'New Name',
                ),
                onChanged: (value) {
                  newName = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'New Mobile',
                ),
                onChanged: (value) {
                  newMobile = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  if (_user != null) {
                    await _user!.updateDisplayName(newName);

                    await _firestore
                        .collection('users')
                        .doc(_user!.uid)
                        .update({
                      'name': newName,
                      'mobile': newMobile,
                    });

                    // Refresh _userData correctly
                    DocumentSnapshot<Map<String, dynamic>> updatedUserData =
                        await _firestore
                            .collection('users')
                            .doc(_user!.uid)
                            .get();

                    // Cast updatedUserData to DocumentSnapshot<Object?>?
                    _userData = updatedUserData;
                    // Now, _userData will contain the updated data and the type will match

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated successfully')),
                      );
                    }

                    setState(() {
                      // No need to refresh here since we already did it above
                    });
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update profile'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // User not logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Login to enjoy!'),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    } else {
      // User logged in
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color.fromARGB(255, 220, 214, 52),
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: ListView(
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_userData?.get('photoURL') != null
                                    ? NetworkImage(_userData!.get('photoURL'))
                                    : const AssetImage(
                                        "assets/images/add_image.png"))
                                as ImageProvider<Object>?,
                        backgroundColor: Colors.grey[300],
                        child: _imageFile == null &&
                                _userData?.get('photoURL') == null
                            ? const Icon(Icons.add_a_photo,
                                size: 30, color: Colors.white)
                            : null,
                      ),
                    ),
                    if (_isUpdatingImage)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                  ],
                ),
              ),

              //horizontal line
              const Divider(
                color: Colors.transparent,
                height: 50,
                thickness: 1,
                indent: 0,
                endIndent: 0,
              ),

              // Show user data

              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Name :',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${_userData?['name'] ?? _user?.displayName ?? ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'Email :',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _user?.email ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (_userData?['mobile'] != null)
                      ListTile(
                        title: const Text(
                          'Mobile :',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '${_userData!['mobile']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (_userData?['createdAt'] != null)
                      ListTile(
                        title: const Text(
                          'Member Since :',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '${DateFormat.yMMMd().format(_userData!['createdAt'].toDate())}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                  onPressed: _editProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 220, 214, 52),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _logout();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ).then((value) => setState(() {}));
          },
          tooltip: 'Click to Logout',
          backgroundColor: const Color.fromARGB(255, 220, 214, 52),
          hoverColor: Colors.red,
          child: const Icon(Icons.logout_sharp),
        ),
      );
    }
  }
}
