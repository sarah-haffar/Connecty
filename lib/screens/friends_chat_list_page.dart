// lib/pages/friends_chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friendship_service.dart';
import 'chat_page.dart';

class FriendsChatListPage extends StatelessWidget {
  const FriendsChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FriendshipService.getUserFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final friendId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final friendName = data['friendName'] as String? ?? 'Ami';

              return _FriendChatTile(
                friendId: friendId,
                friendName: friendName,
                currentUserId: currentUserId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 90, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text("Aucun ami", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Ajoutez des amis pour discuter !", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// TILE ULTIME — PHOTO TOUJOURS AFFICHÉE, POINT VERT, TOUT PARFAIT
class _FriendChatTile extends StatelessWidget {
  final String friendId;
  final String friendName;
  final String currentUserId;

  const _FriendChatTile({
    required this.friendId,
    required this.friendName,
    required this.currentUserId,
  });

  String get chatId {
    final ids = [currentUserId, friendId];
    ids.sort();
    return ids.join('_');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // On récupère les données utilisateur en temps réel (photo + statut en ligne)
      stream: FirebaseFirestore.instance.collection('users').doc(friendId).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        // On essaie profileImage d'abord, puis photoUrl (compatibilité totale)
        final photoUrl = (userData?['profileImage'] as String?) ??
            (userData?['photoUrl'] as String?);
        final isOnline = userData?['isOnline'] == true;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
          builder: (context, chatSnap) {
            final chatData = chatSnap.data?.data() as Map<String, dynamic>?;
            final lastMessage = chatData?['lastMessage'] as String? ?? '';
            final lastTime = (chatData?['lastMessageTime'] as Timestamp?)?.toDate();
            final unreadCount = (chatData?['unreadCount_$currentUserId'] as int?) ?? 0;
            final isTyping = chatData?['typing_$friendId'] == true;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              horizontalTitleGap: 12,
              leading: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      backgroundColor: photoUrl == null || photoUrl.isEmpty
                          ? const Color(0xFF6A1B9A)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                        friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                          : null,
                    ),
                    // Point vert si en ligne
                    if (isOnline)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              title: Text(
                friendName,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: isTyping
                  ? const Row(
                children: [
                  Text(
                    "en train d’écrire",
                    style: TextStyle(color: Color(0xFF6A1B9A), fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  _TypingDots(),
                ],
              )
                  : Text(
                lastMessage.isEmpty ? "Aucun message" : lastMessage,
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lastTime != null)
                    Text(
                      _formatTime(lastTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: unreadCount > 0 ? const Color(0xFF6A1B9A) : Colors.grey[600],
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
                      child: Text(
                        unreadCount > 99 ? "99+" : "$unreadCount",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      friendId: friendId,
                      friendName: friendName,
                      friendPhotoUrl: photoUrl, // Toujours la vraie photo
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (messageDay == yesterday) {
      return "Hier";
    } else {
      return "${date.day}/${date.month}";
    }
  }
}

// Animation des 3 points quand quelqu’un tape
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: ScaleTransition(
            scale: Tween(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Interval(i * 0.2, 1.0, curve: Curves.easeOut)),
            ),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
            ),
          ),
        )),
      ),
    );
  }
}