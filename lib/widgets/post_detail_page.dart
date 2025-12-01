import 'package:flutter/material.dart';

class PostDetailPage extends StatefulWidget {
  final String username;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;

  const PostDetailPage({
    super.key,
    required this.username,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final Color primaryColor = const Color(0xFF6A1B9A); // violet foncé
  final Color backgroundColor = const Color(0xFFEDE7F6); // violet lila clair

  final TextEditingController _commentController = TextEditingController();
  List<Map<String, String>> comments = [
    {"username": "Ahmed", "text": "Super post !"},
    {"username": "Feriel", "text": "J'adore 👍"},
  ];

  List<String> likedUsers = ["Sarah", "Ahmed", "Feriel"];
  bool showLikes = false;
  int? editingIndex;

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
                  if (widget.profileImageUrl != null)
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(widget.profileImageUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor,
                      child: Text(
                        widget.username[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
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
                    width: 700,
                    height: 500,
                    fit: BoxFit.cover,
                  ),
                ),
              if (widget.imageUrl != null) const SizedBox(height: 12),
              Text(
                widget.content,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 20),
              // Boutons Like / Comment / Share
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showLikes = !showLikes;
                      });
                    },
                    icon: Icon(Icons.thumb_up, color: Colors.white),
                    label: Text("Like (${likedUsers.length})"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                  ),
                  _customButton(
                    primaryColor,
                    Icons.comment,
                    "Commenter",
                    () {},
                  ),
                  _customButton(primaryColor, Icons.share, "Partager", () {}),
                ],
              ),
              const SizedBox(height: 10),
              // Liste des likes (affiché si showLikes = true)
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
                          child: Text(
                            user[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
              // Liste des commentaires
              ...comments.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> comment = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(
                      comment["username"]![0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    comment["username"]!,
                    style: const TextStyle(color: Colors.black),
                  ),
                  subtitle: Text(
                    comment["text"]!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        setState(() {
                          comments.removeAt(index);
                        });
                      } else if (value == 'edit') {
                        _commentController.text = comment["text"]!;
                        editingIndex = index;
                      }
                    },
                  ),
                );
              }),
              // Champ pour ajouter/modifier un commentaire
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: "Ajouter un commentaire...",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        setState(() {
                          if (editingIndex != null) {
                            comments[editingIndex!]["text"] =
                                _commentController.text;
                            editingIndex = null;
                          } else {
                            comments.add({
                              "username": widget.username,
                              "text": _commentController.text,
                            });
                          }
                          _commentController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customButton(
    Color color,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
