import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connecty_app/widgets/post_card.dart';

class ProfilePosts extends StatelessWidget {
  final String? userId;
  final bool isCurrentUser;
  final Color primaryColor;
  final void Function(BuildContext, String, Map<String, dynamic>)? onShowPostOptions;

  const ProfilePosts({
    super.key,
    required this.userId,
    required this.isCurrentUser,
    required this.primaryColor,
    this.onShowPostOptions,
  });

  Stream<QuerySnapshot> get _userPostsStream {
    if (userId == null || userId!.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filtrage : exclure quiz et quizScore
        final filteredPosts = snapshot.data!.docs.where((doc) {
          final postData = doc.data() as Map<String, dynamic>?;

          if (postData == null) return false;

          final postType = postData['postType'] ?? 'text';

          // Seuls les posts classiques de l'utilisateur
          return postType != 'quiz' && postType != 'quizScore';
        }).toList();

        return _buildPostsList(context, filteredPosts);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 60,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune publication",
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCurrentUser
                ? "Partagez votre première publication !"
                : "Cet utilisateur n'a pas encore publié",
            style: TextStyle(
              fontSize: 14,
              color: primaryColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, List<QueryDocumentSnapshot> posts) {
    return Column(
      children: [
        // Indicateur du nombre de posts
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${posts.length} publication${posts.length > 1 ? 's' : ''}",
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Liste des posts
        ...posts.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return GestureDetector(
            onLongPress: (isCurrentUser && onShowPostOptions != null)
                ? () => onShowPostOptions!(context, doc.id, data)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: PostCard(
                postId: doc.id,
                username: data['userName'] ?? 'Utilisateur',
                content: data['text'] ?? '',
                imageUrl: data['fileUrl'],
                fileType: data['fileType'],
                timestamp: data['timestamp'],
                isInitiallyFavorite: false,
                onFavoriteToggle: (postMap, isFav) {
                  // Logique des favoris si nécessaire
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
