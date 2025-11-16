import 'package:flutter/material.dart';

class ProfileEditDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isSaving;
  final VoidCallback onUpdateProfile;
  final VoidCallback onUpdateProfileImage;
  final Color primaryColor;

  const ProfileEditDialog({
    super.key,
    required this.userData,
    required this.isSaving,
    required this.onUpdateProfile,
    required this.onUpdateProfileImage,
    required this.primaryColor,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _bioController.text = widget.userData['bio'] ?? '';
    _ageController.text = widget.userData['age'] ?? '';
    _schoolController.text = widget.userData['school'] ?? '';
    _locationController.text = widget.userData['location'] ?? '';
    _interestsController.text = widget.userData['interests'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.edit, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text(
            "Modifier le profil",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.primaryColor,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo de profil modifiable
            _buildProfileImageSection(),
            const SizedBox(height: 16),

            // Indication champs optionnels
            _buildOptionalFieldsInfo(),
            const SizedBox(height: 12),

            // Formulaire de modification
            _buildEditForm(),
          ],
        ),
      ),
      actions: [
        _buildCancelButton(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: widget.primaryColor.withOpacity(0.1),
          backgroundImage: widget.userData['profileImage'] != null
              ? NetworkImage(widget.userData['profileImage']!) as ImageProvider
              : const AssetImage("assets/post/art.jpg"),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: widget.onUpdateProfileImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.primaryColor,
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
    );
  }

  Widget _buildOptionalFieldsInfo() {
    return Container(
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
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        TextField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: "Bio",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "Décrivez-vous en quelques mots...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.description, color: widget.primaryColor),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: "Âge",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "ex: 21 ans",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.cake, color: widget.primaryColor),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _schoolController,
          decoration: InputDecoration(
            labelText: "École",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "ex: ISET Kelibia",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.school, color: widget.primaryColor),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: "Lieu",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "ex: Kelibia, Tunisie",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.location_on, color: widget.primaryColor),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _interestsController,
          decoration: InputDecoration(
            labelText: "Centres d'intérêt",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "ex: Programmation, Design, Lecture",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.interests, color: widget.primaryColor),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.primaryColor,
        side: BorderSide(color: widget.primaryColor),
      ),
      child: const Text("Annuler"),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: widget.isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: widget.isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text("Sauvegarder"),
    );
  }

  void _saveProfile() {
    // Mettre à jour les données locales avant de sauvegarder
    widget.userData['bio'] = _bioController.text.trim();
    widget.userData['age'] = _ageController.text.trim();
    widget.userData['school'] = _schoolController.text.trim();
    widget.userData['location'] = _locationController.text.trim();
    widget.userData['interests'] = _interestsController.text.trim();
    
    // Fermer le dialog et appeler la méthode de sauvegarde
    Navigator.pop(context);
    widget.onUpdateProfile();
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