import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoes2/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart'; // Adjust the import according to your file structure

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  final userId = FirebaseAuth.instance.currentUser!.uid;

  String searchQuery = "";
  final searchController = TextEditingController();

  List<UserModel> searchUsers(List<UserModel> users, String query) {
    return users.where((user) {
      return user.username.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<void> followUser(UserModel user) async {
    await userCollection.doc(userId).update({
      'following': FieldValue.arrayUnion([user.id])
    });
    await userCollection.doc(user.id).update({
      'followers': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unFollowUser(UserModel user) async {
    await userCollection.doc(userId).update({
      'following': FieldValue.arrayRemove([user.id])
    });
    await userCollection.doc(user.id).update({
      'followers': FieldValue.arrayRemove([userId])
    });
  }

  @override
  void initState() {
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          },
        ),
        title: const Text('Search', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextFormField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder(
                  stream: userCollection
                      .where('id', isNotEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final users = snapshot.data!.docs;

                    final allUsers = users.map((doc) {
                      final user = doc.data() as Map<String, dynamic>;
                      return UserModel(
                        id: user['id'],
                        username: user['username'],
                        profileImageUrl: user['profileImageUrl'],
                        name: user['name'],
                        followers: [],
                        following: [],
                      );
                    }).toList();
                    final filteredUsers = searchUsers(allUsers, searchQuery);

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];

                        return SuggestedFollowerWidget(
                          user: user,
                          follow: () => followUser(user),
                          unFollow: () => unFollowUser(user),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuggestedFollowerWidget extends StatefulWidget {
  const SuggestedFollowerWidget({
    super.key,
    required this.user,
    required this.follow,
    required this.unFollow,
  });

  final UserModel user;
  final VoidCallback follow;
  final VoidCallback unFollow;

  @override
  State<SuggestedFollowerWidget> createState() =>
      _SuggestedFollowerWidgetState();
}

class _SuggestedFollowerWidgetState extends State<SuggestedFollowerWidget> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(widget.user.profileImageUrl ??
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRz8cLf8-P2P8GZ0-KiQ-OXpZQ4bebpa3K3Dw&usqp=CAU"),
            backgroundColor: Colors.white,
          ),
          title: Text(widget.user.username),
          subtitle: Text(widget.user.username.toLowerCase()),
          trailing: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final currentUser = UserModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);
                final isFollowing =
                    currentUser.following.contains(widget.user.id);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: isFollowing ? widget.unFollow : widget.follow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                        foregroundColor: isFollowing ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    ),
                  ],
                );
              }),
        ),
        const Divider(),
      ],
    );
  }
}
