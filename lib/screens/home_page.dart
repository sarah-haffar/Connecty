import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import 'profile_page.dart';

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

  // Categories with their sub-levels used by the sidebar ExpansionTiles
  // Définition des catégories et niveaux
  // On garde une structure dynamique pour stocker les groupes
Map<String, Map<String, Map<String, List<String>>>> createdGroups = {
  // category -> level -> class -> list of groups
  "Art": {
    "Collège": {
      "7ème": [],
      "8ème": [],
      "9ème": [],
    },
    "Lycée": {
      "1ère": [],
      "2ème": [],
      "3ème": [],
      "Bac": [],
    },
  },
  "Sport": {
    "Collège": {
      "7ème": [],
      "8ème": [],
      "9ème": [],
    },
    "Lycée": {
      "1ère": [],
      "2ème": [],
      "3ème": [],
      "Bac": [],
    },
  },
  "Robotique": {
    "Collège": {
      "7ème": [],
      "8ème": [],
      "9ème": [],
    },
    "Lycée": {
      "1ère": [],
      "2ème": [],
      "3ème": [],
      "Bac": [],
    },
  },
  "Clubs": {
    "Collège": {
      "7ème": [],
      "8ème": [],
      "9ème": [],
    },
    "Lycée": {
      "1ère": [],
      "2ème": [],
      "3ème": [],
      "Bac": [],
    },
  },
};

  // Définition des niveaux et leurs classes
  final Map<String, List<String>> levels = {
    "Collège": ["7ème", "8ème", "9ème"],
    "Lycée": ["1ère", "2ème", "3ème", "Bac"],
  };
// Structure pour les événements (category -> level -> class -> list of events)
Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> createdEvents = {
  "Evenements": {
    "Collège": {
      "7ème": [],
      "8ème": [],
      "9ème": [],
    },
    "Lycée": {
      "1ère": [],
      "2ème": [],
      "3ème": [],
      "Bac": [],
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
                "assets/Connecty_logo_3.PNG",
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
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  },
),

        ],
      ),
      
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar gauche
        Container(
          width: 250,
          color: sidebarColor,
          padding: const EdgeInsets.all(8),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black87),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Contenu scrollable (Groupes + Événements)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ======= GROUPES =======
                        ListTile(
                          leading: const Icon(Icons.group, color: Colors.black54),
                          title: const Text("Groupes", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(color: Colors.deepPurple),

                        ...createdGroups.keys.map((category) => ExpansionTile(
                              leading: _getCategoryIcon(category),
                              title: Text(category, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              children: [
                                ...createdGroups[category]!.keys.map((level) => ExpansionTile(
                                      title: Text(level, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                                      children: [
                                        ...createdGroups[category]![level]!.keys.map((classe) => Column(
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.add, color: Colors.greenAccent),
                                                  title: const Text("Créer un groupe", style: TextStyle(color: Colors.black54)),
                                                  onTap: () {
                                                    _showCreateGroupDialog(context, category, level, classe);
                                                  },
                                                ),
                                                ...createdGroups[category]![level]![classe]!.map((groupName) => ListTile(
                                                      leading: const Icon(Icons.group, color: Colors.white70),
                                                      title: Text(groupName, style: const TextStyle(color: Colors.black54)),
                                                    )),
                                              ],
                                            )),
                                      ],
                                    )),
                              ],
                            )),

                        const SizedBox(height: 20),

                        // ======= EVENEMENTS =======
                        ListTile(
                          leading: const Icon(Icons.event, color: Colors.black54),
                          title: const Text("Événements", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(color: Colors.deepPurple),

                        ...createdEvents.keys.map((category) => ExpansionTile(
                              leading: const Icon(Icons.event_note, color: Colors.orangeAccent),
                              title: Text(category, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              children: [
                                ...createdEvents[category]!.keys.map((level) => ExpansionTile(
                                      title: Text(level, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                                      children: [
                                        ...createdEvents[category]![level]!.keys.map((classe) => Column(
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.add, color: Colors.orangeAccent),
                                                  title: const Text("Créer un événement", style: TextStyle(color: Colors.black54)),
                                                  onTap: () {
                                                    _showCreateEventDialog(context, category, level, classe);
                                                  },
                                                ),
                                                ...createdEvents[category]![level]![classe]!.map((event) => ListTile(
                                                      leading: const Icon(Icons.event_available, color: Colors.white70),
                                                      title: Text(event["title"], style: const TextStyle(color: Colors.black54)),
                                                      subtitle: Text("${event["date"].day}/${event["date"].month}/${event["date"].year}",
                                                          style: const TextStyle(color: Colors.black45)),
                                                    )),
                                              ],
                                            )),
                                      ],
                                    )),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),

                // Footer fixe (Paramètres + Déconnexion)
                const Divider(color: Colors.deepPurple),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.purple),
                  title: const Text("Paramètres", style: TextStyle(color: Colors.black54)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.purple),
                  title: const Text("Déconnexion", style: TextStyle(color: Colors.black54)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),

        // Contenu principal (centre)
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
                      style: const TextStyle(color: Colors.black), 
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

        // Sidebar droit (quiz & cards)
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
                  color: Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber),
                            SizedBox(width: 8),
                            Text("Astuce du jour",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.deepPurple)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                            "Utilise la technique Pomodoro : 25 minutes de travail concentré, 5 minutes de pause pour booster ta productivité !",
                            style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                Card(
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.quiz, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Mini défi",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text("Si 3 stylos coûtent 15€, combien coûtent 5 stylos ?",
                            style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // tu peux afficher un SnackBar avec la réponse
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Voir la réponse"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Fait historique",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                            "Le 21 juillet 1969, Neil Armstrong a marché sur la Lune. 🌕🚀",
                            style: TextStyle(fontSize: 14, color: Colors.white70)),
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
    ));
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

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback? onTap, {bool isHeader = false}) {
  return ListTile(
    leading: isHeader ? null : Icon(icon, color: primaryColor),
    title: Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
    onTap: onTap,
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
      return const Icon(Icons.category, color: Colors.white);
  }
}
void _showCreateGroupDialog(BuildContext context, String category, String level, String classe) {
  final TextEditingController _groupController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Créer un groupe ($category > $level > $classe)"),
      content: TextField(
        controller: _groupController,
        decoration: const InputDecoration(
          hintText: "Nom du groupe",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // fermer le modal
          },
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            String newGroup = _groupController.text.trim();
            if (newGroup.isNotEmpty) {
              // Ajouter le groupe dans la structure
              setState(() {
                createdGroups[category]![level]![classe]!.add(newGroup);
              });
              Navigator.of(context).pop(); // fermer le modal
            }
          },
          child: const Text("Créer"),
        ),
      ],
    ),
  );
}

void _showCreateEventDialog(BuildContext context, String category, String level, String classe) {
  final TextEditingController _eventTitleController = TextEditingController();
  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Créer un événement ($category > $level > $classe)"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _eventTitleController,
            decoration: const InputDecoration(hintText: "Titre de l'événement"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                selectedDate = picked;
              }
            },
            child: const Text("Choisir une date"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_eventTitleController.text.isNotEmpty && selectedDate != null) {
              setState(() {
                createdEvents[category]![level]![classe]!.add({
                  "title": _eventTitleController.text.trim(),
                  "date": selectedDate,
                });
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text("Créer"),
        ),
      ],
    ),
  );
}

}

