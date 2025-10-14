import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;
  final Color usernameColor;
  final Color contentColor;
  final void Function(Map<String, dynamic> postMap, bool isFavorite)? onFavoriteToggle;


  const PostCard({
    super.key,
    required this.username,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
    this.usernameColor = Colors.black,
    this.contentColor = Colors.black,
    this.onFavoriteToggle,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool showComments = false;
  bool showLikes = false;
  bool isFavorite = false;

  final List<String> likedUsers = ["Sarah", "Ahmed", "Feriel"];

  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color backgroundColor = const Color(0xFFEDE7F6);

  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> comments = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.profileImageUrl != null)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(widget.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  child: Text(widget.username[0],
                      style: const TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 10),
              Text(
                widget.username,
                style: TextStyle(
                  color: widget.usernameColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.content,
            style: TextStyle(
              color: widget.contentColor,
              fontSize: 14,
            ),
          ),
          if (widget.imageUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                final TextEditingController _modalCommentController = TextEditingController();
                bool _showLikes = false;
                bool _showComments = true;

                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setModalState) => Container(
                        width: 600,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Partie gauche : Image
                            if (widget.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  widget.imageUrl!,
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar + username
                                    Row(
                                      children: [
                                        if (widget.profileImageUrl != null)
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage: AssetImage(widget.profileImageUrl!),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: primaryColor,
                                            child: Text(widget.username[0],
                                                style: const TextStyle(color: Colors.white)),
                                          ),
                                        const SizedBox(width: 10),
                                        Text(widget.username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(widget.content, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        _actionIcon(Icons.thumb_up, _showLikes, () {
                                          setModalState(() {
                                            _showLikes = !_showLikes;
                                          });
                                        }),
                                        const SizedBox(width: 20),
                                        _actionIcon(Icons.comment, _showComments, () {
                                          setModalState(() {
                                            _showComments = !_showComments;
                                          });
                                        }),
                                        const SizedBox(width: 20),
                                        _actionIcon(Icons.share, false, () {}),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_showComments)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Commentaires",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          ...comments.map(
                                                (comment) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                  backgroundColor: primaryColor,
                                                  child: Text(comment['username']![0],
                                                      style: const TextStyle(color: Colors.white))),
                                              title: Text(comment['username']!,
                                                  style: const TextStyle(color: Colors.black)),
                                              subtitle: Text(comment['content']!,
                                                  style: const TextStyle(color: Colors.black54)),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 18),
                                                    onPressed: () {
                                                      final controller =
                                                      TextEditingController(text: comment['content']);
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => AlertDialog(
                                                          title: const Text("Modifier le commentaire"),
                                                          content: TextField(
                                                            controller: controller,
                                                            decoration: const InputDecoration(
                                                              hintText: "Modifier...",
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              child: const Text("Annuler"),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                setModalState(() {
                                                                  comment['content'] = controller.text;
                                                                });
                                                                Navigator.pop(context);
                                                              },
                                                              child: const Text("Modifier"),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 18),
                                                    onPressed: () {
                                                      setModalState(() {
                                                        comments.remove(comment);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _modalCommentController,
                                                  style: TextStyle(color: primaryColor),
                                                  decoration: InputDecoration(
                                                    hintText: "Ajouter un commentaire...",
                                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.send),
                                                color: primaryColor,
                                                onPressed: () {
                                                  if (_modalCommentController.text.isNotEmpty) {
                                                    setModalState(() {
                                                      comments.add({
                                                        'username': 'Vous',
                                                        'content': _modalCommentController.text,
                                                      });
                                                      _modalCommentController.clear();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Fermer"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                  width: 500,
                  height: 300,
                ),
              ),
            ),

          ],

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionIcon(Icons.thumb_up, showLikes, () {
                setState(() {
                  showLikes = !showLikes;
                });
              }),
              _actionIcon(Icons.comment, showComments, () {
                setState(() {
                  showComments = !showComments;
                });
              }),
              _actionIcon(Icons.share, false, () {}),
              _actionIcon(
                isFavorite ? Icons.star : Icons.star_border,
                isFavorite,
                    () {
                  setState(() {
                    isFavorite = !isFavorite;
                    if (widget.onFavoriteToggle != null) {
                      widget.onFavoriteToggle!(
                        {
                          "username": widget.username,
                          "content": widget.content,
                          "imageUrl": widget.imageUrl ?? "",
                        },
                        isFavorite,
                      );
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris !',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showLikes)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "J'aime",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                ...likedUsers.map(
                      (user) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Text(user[0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(user, style: const TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          if (showComments)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Commentaires",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                ...comments.map(
                      (comment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(comment['username']![0],
                            style: const TextStyle(color: Colors.white))),
                    title: Text(comment['username']!,
                        style: const TextStyle(color: Colors.black)),
                    subtitle: Text(comment['content']!,
                        style: const TextStyle(color: Colors.black54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            _editComment(comment);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            setState(() {
                              comments.remove(comment);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: primaryColor),
                        decoration: InputDecoration(
                          hintText: "Ajouter un commentaire...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: primaryColor,
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          setState(() {
                            comments.add({
                              'username': 'Vous',
                              'content': _commentController.text,
                            });
                            _commentController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: isActive ? primaryColor : Colors.grey[700],
        size: 22,
      ),
    );
  }

  void _editComment(Map<String, String> comment) {
    final controller = TextEditingController(text: comment['content']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le commentaire"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Modifier...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                comment['content'] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }
}
