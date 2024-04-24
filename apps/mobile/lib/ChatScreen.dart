import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Sahaya/FamilyMember.dart';

class ChatScreen extends StatefulWidget {
  final FamilyMember member;

  ChatScreen({required this.member});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatUser me;
  late ChatUser otherUser;
  List<ChatMessage> msgs = [];
  List<ChatUser> typing = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    me = ChatUser(id: '12345', firstName: 'Me');
    otherUser = ChatUser(
      id: '67890',
      firstName: widget.member.name,
    );
  }

  getMessages(ChatMessage m) async {
    try {
      typing.add(otherUser);
      msgs.insert(0, m);
      _firestore.collection('chats').add({
        'text': m.text,
        'createdAt': DateTime.now(),
        'userId': me.id,
        'userName': me.firstName,
        'userAvatar': me.profileImage,
        'otherUserId': otherUser.id,
        'otherUserName': otherUser.firstName,
        'otherUserAvatar': otherUser.profileImage,
      });
      setState(() {});
    } catch (e) {
      print("Exception occurred: $e");
    } finally {
      typing.remove(otherUser);
      setState(() {});
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              backgroundImage: NetworkImage(widget.member.avatarUrl),
            ),
            const SizedBox(width: 12),
            Text(widget.member.name),
          ],
        ),
      ),
      body: Expanded(
        child: StreamBuilder(
          stream: _firestore
              .collection('chats')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              final messages = snapshot.data!.docs;
              List<ChatMessage> chatMessages = [];
              for (var message in messages) {
                final text = message['text'];
                final userId = message['userId'];
                final userName = message['userName'];
                final userAvatar = message['userAvatar'];
                final otherUserId = message['otherUserId'];
                final otherUserName = message['otherUserName'];
                final otherUserAvatar = message['otherUserAvatar'];

                final chatMessage = ChatMessage(
                  text: text,
                  user: ChatUser(
                    id: userId,
                    firstName: userName,
                    profileImage: userAvatar,
                  ),
                  createdAt: message['createdAt'].toDate(),
                );
                chatMessages.add(chatMessage);
              }
              return ListView(
                reverse: true,
                children: [
                  DashChat(
                    typingUsers: typing,
                    currentUser: me,
                    onSend: (ChatMessage m) {
                      getMessages(m);
                    },
                    messages: chatMessages,
                    inputOptions: const InputOptions(
                      alwaysShowSend: true,
                      inputDisabled: false,
                      autocorrect: true,
                    ),
                    messageOptions: MessageOptions(
                      currentUserContainerColor: Colors.black,
                      avatarBuilder: (ChatUser user, Function? onAvatarTap,
                          Function? onLongPress) {
                        return CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          backgroundImage:
                              NetworkImage(widget.member.avatarUrl),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
