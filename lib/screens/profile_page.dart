import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/post_card.dart';
import 'home_page.dart';
import '../services/cloudinary_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color sidebarColor = const Color(0xFFEDE7F6);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? get currentUser => _auth.currentUser;

  // Données utilisateur
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];
  List<String> _userFriends = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  // Contrôleurs pour l'édition
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  int _selectedSection = 0;

  // Stream pour les posts en temps réel
  Stream<QuerySnapshot> get _userPostsStream {
    if (currentUser == null) {
      return const Stream<QuerySnapshot>.empty();
    }
    
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserFriends();
    
  }

  Future<void> _loadUserData() async {
    try {
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
          _initializeControllers();
        });
      } else {
        // Créer le profil utilisateur avec champs vides
        await _createUserProfile();
      }
    } catch (e) {
      print("❌ Erreur chargement données utilisateur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserProfile() async {
    try {
      final newUserData = {
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        'name':
            currentUser!.displayName ?? currentUser!.email!.split('@').first,
        'pseudo': '@${currentUser!.email!.split('@').first}',
        // CHAMPS VIDES INITIALEMENT
        'bio': '',
        'profileImage': null,
        'age': '',
        'school': '',
        'location': '',
        'interests': '',
        'friendsCount': 0,
        'postsCount': 0,
        'favoritesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(newUserData);

      setState(() {
        _userData = newUserData;
        _initializeControllers();
      });

      print("✅ Profil utilisateur créé avec champs vides");
    } catch (e) {
      print("❌ Erreur création profil: $e");
    }
  }

  void _initializeControllers() {
    _bioController.text = _userData['bio'] ?? '';
    _ageController.text = _userData['age'] ?? '';
    _schoolController.text = _userData['school'] ?? '';
    _locationController.text = _userData['location'] ?? '';
    _interestsController.text = _userData['interests'] ?? '';
  }

  Future<void> _loadUserFriends() async {
    try {
      if (currentUser == null) return;

      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .get();

      setState(() {
        _userFriends = friendsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("❌ Erreur chargement amis: $e");
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isSaving = true);

      final updatedData = {
        'bio': _bioController.text.trim(),
        'age': _ageController.text.trim(),
        'school': _schoolController.text.trim(),
        'location': _locationController.text.trim(),
        'interests': _interestsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updatedData);

      // Mettre à jour les données locales
      setState(() {
        _userData.addAll(updatedData);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profil mis à jour avec succès !'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isSaving = true);

        // Upload vers Cloudinary
        final imageUrl = await CloudinaryService.uploadFile(
          pickedFile,
          'profile_image',
        );

        if (imageUrl != null) {
          await _firestore.collection('users').doc(currentUser!.uid).update({
            'profileImage': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _userData['profileImage'] = imageUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur mise à jour photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Getters pour les données utilisateur avec valeurs par défaut si vides
  String get _username =>
      _userData['name'] ??
      _userData['username'] ??
      currentUser?.displayName ??
      currentUser?.email?.split('@').first ??
      'Utilisateur';
  String get _pseudo =>
      _userData['pseudo'] ??
      '@${currentUser?.email?.split('@').first}' ??
      '@utilisateur';
  String get _bio => _userData['bio']?.isNotEmpty == true
      ? _userData['bio']
      : 'Bienvenue sur mon profil ! 👋\nCliquez sur "Modifier profil" pour personnaliser.';

  int get _friendsCount => _userFriends.length;
  int get _postsCount => _userPosts.length;
  int get _favoritesCount => _userData['favoritesCount'] ?? 0;

  Map<String, String> get _aboutInfo {
    return {
      "Âge": _userData['age']?.isNotEmpty == true
          ? _userData['age']
          : 'Non renseigné',
      "École": _userData['school']?.isNotEmpty == true
          ? _userData['school']
          : 'Non renseigné',
      "Lieu": _userData['location']?.isNotEmpty == true
          ? _userData['location']
          : 'Non renseigné',
      "Centres d'intérêt": _userData['interests']?.isNotEmpty == true
          ? _userData['interests']
          : 'Non renseigné',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: sidebarColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Chargement du profil...',
                style: TextStyle(color: primaryColor, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

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
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
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
                      backgroundImage: _userData['profileImage'] != null
                          ? NetworkImage(_userData['profileImage']!)
                                as ImageProvider
                          : const AssetImage("assets/post/art.jpg"),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _updateProfileImage,
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

                const SizedBox(height: 12),

                // Bio
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _userData['bio']?.isEmpty == true
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _userData['bio']?.isEmpty == true
                          ? Colors.orange
                          : Colors.black87,
                      fontStyle: _userData['bio']?.isEmpty == true
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BOUTONS D'ACTION - Modifier profil + Nouveau post
                Row(
                  children: [
                    // BOUTON MODIFIER PROFIL
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _editProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 20),
                        label: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Modifier profil",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 12), // Espacement entre les boutons
                    
                    // BOUTON NOUVEAU POST
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _showCreatePostModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Nouveau post",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
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
                StreamBuilder<QuerySnapshot>(
                  stream: _userPostsStream,
                  builder: (context, snapshot) {
                    final postsCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatItem("Publications", postsCount);
                  },
                ),
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

          // Contenu dynamique basé sur la sélection
          _buildSelectedSection(),
        ],
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 0:
        return _buildPostsSection();
      case 1:
        return _buildAboutSection();
      case 2:
        return _buildFriendsSection();
      default:
        return _buildPostsSection();
    }
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

  Widget _buildPostsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
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
                const SizedBox(height: 8),
                Text(
                  "Partagez votre première publication !",
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return Column(
          children: [
            // Indicateur du nombre de posts
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${posts.length} publication${posts.length > 1 ? 's' : ''}",
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Liste des posts
            ...posts.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PostCard(
                  username: data['userName'] ?? _userData['name'] ?? 'Utilisateur',
                  content: data['text'] ?? '',
                  imageUrl: data['fileUrl'],
                  fileType: data['fileType'],
                  onFavoriteToggle: (postMap, isFav) {
                    // Logique des favoris si nécessaire
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Container(
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

          // Indicateur si profil incomplet
          if (_aboutInfo.values.every((value) => value == 'Non renseigné'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complétez votre profil pour personnaliser cette section',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          ..._aboutInfo.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      "${entry.key} :",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: entry.value == 'Non renseigné'
                            ? Colors.orange
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.value == 'Non renseigné'
                            ? Colors.orange
                            : Colors.black54,
                        fontStyle: entry.value == 'Non renseigné'
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Container(
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
          _userFriends.isNotEmpty
              ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _userFriends
                      .map(
                        (friend) => Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Text(
                                friend.isNotEmpty
                                    ? friend[0].toUpperCase()
                                    : '?',
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
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 50,
                        color: primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Aucun ami pour le moment",
                        style: TextStyle(color: primaryColor.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  void _editProfile() {
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
                    backgroundImage: _userData['profileImage'] != null
                        ? NetworkImage(_userData['profileImage']!)
                              as ImageProvider
                        : const AssetImage("assets/post/art.jpg"),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _updateProfileImage,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Indication champs optionnels
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tous les champs sont optionnels',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Formulaire de modification
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: "Bio",
                  labelStyle: TextStyle(color: primaryColor),
                  hintText: "Décrivez-vous en quelques mots...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: "Âge",
                  labelStyle: TextStyle(color: primaryColor),
                  hintText: "ex: 21 ans",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.cake, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _schoolController,
                decoration: InputDecoration(
                  labelText: "École",
                  labelStyle: TextStyle(color: primaryColor),
                  hintText: "ex: ISET Kelibia",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.school, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Lieu",
                  labelStyle: TextStyle(color: primaryColor),
                  hintText: "ex: Kelibia, Tunisie",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _interestsController,
                decoration: InputDecoration(
                  labelText: "Centres d'intérêt",
                  labelStyle: TextStyle(color: primaryColor),
                  hintText: "ex: Programmation, Design, Lecture",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.interests, color: primaryColor),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
            ),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    Navigator.pop(context);
                    await _updateProfile();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  // ========== MÉTHODES POUR LES POSTS DE PROFIL ==========

  void _showCreatePostModal() {
    final TextEditingController _postTextController = TextEditingController();
    String _selectedCategory = 'Général';
    final List<String> _categories = [
      'Général', 'Programmation', 'Design', 'Études', 
      'Loisirs', 'Voyages', 'Art', 'Musique', 'Sport', 'Autre'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.post_add, color: primaryColor),
                const SizedBox(width: 8),
                const Text("Créer une publication"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _postTextController,
                    decoration: const InputDecoration(
                      hintText: "Partagez quelque chose avec votre réseau...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category,style: const TextStyle(color: Colors.black)  ,),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Catégorie",
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    style: const TextStyle(color: Colors.black)
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ajouter un fichier (optionnel) :",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFileOption(Icons.photo, "Image", Colors.blue, () async {
                        await _pickImageForProfilePost(_postTextController, _selectedCategory);
                      }),
                      _buildFileOption(Icons.picture_as_pdf, "PDF", Colors.red, () async {
                        await _pickPdfForProfilePost(_postTextController, _selectedCategory);
                      }),
                      _buildFileOption(Icons.videocam, "Vidéo", Colors.purple, () async {
                        await _pickVideoForProfilePost(_postTextController, _selectedCategory);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  final text = _postTextController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veuillez écrire un message"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await _publishProfilePost(
                    text: text,
                    category: _selectedCategory,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Publier"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFileOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _publishProfilePost({
    required String text,
    required String category,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    try {
      setState(() => _isSaving = true);

      print("📝 Création du post de profil...");

      // Créer le post
      await _firestore.collection('posts').add({
        'text': text,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': fileName,
        'categorie': category,
        'userId': currentUser!.uid,
        'userName': _userData['name'] ?? currentUser!.displayName ?? 'Utilisateur',
        'timestamp': FieldValue.serverTimestamp(),
        'storageProvider': fileUrl != null ? 'cloudinary' : null,
      });

      print("✅ Post enregistré avec succès");

      // Mettre à jour le compteur
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'postsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Publication créée !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Erreur création post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageForProfilePost(TextEditingController textController, String category) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        Navigator.pop(context); // Fermer la modal d'abord
        setState(() => _isSaving = true);
        
        print("📤 Début upload image vers Cloudinary...");
        final fileUrl = await CloudinaryService.uploadFile(pickedFile, 'image');
        print("📤 Résultat upload image: $fileUrl");
        
        if (fileUrl != null) {
          await _publishProfilePost(
            text: textController.text.isNotEmpty ? textController.text : "Partage une image",
            category: category,
            fileUrl: fileUrl,
            fileType: 'image',
            fileName: pickedFile.name,
          );
        } else {
          _showError("❌ Échec de l'upload de l'image");
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print("❌ Erreur image: $e");
      _showError("Erreur image: $e");
    }
  }

  Future<void> _pickPdfForProfilePost(TextEditingController textController, String category) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        Navigator.pop(context); // Fermer la modal d'abord
        setState(() => _isSaving = true);
        
        print("📤 Début upload PDF vers Cloudinary...");
        final fileUrl = await CloudinaryService.uploadFile(
          XFile(result.files.single.path!), 
          'pdf'
        );
        print("📤 Résultat upload PDF: $fileUrl");
        
        if (fileUrl != null) {
          await _publishProfilePost(
            text: textController.text.isNotEmpty ? textController.text : "Partage un document PDF",
            category: category,
            fileUrl: fileUrl,
            fileType: 'pdf',
            fileName: result.files.single.name,
          );
        } else {
          _showError("❌ Échec de l'upload du PDF");
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print("❌ Erreur PDF: $e");
      _showError("Erreur PDF: $e");
    }
  }

  Future<void> _pickVideoForProfilePost(TextEditingController textController, String category) async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        Navigator.pop(context); // Fermer la modal d'abord
        setState(() => _isSaving = true);
        
        print("📤 Début upload vidéo vers Cloudinary...");
        final fileUrl = await CloudinaryService.uploadFile(pickedFile, 'video');
        print("📤 Résultat upload vidéo: $fileUrl");
        
        if (fileUrl != null) {
          await _publishProfilePost(
            text: textController.text.isNotEmpty ? textController.text : "Partage une vidéo",
            category: category,
            fileUrl: fileUrl,
            fileType: 'video',
            fileName: pickedFile.name,
          );
        } else {
          _showError("❌ Échec de l'upload de la vidéo");
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print("❌ Erreur vidéo: $e");
      _showError("Erreur vidéo: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _locationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }
}
