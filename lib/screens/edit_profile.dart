import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import the PDF view package
import 'package:image_picker/image_picker.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:echoes2/model/user.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({
    super.key,
    required this.panelController,
    required this.user,
  });

  final PanelController panelController;
  final UserModel? user;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final bioController = TextEditingController();
  final linkController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isChecked = false;
  String profileImageUrl = "";
  String resumeUrl = ""; // To store resume URL
  String resumeStatusMessage = ""; // Variable to hold resume upload status message

  Future<void> updateUserProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .set({
        'bio': bioController.text,
        'link': linkController.text,
        'profileImageUrl': profileImageUrl,
        'resumeUrl': resumeUrl, // Save resume URL to Firestore
      }, SetOptions(merge: true));

      widget.panelController.close();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${currentUser!.uid}.jpg');
      try {
        final upload = storageRef.putFile(file);
        final snapshot = await upload.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          profileImageUrl = downloadUrl;
        });
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> uploadResume() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes/${currentUser!.uid}.pdf');

      try {
        final upload = storageRef.putFile(file);
        final snapshot = await upload.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          resumeUrl = downloadUrl;
          resumeStatusMessage = "Resume successfully uploaded"; // Update status message
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'resumeUrl': downloadUrl});

        debugPrint("Resume uploaded: $resumeUrl");
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      setState(() {
        resumeStatusMessage = "Resume is not uploaded"; // Update status message if no file is selected
      });
    }
  }

  // Method to view the PDF
  void viewResume() {
    if (resumeUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(pdfUrl: resumeUrl),
        ),
      );
    } else {
      // Show a message if there is no resume to display
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No resume uploaded to view.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    profileImageUrl = widget.user?.profileImageUrl ?? "";
    bioController.text = widget.user?.bio ?? "";
    linkController.text = widget.user?.link ?? "";
    resumeUrl = widget.user?.resumeUrl ?? ""; // Initialize with existing resume URL
    resumeStatusMessage = resumeUrl.isEmpty ? "Resume is not uploaded" : "Resume successfully uploaded"; // Initial status message
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9.0),
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
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                TextButton(
                  onPressed: updateUserProfile,
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color.fromARGB(255, 146, 143, 143), width: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Name'),
                        subtitle: Text(
                            '${widget.user?.name} (@${widget.user?.username})'),
                        trailing: InkWell(
                          onTap: uploadImage,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl),
                            radius: 20,
                          ),
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      ListTile(
                        title: const Text('Bio'),
                        subtitle: TextFormField(
                          controller: bioController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Bio goes here...',
                            hintStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      ListTile(
                        title: const Text('Link'),
                        subtitle: TextFormField(
                          controller: linkController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'www.linkedin.com/in/sarthak-sain-795606257',
                            hintStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Private profile'),
                            Switch(
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  isChecked = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      ListTile(
                        title: const Text('Resume'),
                        trailing: TextButton(
                          onPressed: uploadResume,
                          child: const Text('Upload Resume'),
                        ),
                      ),
                      // Display the resume status message
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          resumeStatusMessage,
                          style: TextStyle(
                            color: resumeUrl.isEmpty ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('View Resume'),
                        trailing: TextButton(
                          onPressed: viewResume,
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New PDFViewerScreen to display the PDF
class PDFViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PDFViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume'),
      ),
      body: PDFView(
        filePath: pdfUrl, 
      ),
    );
  }
}
