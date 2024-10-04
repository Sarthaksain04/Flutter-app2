import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoes2/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'View.dart'; // Ensure this import is correct based on your project structure

class PostScreen extends StatefulWidget {
  const PostScreen({
    super.key,
    required this.panelController,
  });

  final PanelController panelController;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen>
    with SingleTickerProviderStateMixin {
  final messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel> fetchUser;
  late TabController _tabController;
  String headerTitle = 'New String';

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? _image; // Variable to store the selected image

  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void initState() {
    super.initState();
    fetchUser = fetchUserData();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          headerTitle = _tabController.index == 1 ? 'New Post' : 'New String';
        });
      }
    });
  }

  Future<UserModel> fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('Images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> postThreadMessage(String username) async {
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      if (messageController.text.isNotEmpty || imageUrl != null) {
        await FirebaseFirestore.instance.collection('threads').add({
          'id': currentUser?.uid ?? '',
          'sender': username,
          'message': messageController.text,
          'imageUrl': imageUrl, // Include image URL if available
          'timestamp': FieldValue.serverTimestamp(),
        });
        messageController.clear();
        setState(() {
          _image = null; // Clear the image after posting
        });
        widget.panelController.close();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting message: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<UserModel>(
        future: fetchUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No user data available'));
          }

          final user = snapshot.data!;
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Header and Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          widget.panelController.close();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        headerTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      TextButton(
                        onPressed: () => postThreadMessage(user.username),
                        child: const Text(
                          'Post',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Strings'),
                    Tab(text: 'Posts'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Strings Tab
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    foregroundImage: NetworkImage(
                                        user.profileImageUrl ?? ""),
                                    radius: 25,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.username,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextFormField(
                                          controller: messageController,
                                          decoration: const InputDecoration(
                                            hintText: 'Start a String...',
                                            hintStyle: TextStyle(fontSize: 14),
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null,
                                          style: const TextStyle(fontSize: 14),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      // Posts Tab
                      // Inside the Posts Tab of your TabBarView
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  foregroundImage:
                                      NetworkImage(user.profileImageUrl ?? ""),
                                  radius: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.arrow_drop_down),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.access_time),
                                  onPressed: () {
                                    _showScheduleBottomSheet(context);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 1 , left: 30.0),
                              child: TextField(
                                controller: messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Share your posts...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                maxLines: null,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),

                            if (_image != null) // Display selected image with circular icons on top-right corner
                              Padding(
                                padding: const EdgeInsets.only(top: 37.0, left: 15),
                                child: Stack(
                                  clipBehavior: Clip.none, // Allows icons to be positioned outside the frame
                                  children: [
                                    Container(
                                      height: 350,
                                      width: 350,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color.fromARGB(255, 255, 255, 255), // Frame color
                                          width: 8,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.6), // Shadow color
                                            spreadRadius: 1, // Spread radius of the shadow
                                            blurRadius: 1, // Blur radius of the shadow
                                          ),
                                        ],
                                      image: DecorationImage(
                                        image: FileImage(_image!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              Positioned(
                                top: -50, // Position outside the frame
                                right: 10, // Position outside the frame
                                child: Row(
                                  children: [
                                    // Edit Icon
                                    Container(
                                      width: 40, // Width of the circle
                                      height: 40, // Height of the circle
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromARGB(255, 0, 0, 0), // White background for circle
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.edit, color: const Color.fromARGB(255, 255, 255, 255)),
                                        iconSize: 20, 
                                        onPressed: () {
                                          // Add functionality for editing the image
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8), 
                                   
                                    Container(
                                      width: 40, // Width of the circle
                                      height: 40, // Height of the circle
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromARGB(255, 0, 0, 0), // White background for circle
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.close, color: const Color.fromARGB(255, 255, 255, 255)),
                                        iconSize: 20, // Size of the icon
                                        onPressed: () {
                                          setState(() {
                                            _image = null; // Clear the image
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.auto_awesome),
                                  onPressed: () {
                                    // Add functionality for AI rewriting here
                                  },
                                ),
                                Text(
                                  'Rewrite with AI',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const Spacer(),
                                Text(
                                  '0/20',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                IconButton(
                                  icon: Icon(Icons.image),
                                  onPressed: _pickImage, // Use image picker
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    // Add functionality to add more options here
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScheduleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ViewScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: selectedDate != null
                      ? '${selectedDate!.toLocal()}'.split(' ')[0]
                      : 'Select Date',
                ),
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 30.0),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: selectedTime != null
                      ? selectedTime!.format(context)
                      : 'Select Time',
                ),
                decoration: InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null && pickedTime != selectedTime) {
                    setState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
              ),
              SizedBox(height: 16.0),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    // Perform the scheduling action here
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
