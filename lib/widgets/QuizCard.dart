import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/CreateQuizPage.dart';

class QuizCard extends StatelessWidget {
  final List<dynamic> quizData;
  final String postId;
  final String username;
  final String creatorId; // ← ID du créateur
  final String quizTitle;
  final String groupName; // ← AJOUT : Pour édition
  final VoidCallback onTap;

  const QuizCard({
    super.key,
    required this.quizData,
    required this.postId,
    required this.username,
    required this.creatorId, // ← Requis
    required this.quizTitle,
    required this.groupName, // ← AJOUT
    required this.onTap,
  });

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'non_connecte';

  Future<void> _deleteQuiz(BuildContext context) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce quiz ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                  "Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Quiz supprimé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEditQuiz(BuildContext context) {
    // Ici, tu peux naviguer vers CreateQuizPage en mode édition
    // ou ouvrir un formulaire de modification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQuizPage(
          groupName: groupName, // ← AJOUT : Passe le bon groupName
          postId: postId,
          quizData: quizData,
          quizTitle: quizTitle,
        ),
      ),
    );
  }

  void _showQuizOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Modifier le quiz"),
              onTap: () {
                Navigator.pop(context);
                _showEditQuiz(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                  "Supprimer le quiz", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteQuiz(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text("Annuler")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap, // ouvrir le quiz
        onLongPress: creatorId == currentUserId
            ? () => _showQuizOptions(context) // édition/suppression
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.quiz, color: Colors.green),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quizTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Créé par $username - ${quizData.length} questions",
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (creatorId == currentUserId)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showQuizOptions(context),
                ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}