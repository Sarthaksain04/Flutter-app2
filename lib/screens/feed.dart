import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoes2/model/thread_message.dart';
import 'package:echoes2/screens/Gemini.dart';
import 'package:echoes2/screens/comment_screen.dart';
import 'package:echoes2/screens/nfc.dart';
import 'package:echoes2/screens/post_comment_screen.dart';
import 'package:echoes2/widgets/thread_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CollectionReference threadCollection = FirebaseFirestore.instance.collection('threads');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  
  String threadDoc = '';
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  PanelController panelController = PanelController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NFCApp()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 1.0),
                child: Image.asset(
                  "assets/thread_logo.png",
                  width: 50,
                ),
              ),
            )
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Gemini()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SlidingUpPanel(
          controller: panelController,
          minHeight: 0,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          panelBuilder: (ScrollController sc) {
            return PostCommentScreen(
              threadDoc: threadDoc,
              panelController: panelController,
            );
          },
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: StreamBuilder<QuerySnapshot>(
                  stream: threadCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final messageData = messages[index].data() as Map<String, dynamic>;

                          DateTime timestamp = messageData.containsKey('timestamp') && messageData['timestamp'] != null
                              ? (messageData['timestamp'] as Timestamp).toDate()
                              : DateTime.now(); // Use current time if timestamp is null

                          return FutureBuilder<String>(
                            future: getSenderImageUrl(messageData['id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

                              final message = ThreadMessage(
                                id: messageData['id'],
                                senderName: messageData['sender'],
                                senderProfileImageUrl: snapshot.data ?? "",
                                message: messageData['message'],
                                timestamp: timestamp,
                                likes: messageData['likes'] ?? [],
                                comments: messageData['comments'] ?? [],
                                imageUrl: messageData['imageUrl'] ?? '',
                              );

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentScreen(
                                        message: message,
                                        panelController: panelController,
                                        threadId: messages[index].id,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ThreadMessageWidget(
                                      message: message,
                                      onDisLike: () => dislikeThreadMessage(messages[index].id),
                                      onLike: () => likeThreadMessage(messages[index].id),
                                      onComment: () {
                                        setState(() {
                                          threadDoc = messages[index].id;
                                        });
                                      },
                                      panelController: panelController,
                                    ),
                                    if (message.imageUrl.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(message.imageUrl),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        childCount: messages.length,
                      ),
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

  Future<String> getSenderImageUrl(String id) async {
    final userDoc = await userCollection.doc(id).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['profileImageUrl'] ?? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRz8cLf8-P2P8GZ0-KiQ-OXpZQ4bebpa3K3Dw&usqp=CAU";
    }
    return '';
  }

  Future<void> likeThreadMessage(String id) async {
    try {
      await threadCollection.doc(id).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      debugPrint('Error liking message: $e');
    }
  }

  Future<void> dislikeThreadMessage(String id) async {
    try {
      await threadCollection.doc(id).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('Error disliking message: $e');
    }
  }
}
