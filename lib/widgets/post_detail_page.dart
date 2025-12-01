import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/interaction_service.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String username;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;
  final Timestamp? timestamp;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.username,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
    this.timestamp,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final Color primaryColor = const Color(0xFF6A1B9A); // violet foncé
  final Color backgroundColor = const Color(0xFFEDE7F6); // violet lila clair

  final TextEditingController _commentController = TextEditingController();
  bool showLikes = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    await InteractionService.addComment(widget.postId, _commentController.text);
    _commentController.clear();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + username
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor,
                    child: Text(
                      widget.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTimestamp(widget.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.imageUrl!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
              if (widget.imageUrl != null) const SizedBox(height: 12),
              Text(
                widget.content,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 20),
              // Boutons Like / Commentaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StreamBuilder<int>(
                    stream: InteractionService.getLikesCount(widget.postId),
                    builder: (context, snapshot) {
                      final likesCount = snapshot.data ?? 0;
                      return ElevatedButton.icon(
                        onPressed: () {
                          setState(() => showLikes = !showLikes);
                        },
                        icon: const Icon(Icons.thumb_up, color: Colors.white),
                        label: Text("J'aime ($likesCount)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: InteractionService.getComments(widget.postId),
                    builder: (context, snapshot) {
                      final commentsCount = snapshot.data?.docs.length ?? 0;
                      return ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.comment, color: Colors.white),
                        label: Text("Commentaires ($commentsCount)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Liste des likes (affiché si showLikes = true)
              if (showLikes)
                StreamBuilder<QuerySnapshot>(
                  stream: InteractionService.getLikes(widget.postId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final likes = snapshot.data!.docs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "J'aime (${likes.length})",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...likes.take(10).map((doc) {
                          final like = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Text(
                                like['userName'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              like['userName'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }),
                        if (likes.length > 10)
                          Text(
                            "Et ${likes.length - 10} autres...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              const Text(
                "Commentaires",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Liste des commentaires via Firestore
              StreamBuilder<QuerySnapshot>(
                stream: InteractionService.getComments(widget.postId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return const Text(
                      "Aucun commentaire pour le moment",
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return Column(
                    children: [
                      ...comments.map((doc) {
                        final comment = doc.data() as Map<String, dynamic>;
                        final isCurrentUser =
                            comment['userId'] ==
                            InteractionService.getCurrentUserId();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Text(
                              comment['userName'][0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            comment['userName'],
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            comment['content'],
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: isCurrentUser
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => InteractionService.deleteComment(
                                    widget.postId,
                                    doc.id,
                                  ),
                                )
                              : null,
                        );
                      }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Champ pour ajouter un commentaire
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Ajouter un commentaire...",
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
