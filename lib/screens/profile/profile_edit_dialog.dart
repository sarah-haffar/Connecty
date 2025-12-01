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
  
  String? _ageErrorText;
  bool _isAgeValid = true;

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
    
    // Valider l'âge initial
    if (_ageController.text.isNotEmpty) {
      _validateAge(_ageController.text);
    }
  }

  // Fonction pour valider l'âge (12 à 18 ans inclus)
  bool _validateAge(String? ageText) {
    if (ageText == null || ageText.isEmpty) {
      setState(() {
        _ageErrorText = null;
        _isAgeValid = true; // Vide est valide (optionnel)
      });
      return true;
    }

    // Essayer de convertir en nombre
    final age = int.tryParse(ageText);
    if (age == null) {
      setState(() {
        _ageErrorText = "Veuillez entrer un âge valide";
        _isAgeValid = false;
      });
      return false;
    }

    // Vérifier la plage d'âge : 12 à 18 ans inclus
    if (age >= 12 && age <= 18) {
      setState(() {
        _ageErrorText = null;
        _isAgeValid = true;
      });
      return true;
    } else {
      setState(() {
        _ageErrorText = "Âge non autorisé (12-18 ans seulement)";
        _isAgeValid = false;
      });
      return false;
    }
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
      child: Column(
        children: [
          Text(
            'Tous les champs sont optionnels',
            style: TextStyle(color: Colors.blue, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Âge accepté: 12 à 18 ans uniquement',
            style: TextStyle(color: widget.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
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
            hintText: "12 à 18 ans seulement",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.cake, color: widget.primaryColor),
            errorText: _ageErrorText,
            errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            suffixIcon: _ageController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.info, color: widget.primaryColor, size: 18),
                    onPressed: () {
                      _showAgeInfoDialog(context);
                    },
                  )
                : null,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _validateAge(value);
          },
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _schoolController,
          decoration: InputDecoration(
            labelText: "École",
            labelStyle: TextStyle(color: widget.primaryColor),
            hintText: "ex: Collège/Lycée...",
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

  void _showAgeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Âge accepté"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pour utiliser l'application, l'âge doit être entre:"),
            SizedBox(height: 8),
            Text("• 12 ans (inclus)"),
            Text("• 13 ans"),
            Text("• 14 ans"),
            Text("• 15 ans"),
            Text("• 16 ans"),
            Text("• 17 ans"),
            Text("• 18 ans (inclus)"),
            SizedBox(height: 8),
            Text("Application réservée aux adolescents."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
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
    // Le bouton est désactivé si: en cours de sauvegarde OU âge invalide
    final isDisabled = widget.isSaving || !_isAgeValid;
    
    return ElevatedButton(
      onPressed: isDisabled ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey : widget.primaryColor,
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
    // Validation finale avant sauvegarde
    if (!_validateAge(_ageController.text.trim())) {
      // Si l'âge est invalide, on ne fait RIEN
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Âge non valide. Veuillez corriger avant de sauvegarder."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

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