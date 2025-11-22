import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';

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
          _buildFriendsContent(context),
        ],
      ),
    );
  }

  Widget _buildFriendsContent(BuildContext context) {
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
        return _buildFriendsList(context, friends);
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

  Widget _buildFriendsList(BuildContext context, List<QueryDocumentSnapshot> friends) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: friends.map((doc) {
        final friendId = doc.id;
        final friendData = doc.data() as Map<String, dynamic>;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildFriendSkeleton();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return _buildUnknownFriend();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            return _buildFriendItem(context, userData, friendId);
          },
        );
      }).toList(),
    );
  }

  Widget _buildFriendItem(BuildContext context, Map<String, dynamic> userData, String friendId) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers le profil de l'ami
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: friendId),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: userData['profileImage'] != null
                    ? NetworkImage(userData['profileImage']!) as ImageProvider
                    : const AssetImage("assets/post/art.jpg"),
                child: userData['profileImage'] == null
                    ? Text(
                        userData['name']?[0] ?? '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      )
                    : null,
              ),
              // Badge en ligne (optionnel)
              if (userData['isOnline'] == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              userData['name'] ?? 'Ami',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendSkeleton() {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 8,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildUnknownFriend() {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person_off, color: Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        const Text(
          "Inconnu",
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}