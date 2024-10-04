import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoes2/model/thread_message.dart';
import 'package:echoes2/model/user.dart';
import 'package:echoes2/widgets/thread_message.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';


class CommentScreen extends StatefulWidget {
  const CommentScreen({
    super.key,
    required this.message,
    required this.panelController,
    required this.threadId,
  });

  final ThreadMessage message;
  final PanelController panelController;
  final String threadId;

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CollectionReference threadCollection =
      FirebaseFirestore.instance.collection('threads');

  Stream<UserModel> fetchUserData(String id) {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(id).snapshots();
      return userDoc.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'String',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ThreadMessageWidget(
                message: widget.message,
                onLike: () {},
                onDisLike: () {},
                onComment: () {},
                panelController: widget.panelController,
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: threadCollection.doc(widget.threadId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;

                  if (data == null) {
                    return const Text('No data available');
                  }

                  final comments = data['comments'] as List<dynamic>?;

                  if (comments == null) {
                    return const Text('No comments');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index] as Map<String, dynamic>;

                      DateTime timeStamp = DateTime.now();

                      if (comment.containsKey('time') &&
                          comment['time'] != null) {
                        timeStamp = (comment['time'] as Timestamp).toDate();
                      }

                      return StreamBuilder<UserModel>(
                        stream: fetchUserData(comment['id']),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (userSnapshot.hasError) {
                            return Text('Error: ${userSnapshot.error}');
                          }

                          final user = userSnapshot.data;

                          if (user == null) {
                            return const Text('User not found');
                          }

                          final message = ThreadMessage(
                            id: comment['id'],
                            senderName: user.name,
                            senderProfileImageUrl: user.profileImageUrl ?? "",
                            message: comment['text'],
                            timestamp: timeStamp,
                            likes: [],
                            comments: [], 
                            imageUrl: '',
                          );

                          return ThreadMessageWidget(
                            message: message,
                            onLike: () {},
                            onDisLike: () {},
                            onComment: () {},
                            panelController: widget.panelController,
                          );
                        },
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
