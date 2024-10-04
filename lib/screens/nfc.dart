import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class User {
  final String name;
  final String bio;
  final String profileImageUrl;

  User({required this.name, required this.bio, required this.profileImageUrl});
}

class NFCApp extends StatefulWidget {
  const NFCApp({super.key});

  @override
  _NFCAppState createState() => _NFCAppState();
}

class _NFCAppState extends State<NFCApp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Static user data with image URLs
  final List<User> users = [
    User(
      name: "Asmi Mishra",
      bio: "Hi, I am using Echoes!",
      profileImageUrl: '', // Provide an image URL if needed
    ),
    User(
      name: "Aman Jain",
      bio: "Loving the Echoes experience!",
      profileImageUrl: '',
    ),
    User(
      name: "Chandan Suthar",
      bio: "Exploring new connections.",
      profileImageUrl: 'assets/yash.jpg',
    ),
    User(
      name: "Ankit Sharma",
      bio: "Excited to share memories!",
      profileImageUrl: 'https://yourstorageurl.com/Ankit.jpg',
    ),
    User(
      name: "Yash",
      bio: "Creating beautiful moments.",
      profileImageUrl: 'https://yourstorageurl.com/yash.jpg',
    ),
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Upload user data to Firestore
    _uploadUsersToFirestore();

    // Simulate checking for nearby users after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _showBottomSheetForUsers();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _uploadUsersToFirestore() async {
    for (User user in users) {
      await _firestore.collection('users').add({
        'name': user.name,
        'bio': user.bio,
        'profileImageUrl': user.profileImageUrl,
      });
    }
  }

  void _showBottomSheetForUsers() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: users.map((user) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    if (user.profileImageUrl.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.profileImageUrl),
                        radius: 30,
                      )
                    else
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 30),
                        radius: 30,
                      ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "User: ${user.name}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user.bio,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Add your connect action here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected with ${user.name}')),
                        );
                      },
                      child: Text('Connect'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return SizedBox(
                    width: 280,
                    height: 280,
                    child: Transform.scale(
                      scale: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.grey.withOpacity(0.8),
                              Colors.grey.withOpacity(0.3),
                            ],
                            center: Alignment.center,
                            radius: 0.6,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 131, 127, 127)
                          .withOpacity(1),
                      blurRadius: 2,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/thread_logo.png',
                  width: 80,
                  height: 80,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const NFCApp());
}
