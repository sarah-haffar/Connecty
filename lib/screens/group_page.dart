import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../widgets/post_card.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'CreateQuizPage.dart';
import 'QuizInteractivePage.dart';
import '../widgets/QuizCard.dart';

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

  String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'non_connecte';
    return user.uid;
  }

  String get currentUserName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur';
  }

  Future<void> _uploadFile(XFile pickedFile, String type) async {
    try {
      setState(() => isUploading = true);
      final fileUrl = await CloudinaryService.uploadFile(pickedFile, type);

      if (fileUrl != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'upload: ${e.toString()}"),
          backgroundColor: Colors.red,
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
  }

  Future<void> _editPost(String postId, String newText) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Post modifié avec succès !"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deletePost(String postId, String? fileUrl, String? fileType) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce post ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete == true) {
      if (fileUrl != null && fileType == 'image') {
        await CloudinaryService.deleteFileSimple(fileUrl);
      }
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Post supprimé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEditDialog(String postId, String currentText) {
    _editPostController.text = currentText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le post"),
        content: TextField(
          controller: _editPostController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (_editPostController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _editPost(postId, _editPostController.text.trim());
              }
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, String postId, Map<String, dynamic> postData) {
    if (currentUserId != postData['userId']) {
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
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Modifier le post"),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(postId, postData['text']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Supprimer le post", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePost(postId, postData['fileUrl'], postData['fileType']);
              },
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) await _uploadFile(pickedFile, 'image');
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) await _uploadFile(pickedFile, 'video');
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      await _uploadFile(XFile(result.files.single.path!), 'pdf');
    }
  }

  Future<void> _publishTextPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
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
    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      backgroundColor: const Color(0xFFF4F4F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: "Partagez avec le groupe...", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(onPressed: isUploading ? null : _pickImage, icon: const Icon(Icons.photo, color: Colors.blue)),
                    IconButton(onPressed: isUploading ? null : _pickVideo, icon: const Icon(Icons.videocam, color: Colors.purple)),
                    IconButton(onPressed: isUploading ? null : _pickPdf, icon: const Icon(Icons.picture_as_pdf, color: Colors.red)),
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizPage(groupName: widget.groupName)));
                      },
                      icon: const Icon(Icons.quiz, color: Colors.green),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isUploading ? null : _publishTextPost,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                      child: isUploading ? const CircularProgressIndicator() : const Text("Publier"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').where('groupName', isEqualTo: widget.groupName).orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucune publication"));

                final posts = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Si c'est un quiz
                    if (data['postType'] == 'quiz' && data['quizData'] != null) {
                      final quizDataList = (data['quizData'] as List<dynamic>)
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList();

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['userId'])  // ← CORRECTION : userId au lieu de creatorId
                            .get(),
                        builder: (context, userSnapshot) {
                          String quizUsername = 'Utilisateur';
                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            quizUsername = userData['name'] ?? data['userName'] ?? 'Utilisateur';  // ← CORRECTION : userName au lieu de creatorName
                          } else if (data['userName'] != null && (data['userName'] as String).isNotEmpty) {  // ← CORRECTION : userName au lieu de creatorName
                            quizUsername = data['userName'];
                          }

                          return QuizCard(
                            quizTitle: data['quizTitle'] ?? 'Quiz sans titre',
                            quizData: quizDataList,
                            postId: doc.id,
                            username: quizUsername,
                            creatorId: data['userId'] ?? '',  // ← CORRECTION : Passe le bon creatorId
                            groupName: widget.groupName,  // ← AJOUT : Passe groupName pour édition
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizInteractivePage(
                                    groupName: widget.groupName,
                                    username: quizUsername,
                                    quizTitle: data['quizTitle'] ?? 'Quiz sans titre',
                                    quizData: quizDataList,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }

                    // Sinon post classique
                    return GestureDetector(
                      onLongPress: () => _showPostOptions(context, doc.id, data),
                      onTap: () {
                        if (data['fileType'] == 'pdf' && data['fileUrl'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: Text(data['fileName'] ?? 'PDF')),
                                body: SfPdfViewer.network(data['fileUrl']),
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: PostCard(
                          postId: doc.id,
                          username: data['userName'] ?? 'Utilisateur',
                          content: data['text'] ?? '',
                          imageUrl: data['fileUrl'],
                          fileType: data['fileType'],
                          profileImageUrl: null,
                          timestamp: data['timestamp'] as Timestamp?,
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