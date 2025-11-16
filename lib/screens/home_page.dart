import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import 'group_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/notification_dialog.dart';
import '../services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  String searchQuery = "";
  String selectedCategory = "";
  String? selectedAnswer;
  String feedbackMessage = "";
  int currentQuizIndex = 0;
  int _unreadNotificationsCount = 0;

  final List<String> users = ["Sarah", "Ahmed", "Feriel", "Baha"];
  final List<String> chats = ["Sarah", "Ahmed", "Feriel", "Baha"];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, Map<String, Map<String, Map<String, List<String>>>>>
  createdGroups = {
    "Groupe": {
      "Robotique": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {
          "1ère": <String>[],
          "2ème": <String>[],
          "3ème": <String>[],
          "Bac": <String>[],
        },
      },
      "Art": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {
          "1ère": <String>[],
          "2ème": <String>[],
          "3ème": <String>[],
          "Bac": <String>[],
        },
      },
      "Sport": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {
          "1ère": <String>[],
          "2ème": <String>[],
          "3ème": <String>[],
          "Bac": <String>[],
        },
      },
      "Clubs": {
        "Collège": {"7ème": <String>[], "8ème": <String>[], "9ème": <String>[]},
        "Lycée": {
          "1ère": <String>[],
          "2ème": <String>[],
          "3ème": <String>[],
          "Bac": <String>[],
        },
      },
    },
  };

  // SUPPRIMER les posts statiques fictifs
  // final List<Map<String, dynamic>> posts = [ ... ]; // ← À SUPPRIMER

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

  @override
  void initState() {
    super.initState();
    _loadGroupsFromFirestore();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    // Écouter le compteur de notifications non lues
    NotificationService.getUnreadCount().listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  // ========== NOUVELLE MÉTHODE : RÉCUPÉRER TOUS LES POSTS ==========
  Stream<QuerySnapshot> get _allPostsStream {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ========== MÉTHODE TEMPORAIRE : RÉCUPÉRER LES POSTS FILTRÉS ==========
  // Pour l'instant, on affiche tous les posts
  // Plus tard, on filtrera par amis + groupes participants
  Stream<QuerySnapshot> get _filteredPostsStream {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _loadGroupsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groupe')
          .get();

      final Map<String, Map<String, Map<String, Map<String, List<String>>>>>
      updatedGroups = Map.from(createdGroups);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categorie = data['categorie'];
        final niveau = data['niveau'];
        final classe = data['classe'];
        final nom = data['nom'];

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

  void _showSearchOverlay() {
    // Cette méthode devra être adaptée pour la recherche en temps réel
    _overlayEntry?.remove();
    // Implementation temporaire - à adapter avec la vraie recherche
  }

  @override
  Widget build(BuildContext context) {
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
                    height: isMobile ? 70 : 80,
                    width: isMobile ? 60 : 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                if (!isMobile)
                  Expanded(
                    child: TextField(
                      key: _searchFieldKey,
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
                        if (searchQuery.isNotEmpty) {
                          _showSearchOverlay();
                        } else {
                          _overlayEntry?.remove();
                          _overlayEntry = null;
                        }
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
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
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
                            ],
                          ),
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
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (_unreadNotificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            _unreadNotificationsCount > 9
                                ? '9+'
                                : '$_unreadNotificationsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: "Notifications",
                onPressed: _showNotifications,
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
                  child: _buildPostsList(), // ← MODIFICATION ICI
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

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) =>
          NotificationDialog(unreadCount: _unreadNotificationsCount),
    );
  }

  // ========== NOUVELLE MÉTHODE : CONSTRUIRE LA LISTE DES POSTS ==========
  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _filteredPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Aucune publication",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  "Les publications de vos amis et groupes apparaîtront ici",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final data = doc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PostCard(
                postId: doc.id,
                username: data['userName'] ?? 'Utilisateur',
                content: data['text'] ?? '',
                imageUrl: data['fileUrl'],
                fileType: data['fileType'],
                isInitiallyFavorite: false,
                onFavoriteToggle: (postMap, isFav) {
                  // Gérer les favoris si nécessaire
                },
              ),
            );
          },
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
                        ...createdGroups["Groupe"]![sousCategorie]![niveau]!
                            .keys
                            .map(
                              (classe) => Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      "Créer un groupe ($classe)",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    onTap: () {
                                      _showCreateGroupDialog(
                                        context,
                                        sousCategorie,
                                        niveau,
                                        classe,
                                      );
                                    },
                                  ),
                                  ...createdGroups["Groupe"]![sousCategorie]![niveau]![classe]!
                                      .map(
                                        (groupName) => ListTile(
                                          leading: const Icon(
                                            Icons.group,
                                            color: Colors.black54,
                                          ),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                    content: const Text(
                      "Voulez-vous vraiment vous déconnecter ?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
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
                    feedbackMessage = "❌ Mauvaise réponse.";
                  }
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      currentQuizIndex =
                          (currentQuizIndex + 1) % quizQuestions.length;
                      selectedAnswer = null;
                      feedbackMessage = "";
                    });
                  });
                });
              },
            );
          }).toList(),
          const SizedBox(height: 4),
          Text(
            feedbackMessage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case "Art":
        return const Icon(Icons.palette, color: Colors.black87);
      case "Sport":
        return const Icon(Icons.sports, color: Colors.black87);
      case "Robotique":
        return const Icon(Icons.smart_toy, color: Colors.black87);
      case "Clubs":
        return const Icon(Icons.groups, color: Colors.black87);
      default:
        return const Icon(Icons.group, color: Colors.black87);
    }
  }

  void _showCreateGroupDialog(
    BuildContext context,
    String categorie,
    String niveau,
    String classe,
  ) {
    final TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Créer un nouveau groupe"),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(labelText: "Nom du groupe"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                final groupName = groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  setState(() {
                    createdGroups["Groupe"]![categorie]![niveau]![classe]!.add(
                      groupName,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Créer"),
            ),
          ],
        );
      },
    );
  }

  void _showFavorites() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mes Favoris",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('favorites')
                      .orderBy('addedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final favorites = snapshot.data!.docs;

                    // DEBUG
                    print('=== DEBUG FAVORIS ===');
                    for (int i = 0; i < favorites.length; i++) {
                      final doc = favorites[i];
                      final postData = doc['postData'] as Map<String, dynamic>;
                      print('Favori $i:');
                      print('  - Document ID: ${doc.id}');
                      print('  - Post ID: ${postData['postId']}');
                      print('  - Username: ${postData['userName']}');
                    }

                    return ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final favoriteDoc = favorites[index];
                        final postData =
                            favoriteDoc['postData'] as Map<String, dynamic>;
                        final originalPostId =
                            postData['postId'] ?? favoriteDoc.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PostCard(
                            postId: originalPostId,
                            username: postData['userName'] ?? 'Utilisateur',
                            content: postData['text'] ?? '',
                            imageUrl: postData['fileUrl'],
                            fileType: postData['fileType'],
                            isInitiallyFavorite: true,
                            onFavoriteToggle: (postMap, isFav) async {
                              if (!isFav) {
                                print('=== SUPPRESSION ===');
                                print('Index: $index');
                                print('Document ID: ${favoriteDoc.id}');
                                print('Post ID: $originalPostId');
                                print('Username: ${postData['userName']}');

                                // CORRECTION : Utilisez postId comme identifiant
                                await _firestore
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .collection('favorites')
                                    .doc(originalPostId) // ← CHANGEMENT ICI
                                    .delete();
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chats"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: chats.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(chats[index]));
            },
          ),
        ),
      ),
    );
  }
}
