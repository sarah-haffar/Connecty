import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/post_card.dart';
import '../home_page.dart';
import '../../services/cloudinary_service.dart';
import '../../services/friendship_service.dart';
import 'profile_header.dart';
import 'profile_posts.dart';
import 'profile_about.dart';
import 'profile_friends.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  
  const ProfilePage({
    super.key,
    this.userId,
  });

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

  // Variables pour l'amitié
  bool _isCurrentUserProfile = true;
  String? _viewedUserId;
  Map<String, dynamic> _friendshipStatus = {
    'isFriend': false,
    'hasSentRequest': false,
    'hasReceivedRequest': false,
    'requestId': null,
  };
  bool _isLoadingFriendship = false;

  // Stream pour les posts en temps réel
  Stream<QuerySnapshot> get _userPostsStream {
    final String userIdToLoad = _viewedUserId ?? currentUser?.uid ?? '';
    if (userIdToLoad.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }

    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userIdToLoad)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadUserData(),
      _loadUserFriends(),
    ]);
    setState(() => _isLoading = false);
  }

  void _initializeProfile() {
    _viewedUserId = widget.userId;
    _isCurrentUserProfile = _viewedUserId == null || 
                           _viewedUserId == _auth.currentUser?.uid;
    
    if (!_isCurrentUserProfile) {
      _checkFriendshipStatus();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final String userIdToLoad = _viewedUserId ?? currentUser?.uid ?? '';
      if (userIdToLoad.isEmpty) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(userIdToLoad)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
          _initializeControllers();
        });
      } else {
        if (_isCurrentUserProfile) {
          await _createUserProfile();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil non trouvé'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Erreur chargement données utilisateur: $e");
    }
  }

  Future<void> _createUserProfile() async {
    if (!_isCurrentUserProfile) return;

    try {
      final newUserData = {
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        'name': currentUser!.displayName ?? currentUser!.email!.split('@').first,
        'pseudo': '@${currentUser!.email!.split('@').first}',
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
      final String userIdToLoad = _viewedUserId ?? currentUser?.uid ?? '';
      if (userIdToLoad.isEmpty) return;

      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(userIdToLoad)
          .collection('friends')
          .get();

      setState(() {
        _userFriends = friendsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("❌ Erreur chargement amis: $e");
    }
  }

  // ========== MÉTHODES POUR L'AMITIÉ ==========

  Future<void> _checkFriendshipStatus() async {
    if (_viewedUserId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      final status = await FriendshipService.checkFriendshipStatus(_viewedUserId!);
      
      if (mounted) {
        setState(() {
          _friendshipStatus = status;
        });
      }
    } catch (e) {
      print("❌ Erreur vérification statut amitié: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_viewedUserId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      await FriendshipService.sendFriendRequest(_viewedUserId!);
      await _checkFriendshipStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Demande d'ami envoyée !"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
    }
  }

  Future<void> _acceptFriendRequest() async {
    final requestId = _friendshipStatus['requestId'];
    if (requestId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      await FriendshipService.acceptFriendRequest(requestId);
      await _checkFriendshipStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Vous êtes maintenant amis !"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
    }
  }

  Future<void> _declineFriendRequest() async {
    final requestId = _friendshipStatus['requestId'];
    if (requestId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      await FriendshipService.declineFriendRequest(requestId);
      await _checkFriendshipStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Demande d'ami refusée"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
    }
  }

  Future<void> _cancelFriendRequest() async {
    if (_viewedUserId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      await FriendshipService.cancelFriendRequest(_viewedUserId!);
      await _checkFriendshipStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Demande d'ami annulée"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
    }
  }

  Future<void> _removeFriend() async {
    if (_viewedUserId == null) return;
    
    setState(() => _isLoadingFriendship = true);
    
    try {
      await FriendshipService.removeFriend(_viewedUserId!);
      await _checkFriendshipStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Ami retiré de votre liste"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingFriendship = false);
      }
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

      setState(() {
        _userData.addAll(updatedData);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil mis à jour avec succès !'),
          backgroundColor: Colors.green,
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
              content: Text('✅ Photo de profil mise à jour !'),
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
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête du profil
          ProfileHeader(
            userData: _userData,
            isCurrentUserProfile: _isCurrentUserProfile,
            isLoadingFriendship: _isLoadingFriendship,
            isSaving: _isSaving,
            friendshipStatus: _friendshipStatus,
            onEditProfile: _editProfile,
            onUpdateProfileImage: _updateProfileImage,
            onShowCreatePostModal: _showCreatePostModal,
            onSendFriendRequest: _sendFriendRequest,
            onAcceptFriendRequest: _acceptFriendRequest,
            onDeclineFriendRequest: _declineFriendRequest,
            onCancelFriendRequest: _cancelFriendRequest,
            onRemoveFriend: _removeFriend,
            primaryColor: primaryColor,
          ),

          // Section statistiques
          _buildStatsSection(),

          // Section navigation
          _buildNavigationSection(),

          const SizedBox(height: 16),

          // Contenu dynamique
          _buildSelectedSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
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
          _buildStatItem("Amis", _userFriends.length),
          StreamBuilder<QuerySnapshot>(
            stream: _userPostsStream,
            builder: (context, snapshot) {
              final postsCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatItem("Publications", postsCount);
            },
          ),
          _buildStatItem("Favoris", _userData['favoritesCount'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Container(
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
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 0:
        return ProfilePosts(
          userId: _viewedUserId ?? _auth.currentUser?.uid,
          isCurrentUser: _isCurrentUserProfile,
          primaryColor: primaryColor,
          onShowPostOptions: _showPostOptions,
        );
      case 1:
        return ProfileAbout(
          userData: _userData,
          isCurrentUser: _isCurrentUserProfile,
          primaryColor: primaryColor,
        );
      case 2:
        return ProfileFriends(
          userId: _viewedUserId ?? _auth.currentUser?.uid,
          isCurrentUser: _isCurrentUserProfile,
          primaryColor: primaryColor,
        );
      default:
        return ProfilePosts(
          userId: _viewedUserId ?? _auth.currentUser?.uid,
          isCurrentUser: _isCurrentUserProfile,
          primaryColor: primaryColor,
          onShowPostOptions: _showPostOptions,
        );
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

  // ========== MÉTHODES POUR LES POSTS ==========

  void _showCreatePostModal() {
    final TextEditingController postTextController = TextEditingController();
    String selectedCategory = 'Général';
    final List<String> categories = [
      'Général', 'Programmation', 'Design', 'Études', 'Loisirs',
      'Voyages', 'Art', 'Musique', 'Sport', 'Autre',
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
                    controller: postTextController,
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
                    initialValue: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Catégorie",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Ajouter un fichier (optionnel) :"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFileOption(Icons.photo, "Image", Colors.blue, () {
                        _pickImageForProfilePost(postTextController, selectedCategory);
                      }),
                      _buildFileOption(Icons.picture_as_pdf, "PDF", Colors.red, () {
                        _pickPdfForProfilePost(postTextController, selectedCategory);
                      }),
                      _buildFileOption(Icons.videocam, "Vidéo", Colors.purple, () {
                        _pickVideoForProfilePost(postTextController, selectedCategory);
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
                  final text = postTextController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez écrire un message")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await _publishProfilePost(text: text, category: selectedCategory);
                },
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
          child: IconButton(icon: Icon(icon, color: color), onPressed: onTap),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color)),
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

      await _firestore.collection('posts').add({
        'text': text,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': fileName,
        'categorie': category,
        'userId': currentUser!.uid,
        'userName': _userData['name'] ?? 'Utilisateur',
        'timestamp': FieldValue.serverTimestamp(),
        'storageProvider': fileUrl != null ? 'cloudinary' : null,
      });

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Publication créée !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageForProfilePost(TextEditingController controller, String category) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        Navigator.pop(context);
        setState(() => _isSaving = true);

        final fileUrl = await CloudinaryService.uploadFile(pickedFile, 'image');
        if (fileUrl != null) {
          await _publishProfilePost(
            text: controller.text.isNotEmpty ? controller.text : "Partage une image",
            category: category,
            fileUrl: fileUrl,
            fileType: 'image',
            fileName: pickedFile.name,
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError("Erreur image: $e");
    }
  }

  Future<void> _pickPdfForProfilePost(TextEditingController controller, String category) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        Navigator.pop(context);
        setState(() => _isSaving = true);

        final fileUrl = await CloudinaryService.uploadFile(
          XFile(result.files.single.path!),
          'pdf',
        );
        if (fileUrl != null) {
          await _publishProfilePost(
            text: controller.text.isNotEmpty ? controller.text : "Partage un document PDF",
            category: category,
            fileUrl: fileUrl,
            fileType: 'pdf',
            fileName: result.files.single.name,
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError("Erreur PDF: $e");
    }
  }

  Future<void> _pickVideoForProfilePost(TextEditingController controller, String category) async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        Navigator.pop(context);
        setState(() => _isSaving = true);

        final fileUrl = await CloudinaryService.uploadFile(pickedFile, 'video');
        if (fileUrl != null) {
          await _publishProfilePost(
            text: controller.text.isNotEmpty ? controller.text : "Partage une vidéo",
            category: category,
            fileUrl: fileUrl,
            fileType: 'video',
            fileName: pickedFile.name,
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError("Erreur vidéo: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            Text("Modifier le profil", style: TextStyle(color: primaryColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    backgroundImage: _userData['profileImage'] != null
                        ? NetworkImage(_userData['profileImage']!) as ImageProvider
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
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _bioController, decoration: const InputDecoration(labelText: "Bio"), maxLines: 3),
              const SizedBox(height: 12),
              TextField(controller: _ageController, decoration: const InputDecoration(labelText: "Âge")),
              const SizedBox(height: 12),
              TextField(controller: _schoolController, decoration: const InputDecoration(labelText: "École")),
              const SizedBox(height: 12),
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Lieu")),
              const SizedBox(height: 12),
              TextField(controller: _interestsController, decoration: const InputDecoration(labelText: "Centres d'intérêt"), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: _isSaving ? null : () async {
              Navigator.pop(context);
              await _updateProfile();
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, String postId, Map<String, dynamic> postData) {
    final String postUserId = postData['userId'] ?? '';

    if (currentUser!.uid != postUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez modifier que vos propres posts")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Modifier le post"),
              onTap: () {
                Navigator.pop(context);
                _showEditPostDialog(postId, postData['text'] ?? '');
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

  void _showEditPostDialog(String postId, String currentText) {
    final TextEditingController editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le post"),
        content: TextField(controller: editController, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _editPost(postId, editController.text.trim());
              }
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(String postId, String newText) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Post modifié !")));
    } catch (e) {
      _showError("Erreur modification: $e");
    }
  }

  Future<void> _deletePost(String postId, String? fileUrl, String? fileType) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce post ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        if (fileUrl != null && fileType == 'image') {
          await CloudinaryService.deleteFileSimple(fileUrl);
        }

        await _firestore.collection('posts').doc(postId).delete();

        await _firestore.collection('users').doc(currentUser!.uid).update({
          'postsCount': FieldValue.increment(-1),
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Post supprimé !")));
      } catch (e) {
        _showError("Erreur suppression: $e");
      }
    }
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