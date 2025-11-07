import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import 'group_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "";
  String? selectedAnswer;
  String feedbackMessage = "";
  int currentQuizIndex = 0;

  final List<String> users = ["Sarah", "Ahmed", "Feriel", "Baha"];
  final List<String> chats = ["Sarah", "Ahmed", "Feriel", "Baha"];

  // STRUCTURE CORRIGÉE - "Groupe" comme catégorie principale
  Map<String, Map<String, Map<String, Map<String, List<String>>>>> createdGroups = {
    "Groupe": {  // ← "Groupe" comme grande catégorie
      "Robotique": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
      },
      "Art": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
      },
      "Sport": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
      },
      "Clubs": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
      },
    },
  };

  final List<Map<String, dynamic>> posts = [
    {
      "username": "Sarah",
      "content": "On prépare une chorégraphie pour le spectacle de danse 💃🎶",
      "category": "Clubs",
      "imageUrl": "assets/post/dance.jpg",
      "isFavorite": false,
    },
    {
      "username": "Ahmed",
      "content": "Super entraînement de basket aujourd'hui avec l'équipe 🏀💪",
      "category": "Sport",
      "imageUrl": "assets/post/basket.jpg",
      "isFavorite": false,
    },
    {
      "username": "Feriel",
      "content": "Mini robot pour le concours de robotique 🤖✨",
      "category": "Robotique",
      "imageUrl": "assets/post/robo.jpg",
      "isFavorite": false,
    },
    {
      "username": "Baha",
      "content": "Notre club de lecture a choisi 'Le Petit Prince' 📚🌟",
      "category": "Clubs",
      "imageUrl": "assets/post/livre.jpg",
      "isFavorite": false,
    },
    {
      "username": "Nora",
      "content": "Nouveau tutoriel de peinture digitale 🎨🖌️",
      "category": "Art",
      "imageUrl": "assets/post/art.jpg",
      "isFavorite": false,
    },
  ];

  final List<Map<String, dynamic>> quizQuestions = [
    {
      "question": "Quelle est la capitale de la France ?",
      "options": ["Paris", "Londres", "Madrid", "Berlin"],
      "answer": "Paris",
    },
    {
      "question": "Quelle planète est connue comme la planète rouge ?",
      "options": ["Mars", "Vénus", "Jupiter", "Saturne"],
      "answer": "Mars",
    },
    {
      "question": "Combien de continents y a-t-il sur Terre ?",
      "options": ["5", "6", "7", "8"],
      "answer": "7",
    },
  ];

  Map<String, dynamic> get quiz => quizQuestions[currentQuizIndex];

  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color sidebarColor = const Color(0xFFF0F0F0);

  Future<void> _loadGroupsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('groupe').get();

      // Structure vide de départ avec "Groupe" comme catégorie principale
      final Map<String, Map<String, Map<String, Map<String, List<String>>>>> updatedGroups = {
        "Groupe": {
          "Robotique": {
            "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
            "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
          },
          "Art": {
            "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
            "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
          },
          "Sport": {
            "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
            "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
          },
          "Clubs": {
            "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
            "Lycée": {"1ère": <String>[], "2ème": <String>[], "3ème": <String>[], "Bac": <String>[]},
          },
        },
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categorie = data['categorie'];
        final niveau = data['niveau'];
        final classe = data['classe'];
        final nom = data['nom'];

        // Vérifier que la structure existe avant d'ajouter
        if (updatedGroups["Groupe"]?[categorie] != null &&
            updatedGroups["Groupe"]![categorie]![niveau] != null &&
            updatedGroups["Groupe"]![categorie]![niveau]![classe] != null) {
          updatedGroups["Groupe"]![categorie]![niveau]![classe]!.add(nom);
        }
      }

      setState(() {
        createdGroups = updatedGroups;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des groupes : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGroupsFromFirestore(); // 🔥 charge les groupes dès le démarrage
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = posts.where((p) {
      final matchesCategory =
          selectedCategory.isEmpty || p["category"] == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          p["username"]!.toLowerCase().contains(searchQuery) ||
          p["content"]!.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final isTablet =
            constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  child: Image.asset(
                    "assets/Connecty_logo_3.PNG",
                    height: isMobile ? 45 : 80,
                    width: isMobile ? 45 : 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                if (!isMobile)
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Rechercher...",
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
              ],
            ),
            actions: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Recherche"),
                        content: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Rechercher...",
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.star),
                tooltip: "Favoris",
                onPressed: _showFavorites,
              ),
              IconButton(
                icon: const Icon(Icons.message),
                tooltip: "Messages",
                onPressed: _showChats,
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: "Notifications",
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: "Profil",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: isMobile
              ? Drawer(child: SingleChildScrollView(child: _buildSidebar()))
              : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile)
                Container(
                  width: isTablet ? 200 : 250,
                  color: sidebarColor,
                  child: _buildSidebar(),
                ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListView(
                    children: [
                      if (searchQuery.isNotEmpty)
                        ...users
                            .where((u) => u.toLowerCase().contains(searchQuery))
                            .map(
                              (u) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: sidebarColor,
                                  child: Text(
                                    u[0],
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                title: Text(
                                  u,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                      ...displayedPosts.map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: PostCard(
                            username: post["username"]!,
                            content: post["content"]!,
                            imageUrl: post["imageUrl"],
                            onFavoriteToggle: (postMap, isFav) {
                              setState(() {
                                final indexPost = posts.indexWhere(
                                  (p) =>
                                      p["username"] == postMap["username"] &&
                                      p["content"] == postMap["content"],
                                );
                                if (indexPost != -1) {
                                  posts[indexPost]["isFavorite"] = isFav;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMobile)
                Container(
                  width: isTablet ? 220 : 280,
                  color: sidebarColor,
                  padding: const EdgeInsets.all(12),
                  child: _buildRightSidebar(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.black87),
              title: const Text(
                "Groupes",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.black26),
            
            // Navigation dans "Groupe" → Sous-catégorie → Niveau → Classe
            ...createdGroups["Groupe"]!.keys.map(
              (sousCategorie) => ExpansionTile(
                leading: _getCategoryIcon(sousCategorie),
                title: Text(
                  sousCategorie,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  ...createdGroups["Groupe"]![sousCategorie]!.keys.map(
                    (niveau) => ExpansionTile(
                      title: Text(
                        niveau,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        ...createdGroups["Groupe"]![sousCategorie]![niveau]!.keys.map(
                          (classe) => Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.add, color: Colors.green),
                                title: Text(
                                  "Créer un groupe ($classe)",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                onTap: () {
                                  _showCreateGroupDialog(context, sousCategorie, niveau, classe);
                                },
                              ),
                              ...createdGroups["Groupe"]![sousCategorie]![niveau]![classe]!.map(
                                (groupName) => ListTile(
                                  leading: const Icon(Icons.group, color: Colors.black54),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        groupName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Classe: $classe",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GroupPage(
                                          groupName: groupName,
                                          categorie: sousCategorie,
                                          niveau: niveau,
                                          classe: classe,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.black26),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black87),
              title: const Text(
                "Paramètres",
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black87),
              title: const Text(
                "Déconnexion",
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirmation"),
                    content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text("Se déconnecter"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎓 Quiz éducatif du jour",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quiz["question"],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          ...quiz["options"].map<Widget>((option) {
            return RadioListTile<String>(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              title: Text(
                option,
                style: const TextStyle(color: Colors.black87),
              ),
              value: option,
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value;
                  if (value == quiz["answer"]) {
                    feedbackMessage = "✅ Bonne réponse !";
                  } else {
                    feedbackMessage =
                        "❌ Mauvaise réponse. La bonne réponse est : ${quiz["answer"]}";
                  }
                });
              },
            );
          }).toList(),
          if (feedbackMessage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              feedbackMessage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: feedbackMessage.startsWith("✅")
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentQuizIndex =
                    (currentQuizIndex + 1) % quizQuestions.length;
                selectedAnswer = null;
                feedbackMessage = "";
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text("Question suivante"),
          ),
        ],
      ),
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 400,
        child: const Center(child: Text("Aucun favori pour l'instant")),
      ),
    );
  }

  void _showChats() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 400,
        child: const Center(child: Text("Chats à venir...")),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case "Art":
        return const Icon(Icons.palette, color: Colors.purpleAccent);
      case "Sport":
        return const Icon(Icons.sports_soccer, color: Colors.orangeAccent);
      case "Robotique":
        return const Icon(Icons.smart_toy, color: Colors.blueAccent);
      case "Clubs":
        return const Icon(Icons.menu_book, color: Colors.tealAccent);
      default:
        return const Icon(Icons.category, color: Colors.black87);
    }
  }

  void _showCreateGroupDialog(
    BuildContext context,
    String sousCategorie,
    String niveau,
    String classe,
  ) {
    final TextEditingController _groupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Créer un groupe ($sousCategorie > $niveau > $classe)"),
        content: TextField(
          controller: _groupController,
          decoration: const InputDecoration(hintText: "Nom du groupe"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newGroup = _groupController.text.trim();
              if (newGroup.isNotEmpty) {
                try {
                  // Enregistrement dans Firestore
                  await FirebaseFirestore.instance.collection('groupe').add({
                    'nom': newGroup,
                    'categorie': sousCategorie,
                    'niveau': niveau,
                    'classe': classe,
                    'date_creation': Timestamp.now(),
                  });

                  // Ajout local pour affichage immédiat
                  setState(() {
                    createdGroups["Groupe"]![sousCategorie]![niveau]![classe]!.add(newGroup);
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Groupe ajouté avec succès ✅'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }
}