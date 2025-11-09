import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloudinary_service.dart';
import '../widgets/post_card.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class GroupPage extends StatefulWidget {
  final String groupName;
  final String categorie;
  final String niveau;
  final String classe;

  const GroupPage({
    super.key,
    required this.groupName,
    required this.categorie,
    required this.niveau,
    required this.classe,
  });

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  final TextEditingController _editPostController = TextEditingController();
  String? _editingPostId;
  String? _editingPostText;

  String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Aucun utilisateur connecté');
      return 'non_connecte';
    }
    return user.uid;
  }

  String get currentUserName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur';
  }

  Future<void> _uploadFile(XFile pickedFile, String type) async {
    try {
      setState(() => isUploading = true);
      print("🚀 Début upload vers Cloudinary...");

      final fileUrl = await CloudinaryService.uploadFile(pickedFile, type);

      if (fileUrl != null) {
        print("✅ Upload Cloudinary réussi: $fileUrl");

        await _savePostToFirestore(
          text: _postController.text,
          fileUrl: fileUrl,
          fileType: type,
          fileName: pickedFile.name,
        );

        _postController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Publication réussie avec fichier !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception("Échec de l'upload Cloudinary");
      }
    } catch (e) {
      print("❌ Erreur upload Cloudinary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'upload: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> _savePostToFirestore({
    required String text,
    required String fileUrl,
    required String fileType,
    required String fileName,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': text.isEmpty ? "Fichier partagé: $fileName" : text,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': fileName,
        'groupName': widget.groupName,
        'categorie': widget.categorie,
        'niveau': widget.niveau,
        'classe': widget.classe,
        'userName': currentUserName,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'storageProvider': 'cloudinary',
      });
      print(
        "✅ Post sauvegardé pour l'utilisateur: $currentUserName ($currentUserId)",
      );
    } catch (e) {
      print("❌ Erreur Firestore: $e");
      throw Exception("Impossible de sauvegarder le post: $e");
    }
  }

  Future<void> _editPost(String postId, String newText) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Post modifié avec succès !"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showError("Erreur lors de la modification: $e");
    }
  }

  Future<void> _deletePost(
    String postId,
    String? fileUrl,
    String? fileType,
  ) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce post ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        if (fileUrl != null && fileType == 'image') {
          final success = await CloudinaryService.deleteFileSimple(fileUrl);
          if (!success) {
            print(
              '⚠️ Impossible de supprimer le fichier de Cloudinary, continuation...',
            );
          }
        }

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Post supprimé avec succès !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        _showError("Erreur lors de la suppression: $e");
      }
    }
  }

  void _showEditDialog(String postId, String currentText) {
    _editPostController.text = currentText;
    _editingPostId = postId;
    _editingPostText = currentText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le post"),
        content: TextField(
          controller: _editPostController,
          decoration: const InputDecoration(
            hintText: "Modifier votre message...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_editPostController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _editPost(postId, _editPostController.text.trim());
              }
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(
    BuildContext context,
    String postId,
    Map<String, dynamic> postData,
  ) {
    final String postUserId = postData['userId'] ?? '';

    if (currentUserId != postUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous ne pouvez modifier que vos propres posts"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Modifier le post"),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(postId, postData['text'] ?? '');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Supprimer le post",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePost(postId, postData['fileUrl'], postData['fileType']);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadFile(pickedFile, 'image');
      }
    } catch (e) {
      _showError("Erreur lors de la sélection de l'image: $e");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _uploadFile(pickedFile, 'video');
      }
    } catch (e) {
      _showError("Erreur lors de la sélection de la vidéo: $e");
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFile(XFile(result.files.single.path!), 'pdf');
      }
    } catch (e) {
      _showError("Erreur lors de la sélection du PDF: $e");
    }
  }

  Future<void> _publishTextPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) {
      _showError("Veuillez écrire un message");
      return;
    }

    try {
      setState(() => isUploading = true);

      await FirebaseFirestore.instance.collection('posts').add({
        'text': text,
        'groupName': widget.groupName,
        'categorie': widget.categorie,
        'niveau': widget.niveau,
        'classe': widget.classe,
        'userName': currentUserName,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _postController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Message publié avec succès !"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showError("Erreur lors de la publication: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _debugUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    print('=== DEBUG UTILISATEUR ===');
    print('UID: ${user?.uid}');
    print('Email: ${user?.email}');
    print('DisplayName: ${user?.displayName}');
    print('=========================');
  }

  @override
  Widget build(BuildContext context) {
    _debugUserInfo();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: "Partagez avec le groupe...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: isUploading ? null : _pickImage,
                      icon: const Icon(Icons.photo, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: isUploading ? null : _pickVideo,
                      icon: const Icon(Icons.videocam, color: Colors.purple),
                    ),
                    IconButton(
                      onPressed: isUploading ? null : _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isUploading ? null : _publishTextPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                      ),
                      child: isUploading
                          ? const CircularProgressIndicator()
                          : const Text("Publier"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isUploading) const LinearProgressIndicator(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('groupName', isEqualTo: widget.groupName)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Aucune publication dans ce groupe",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          "Soyez le premier à partager !",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final postId = doc.id;

                    return GestureDetector(
                      onLongPress: () =>
                          _showPostOptions(context, postId, data),
                      onTap: () {
                        // 👇 Ajout pour les PDF
                        if (data['fileType'] == 'pdf' &&
                            data['fileUrl'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: Text(data['fileName'] ?? 'PDF'),
                                ),
                                body: SfPdfViewer.network(data['fileUrl']),
                              ),
                            ),
                          );
                        }
                      },
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
                          profileImageUrl: null,
                          onFavoriteToggle: (postMap, isFavorite) {},
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _editPostController.dispose();
    super.dispose();
  }
}
