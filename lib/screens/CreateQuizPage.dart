import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateQuizPage extends StatefulWidget {
  final String groupName;
  final String? postId; // ← facultatif, pour l’édition
  final List<dynamic>? quizData; // ← facultatif, quiz existant
  final String? quizTitle; // ← facultatif

  const CreateQuizPage({
    super.key,
    required this.groupName,
    this.postId,
    this.quizData,
    this.quizTitle,
  });

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    // ← AJOUT : Charge les données existantes en mode édition
    if (widget.quizTitle != null) {
      _titleController.text = widget.quizTitle!;
    }
    if (widget.quizData != null) {
      questions = widget.quizData!.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  void _addQuestion() {
    if (questions.length >= 6) return;
    setState(() {
      questions.add({
        'question': '',
        'type': 'unique', // 'unique', 'multiple', 'truefalse'
        'options': ['Option 1', 'Option 2'],
        'correctAnswers': [],
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  void _updateQuestion(int index, Map<String, dynamic> data) {
    setState(() {
      questions[index] = data;
    });
  }

  Future<void> _publishQuiz() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoutez un titre au quiz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoutez au moins une question"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final quizMap = {
        'quizTitle': _titleController.text.trim(),
        'groupName': widget.groupName,
        'userName': user?.displayName ?? 'Utilisateur',
        'userId': user?.uid ?? 'non_connecte',
        'timestamp': FieldValue.serverTimestamp(),
        'postType': 'quiz',
        'quizData': questions,
      };

      if (widget.postId != null) {
        // 🔹 Édition d’un quiz existant
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(quizMap);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Quiz mis à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 🔹 Création d’un nouveau quiz
        await FirebaseFirestore.instance.collection('posts').add(quizMap);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Quiz publié avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);

    } catch (e) {
      print("Erreur publication quiz: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur publication: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un quiz")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Titre du quiz",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return QuestionCard(
                  questionIndex: index,
                  questionData: questions[index],
                  onChanged: (data) => _updateQuestion(index, data),
                  onRemove: () => _removeQuestion(index),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _addQuestion,
                child: const Text("Ajouter une question"),
              ),
              ElevatedButton(
                onPressed: _publishQuiz,
                child: const Text("Publier le quiz"),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class QuestionCard extends StatefulWidget {
  final int questionIndex;
  final Map<String, dynamic> questionData;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback onRemove;

  const QuestionCard({
    super.key,
    required this.questionIndex,
    required this.questionData,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  String type = 'unique';
  List<int> correctAnswers = [];

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.questionData['question']);
    type = widget.questionData['type'];
    correctAnswers = List<int>.from(widget.questionData['correctAnswers']);
    _optionControllers = (widget.questionData['options'] as List<String>)
        .map((e) => TextEditingController(text: e))
        .toList();
  }

  void _updateParent() {
    final data = {
      'question': _questionController.text,
      'type': type,
      'options': _optionControllers.map((e) => e.text).toList(),
      'correctAnswers': correctAnswers,
    };
    widget.onChanged(data);
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() {
      _optionControllers.add(TextEditingController(text: 'Nouvelle option'));
    });
    _updateParent();
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index);
      correctAnswers.remove(index);
    });
    _updateParent();
  }

  Widget _buildOption(int index) {
    return Row(
      children: [
        if (type == 'unique' || type == 'truefalse')
          Radio<int>(
            value: index,
            groupValue: correctAnswers.isNotEmpty ? correctAnswers.first : -1,
            onChanged: (val) {
              setState(() {
                correctAnswers = [val!];
              });
              _updateParent();
            },
          )
        else if (type == 'multiple')
          Checkbox(
            value: correctAnswers.contains(index),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  correctAnswers.add(index);
                } else {
                  correctAnswers.remove(index);
                }
              });
              _updateParent();
            },
          ),
        Expanded(
          child: TextField(
            controller: _optionControllers[index],
            onChanged: (_) => _updateParent(),
            decoration: InputDecoration(labelText: "Option ${index + 1}"),
            readOnly: type == 'truefalse',
          ),
        ),
        if (type != 'truefalse')
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeOption(index),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    onChanged: (_) => _updateParent(),
                    decoration: InputDecoration(
                      labelText: "Question ${widget.questionIndex + 1}",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                )
              ],
            ),
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(
                  value: 'unique',
                  child: Text("Réponse unique"),
                ),
                DropdownMenuItem(
                  value: 'multiple',
                  child: Text("Réponse multiple"),
                ),
                DropdownMenuItem(
                  value: 'truefalse',
                  child: Text("Vrai / Faux"),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  type = val!;
                  if (type == 'truefalse') {
                    _optionControllers = [
                      TextEditingController(text: 'Vrai'),
                      TextEditingController(text: 'Faux'),
                    ];
                    correctAnswers = [];
                  } else if (type == 'unique' || type == 'multiple') {
                    if (_optionControllers.length < 2) {
                      _optionControllers.add(TextEditingController(text: 'Option 2'));
                    }
                  }
                });
                _updateParent();
              },
            ),
            Column(
              children: List.generate(_optionControllers.length, _buildOption),
            ),
            if (type != 'truefalse')
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter une option"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }
}