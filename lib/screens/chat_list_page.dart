// lib/screens/ChatListPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService.getChatPreviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune discussion\nCommencez à discuter !", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final c = snapshot.data![i];
              final unread = c['unreadCount'] as int? ?? 0;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: c['friendPhotoUrl'] != null ? NetworkImage(c['friendPhotoUrl']) : null,
                      child: c['friendPhotoUrl'] == null ? Text(c['friendName'][0].toUpperCase()) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: ChatService.friendStatus(c['friendId']),
                        builder: (context, snap) {
                          final online = (snap.data?.data() as Map?)?['isOnline'] == true;
                          return online ? Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))) : const SizedBox();
                        },
                      ),
                    ),
                  ],
                ),
                title: Text(c['friendName'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: c['isTyping'] == true
                    ? const Text("en train d'écrire...", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic))
                    : Text(c['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: unread > 0
                    ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                )
                    : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(friendId: c['friendId'], friendName: c['friendName']))),
              );
            },
          );
        },
      ),
    );
  }
}