import 'package:flutter/material.dart';
import '../widgets/post_card.dart';

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
  final List<String> groups = ["Art", "Sport", "Clubs", "Robotique"];
  final List<String> chats = ["Sarah", "Ahmed", "Feriel", "Baha"];

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
      "content": "Super entraînement de basket aujourd’hui avec l’équipe 🏀💪",
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

  final Color primaryColor = const Color(0xFF6A1B9A); // violet foncé
  final Color sidebarColor = const Color(0xFFEDE7F6); // violet lila clair

  @override
  Widget build(BuildContext context) {
    final displayedPosts = posts.where((p) {
      final matchesCategory = selectedCategory.isEmpty || p["category"] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          p["username"]!.toLowerCase().contains(searchQuery) ||
          p["content"]!.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();


    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
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
                "assets/Connecty_logo_2.png",
                height: 150,
              ),
            ),
            const SizedBox(width: 10),
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
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
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
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: "Favoris",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      final favoritePosts = posts.where((post) => post['isFavorite'] == true).toList();

                      if (favoritePosts.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          height: 200,
                          child: const Center(child: Text("Aucun favori pour l'instant")),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        height: 400,
                        child: ListView.builder(
                          itemCount: favoritePosts.length,
                          itemBuilder: (context, index) {
                            final post = favoritePosts[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(post["username"]!),
                                subtitle: Text(post["content"]!),
                                leading: post["imageUrl"] != null
                                    ? Image.asset(
                                  post["imageUrl"]!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      post['isFavorite'] = false;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
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
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildSidebarItem(Icons.palette, "Art", () {
                  setState(() {
                    selectedCategory = "Art";
                  });
                }),
                _buildSidebarItem(Icons.sports_soccer, "Sport", () {
                  setState(() {
                    selectedCategory = "Sport";
                  });
                }),
                _buildSidebarItem(Icons.group, "Clubs", () {
                  setState(() {
                    selectedCategory = "Clubs";
                  });
                }),
                _buildSidebarItem(Icons.smart_toy, "Robotique", () {
                  setState(() {
                    selectedCategory = "Robotique";
                  });
                }),
                const Spacer(),
                _buildSidebarItem(Icons.settings, "Paramètres", () {}),
                _buildSidebarItem(Icons.logout, "Déconnexion", () {}),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListView(
                children: [
                  if (searchQuery.isNotEmpty)
                    ...users
                        .where((u) => u.toLowerCase().contains(searchQuery))
                        .map((u) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: sidebarColor,
                        child: Text(u[0], style: const TextStyle(color: Colors.black)),
                      ),
                      title: Text(
                        u,
                        style: const TextStyle(color: Colors.black), // <- ajouter ceci
                      ),

                    )),

                  if (searchQuery.isNotEmpty)
                    ...groups
                        .where((g) => g.toLowerCase().contains(searchQuery))
                        .map((g) => ListTile(
                      leading: const Icon(Icons.group, color: Colors.black54),
                      title: Text(
                        g,
                        style: const TextStyle(color: Colors.black),
                      ),)),
                  ...displayedPosts.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostCard(
                      username: post["username"]!,
                      content: post["content"]!,
                      imageUrl: post["imageUrl"],
                      onFavoriteToggle: (postMap, isFav) {
                        setState(() {
                          final indexPost = posts.indexWhere((p) =>
                          p["username"] == postMap["username"] &&
                              p["content"] == postMap["content"]);
                          if (indexPost != -1) {
                            posts[indexPost]["isFavorite"] = isFav;
                          }
                        });
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),

          Container(
            width: 280,
            color: sidebarColor,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🎓 Quiz éducatif du jour",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    quiz["question"],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...quiz["options"].map<Widget>((option) {
                    return RadioListTile<String>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      dense: true,
                      title: Text(option, style: const TextStyle(color: Colors.black)),
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
                              : Colors.red),
                    ),
                  ],
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("📘 Astuce d'étude",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          SizedBox(height: 2),
                          Text(
                              "Pour mieux mémoriser, révisez vos notes tous les soirs pendant 10 minutes.",
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("💡 Le savais-tu ?",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          SizedBox(height: 2),
                          Text(
                              "Le cerveau humain contient environ 86 milliards de neurones.",
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("🧠 Mini défi",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          SizedBox(height: 2),
                          Text(
                              "Résous cette énigme : Si 3 stylos coûtent 15€, combien coûtent 5 stylos ?",
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("📚 Fait historique",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          SizedBox(height: 2),
                          Text("Le 21 juillet 1969, Neil Armstrong a marché sur la Lune.",
                              style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Container(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Chats",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatUser = chats[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sidebarColor,
                      child: Text(chatUser[0],
                          style: const TextStyle(color: Colors.black)),
                    ),
                    title: Text(chatUser),
                    subtitle: const Text("Dernier message..."),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
