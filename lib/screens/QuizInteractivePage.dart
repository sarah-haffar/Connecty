import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizInteractivePage extends StatefulWidget {
  final String groupName;
  final String username;
  final String quizTitle;                   // ← AJOUT
  final List<dynamic> quizData;

  const QuizInteractivePage({
    super.key,
    required this.groupName,
    required this.username,
    required this.quizTitle,               // ← AJOUT
    required this.quizData,
  });

  @override
  State<QuizInteractivePage> createState() => _QuizInteractivePageState();
}

class _QuizInteractivePageState extends State<QuizInteractivePage> {
  int currentQuestion = 0;
  late List<List<int>> selectedAnswers;
  int score = 0;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List.generate(widget.quizData.length, (_) => []);
  }

  // Sélection réponse unique / Vrai-Faux
  void _selectAnswer(int optionIndex, String type) {
    if (answered) return;

    setState(() {
      if (type == 'unique' || type == 'truefalse') {
        selectedAnswers[currentQuestion] = [optionIndex];
        answered = true;
        _validateAnswer();
      }
    });
  }

  // Vérification réponse
  void _validateAnswer() {
    final question = widget.quizData[currentQuestion];
    final correctAnswers = question.containsKey('correctAnswers')
        ? List<int>.from(question['correctAnswers'])
        : [];

    final matches = correctAnswers.length == selectedAnswers[currentQuestion].length &&
        correctAnswers.every((ans) => selectedAnswers[currentQuestion].contains(ans));

    if (matches) {
      score++;
      HapticFeedback.lightImpact();
      _showSnack(true);
    } else {
      HapticFeedback.heavyImpact();
      _showSnack(false);
    }
  }

  void _showSnack(bool isCorrect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "✅ Correct !" : "❌ Incorrect"),
        duration: const Duration(milliseconds: 900),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
      ),
    );
  }

  void _nextQuestion() {
    if (currentQuestion < widget.quizData.length - 1) {
      setState(() {
        currentQuestion++;
        answered = false;
      });
    } else {
      _showQuizSummary();
    }
  }

  void _previousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
        answered = false;
      });
    }
  }

  Widget _buildOption(int optionIndex, String optionText, String type) {
    final isSelected = selectedAnswers[currentQuestion].contains(optionIndex);
    final question = widget.quizData[currentQuestion];
    final correctAnswers = question.containsKey('correctAnswers')
        ? List<int>.from(question['correctAnswers'])
        : [];
    Color? optionColor;

    if (answered) {
      if (correctAnswers.contains(optionIndex)) optionColor = Colors.green[300];
      if (isSelected && !correctAnswers.contains(optionIndex))
        optionColor = Colors.red[300];
    }

    if (type == 'unique' || type == 'truefalse') {
      return RadioListTile<int>(
        value: optionIndex,
        groupValue:
        selectedAnswers[currentQuestion].isNotEmpty ? selectedAnswers[currentQuestion].first : -1,
        title: Text(optionText),
        tileColor: optionColor,
        onChanged: (_) => _selectAnswer(optionIndex, type),
      );
    } else {
      return CheckboxListTile(
        value: isSelected,
        title: Text(optionText),
        tileColor: optionColor,
        onChanged: answered
            ? null
            : (val) {
          setState(() {
            if (val == true) {
              selectedAnswers[currentQuestion].add(optionIndex);
            } else {
              selectedAnswers[currentQuestion].remove(optionIndex);
            }
          });
        },
      );
    }
  }

  void _validateMultiAnswer() {
    if (answered) return;
    setState(() {
      answered = true;
      _validateAnswer();
    });
  }

  // Résumé final
  void _showQuizSummary() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Résumé du quiz : ${widget.quizTitle}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.quizData.length,
            itemBuilder: (context, index) {
              final question = widget.quizData[index];
              final correctAnswers = question.containsKey('correctAnswers')
                  ? List<int>.from(question['correctAnswers'])
                  : [];
              final userAnswers = selectedAnswers[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Q${index + 1}: ${question['question'] ?? 'Question sans texte'}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),

                        ...List.generate(question['options']?.length ?? 0, (i) {
                          final optionText = question['options'][i] ?? 'Option vide';
                          final isCorrect = correctAnswers.contains(i);
                          final isSelected = userAnswers.contains(i);

                          Color? color;
                          if (isCorrect) color = Colors.green[200];
                          if (!isCorrect && isSelected) color = Colors.red[200];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 6),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: color,
                            child: Text(
                              optionText +
                                  (isCorrect ? " ✅" : "") +
                                  (isSelected && !isCorrect ? " ❌" : ""),
                            ),
                          );
                        }),
                      ]),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer")),
          ElevatedButton(
              onPressed: _shareScore,
              child: const Text("Partager dans le groupe")),
        ],
      ),
    );
  }

  // Partage score → Firestore
  Future<void> _shareScore() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    final userName = currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'Utilisateur';

    await FirebaseFirestore.instance.collection('posts').add({
      'text':
      "📊 $userName a obtenu $score/${widget.quizData.length} au quiz : ${widget.quizTitle}",
      'groupName': widget.groupName,
      'userName': userName,
      'quizTitle': widget.quizTitle,
      'userId': currentUser?.uid ?? 'non_connecte',
      'timestamp': FieldValue.serverTimestamp(),
      'postType': 'quizScore',
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Score partagé avec succès !"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quizData[currentQuestion];
    final options = question.containsKey('options')
        ? List<String>.from(question['options'])
        : [];
    final type = question['type'] ?? 'unique';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),   // ← UTILISE LE TITRE DU QUIZ
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              "Question ${currentQuestion + 1} / ${widget.quizData.length}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(question['question'] ?? 'Question sans texte',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),

          ...List.generate(
              options.length,
                  (index) =>
                  _buildOption(index, options[index], type)),

          if (type == 'multiple' && !answered)
            ElevatedButton(
              onPressed: _validateMultiAnswer,
              child: const Text("Valider"),
            ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentQuestion > 0)
                ElevatedButton(
                    onPressed: _previousQuestion,
                    child: const Text("Précédent")),
              ElevatedButton(
                onPressed: answered ? _nextQuestion : null,
                child: currentQuestion == widget.quizData.length - 1
                    ? const Text("Terminer")
                    : const Text("Suivant"),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text("Score actuel: $score",
              style: const TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }
}