import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color sidebarColor = const Color(0xFFEDE7F6);

  String _username = "Feriel Tira";
  String _pseudo = "@feriel";
  String _bio = "Étudiante en informatique 🌟";
  int _friendsCount = 56;
  int _postsCount = 10;
  int _favoritesCount = 5;

  // 0: Publications, 1: À propos, 2: Amis
  int _selectedSection = 0;

  // Informations supplémentaires
  final Map<String, String> _aboutInfo = {
    "Âge": "21 ans",
    "École": "ISETKL",
    "Lieu": "Kelibia, Tunisie",
    "Centres d'intérêt": "Programmation, Design, Lecture",
  };

  // Amis (exemple)
  final List<String> _friends = ["Baha", "Sarah", "Ahmed", "Nora", "Youssef"];

  // Publications de l'utilisateur
  final List<Map<String, dynamic>> _userPosts = [
    {
      "username": "Feriel Tira",
      "content": "Première publication sur mon profil Flutter",
      "category": "Général",
      "imageUrl": null,
      "isFavorite": false,
    },
    {
      "username": "Feriel Tira",
      "content": "Nouveau projet en cours de développement 🚀",
      "category": "Programmation",
      "imageUrl": "assets/post/robo.jpg",
      "isFavorite": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sidebarColor,
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
              child: Image.asset("assets/Connecty_logo_3.PNG", height: 150),
            ),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: "Notifications",
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section en-tête du profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Photo de profil
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: const AssetImage(
                          "assets/post/art.jpg",
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Nom et pseudo
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _pseudo,
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bio
                  Text(
                    _bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 20),

                  // Bouton d'action - Modifier profil seulement
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text(
                        "Modifier profil",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section statistiques
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Amis", _friendsCount),
                  _buildStatItem("Publications", _postsCount),
                  _buildStatItem("Favoris", _favoritesCount),
                ],
              ),
            ),

            // Section navigation (Publications/À propos/Amis)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildNavItem("Publications", Icons.grid_on, 0),
                  _buildNavItem("À propos", Icons.info_outline, 1),
                  _buildNavItem("Amis", Icons.people, 2),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contenu dynamique
            if (_selectedSection == 0) ..._buildPostsSection(),
            if (_selectedSection == 1) ..._buildAboutSection(),
            if (_selectedSection == 2) ..._buildFriendsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(String title, IconData icon, int sectionIndex) {
    bool isActive = _selectedSection == sectionIndex;
    return Expanded(
      child: Material(
        color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedSection = sectionIndex;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? primaryColor : Colors.black54,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? primaryColor : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPostsSection() {
    return [
      ..._userPosts
          .map(
            (post) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PostCard(
                username: post["username"]!,
                content: post["content"]!,
                imageUrl: post["imageUrl"],
                onFavoriteToggle: (postMap, isFav) {
                  setState(() {
                    final indexPost = _userPosts.indexWhere(
                      (p) =>
                          p["username"] == postMap["username"] &&
                          p["content"] == postMap["content"],
                    );
                    if (indexPost != -1) {
                      _userPosts[indexPost]["isFavorite"] = isFav;
                      if (isFav) {
                        _favoritesCount++;
                      } else {
                        _favoritesCount--;
                      }
                    }
                  });
                },
              ),
            ),
          )
          .toList(),

      if (_userPosts.isEmpty)
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Aucune publication",
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildAboutSection() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informations personnelles",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ..._aboutInfo.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "${entry.key} :",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFriendsSection() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Amis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _friends
                  .map(
                    (friend) => Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Text(
                            friend[0],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          friend,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ];
  }

  void _editProfile() {
    // Créer des contrôleurs temporaires avec les valeurs actuelles
    final usernameController = TextEditingController(text: _username);
    final pseudoController = TextEditingController(text: _pseudo);
    final bioController = TextEditingController(text: _bio);
    final ageController = TextEditingController(text: _aboutInfo["Âge"]);
    final schoolController = TextEditingController(text: _aboutInfo["École"]);
    final locationController = TextEditingController(text: _aboutInfo["Lieu"]);
    final interestsController = TextEditingController(
      text: _aboutInfo["Centres d'intérêt"],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Modifier le profil",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo de profil modifiable
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    backgroundImage: const AssetImage("assets/post/art.jpg"),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Formulaire de modification
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Nom complet",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: pseudoController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Pseudo",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.alternate_email, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: bioController,
                style: const TextStyle(color: Colors.black),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Bio",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // Informations personnelles
              Text(
                "Informations personnelles",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: ageController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Âge",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.cake, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: schoolController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "École",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.school, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Lieu",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: interestsController,
                style: const TextStyle(color: Colors.black),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Centres d'intérêt",
                  labelStyle: TextStyle(color: primaryColor),
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.interests, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Bouton Annuler
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Annuler"),
          ),

          // Bouton Sauvegarder
          ElevatedButton(
            onPressed: () {
              // Appliquer les modifications localement
              setState(() {
                _username = usernameController.text;
                _pseudo = pseudoController.text;
                _bio = bioController.text;
                _aboutInfo["Âge"] = ageController.text;
                _aboutInfo["École"] = schoolController.text;
                _aboutInfo["Lieu"] = locationController.text;
                _aboutInfo["Centres d'intérêt"] = interestsController.text;
              });

              Navigator.pop(context);

              // Message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text("Profil modifié avec succès !"),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Sauvegarder"),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
