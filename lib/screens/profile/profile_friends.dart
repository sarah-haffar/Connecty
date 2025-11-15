import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileFriends extends StatelessWidget {
  final String? userId;
  final bool isCurrentUser;
  final Color primaryColor;

  const ProfileFriends({
    super.key,
    required this.userId,
    required this.isCurrentUser,
    required this.primaryColor,
  });

  Stream<QuerySnapshot> get _userFriendsStream {
    final String userIdToLoad = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userIdToLoad.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userIdToLoad)
        .collection('friends')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildFriendsContent(),
        ],
      ),
    );
  }

  Widget _buildFriendsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userFriendsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyFriendsState();
        }

        final friends = snapshot.data!.docs;
        return _buildFriendsList(friends);
      },
    );
  }

  Widget _buildEmptyFriendsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 50,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            isCurrentUser
                ? "Aucun ami pour le moment"
                : "Cet utilisateur n'a pas encore d'amis",
            style: TextStyle(color: primaryColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(List<QueryDocumentSnapshot> friends) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: friends.map((doc) {
        final friendId = doc.id;
        final friendData = doc.data() as Map<String, dynamic>;
        
        return Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                friendData['friendName']?[0] ?? '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              friendData['friendName'] ?? 'Ami',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}