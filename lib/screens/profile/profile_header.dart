import 'package:flutter/material.dart';
import 'package:connecty_app/services/friendship_service.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isCurrentUserProfile;
  final bool isLoadingFriendship;
  final bool isSaving;
  final Map<String, dynamic> friendshipStatus;
  final VoidCallback onEditProfile;
  final VoidCallback onUpdateProfileImage;
  final VoidCallback onShowCreatePostModal;
  final VoidCallback onSendFriendRequest;
  final VoidCallback onAcceptFriendRequest;
  final VoidCallback onDeclineFriendRequest;
  final VoidCallback onCancelFriendRequest;
  final VoidCallback onRemoveFriend;
  final Color primaryColor;

  const ProfileHeader({
    super.key,
    required this.userData,
    required this.isCurrentUserProfile,
    required this.isLoadingFriendship,
    required this.isSaving,
    required this.friendshipStatus,
    required this.onEditProfile,
    required this.onUpdateProfileImage,
    required this.onShowCreatePostModal,
    required this.onSendFriendRequest,
    required this.onAcceptFriendRequest,
    required this.onDeclineFriendRequest,
    required this.onCancelFriendRequest,
    required this.onRemoveFriend,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildProfileImage(),
          const SizedBox(height: 16),

          // Nom et pseudo
          _buildNameAndPseudo(),
          const SizedBox(height: 12),

          // Bio
          _buildBio(),
          const SizedBox(height: 20),

          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: userData['profileImage'] != null
              ? NetworkImage(userData['profileImage']!) as ImageProvider
              : const AssetImage("assets/post/art.jpg"),
        ),
        if (isCurrentUserProfile)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onUpdateProfileImage,
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
    );
  }

  Widget _buildNameAndPseudo() {
    final username = userData['name'] ?? 
                    userData['username'] ?? 
                    'Utilisateur';
    
    final pseudo = userData['pseudo'] ?? '@utilisateur';

    return Column(
      children: [
        Text(
          username,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pseudo,
          style: TextStyle(
            fontSize: 16,
            color: primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBio() {
    final bio = userData['bio']?.isNotEmpty == true
        ? userData['bio']
        : 'Bienvenue sur mon profil ! 👋\nCliquez sur "Modifier profil" pour personnaliser.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: userData['bio']?.isEmpty == true
            ? Colors.orange.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        bio,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: userData['bio']?.isEmpty == true
              ? Colors.orange
              : Colors.black87,
          fontStyle: userData['bio']?.isEmpty == true
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // BOUTON MODIFIER PROFIL (seulement si mon profil)
        if (isCurrentUserProfile) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, size: 20),
              label: isSaving
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
          const SizedBox(width: 12),
        ],

        // BOUTON D'AMITIÉ (seulement si profil visité)
        if (!isCurrentUserProfile) ...[
          Expanded(
            child: _buildFriendshipButton(),
          ),
          const SizedBox(width: 12),
        ],

        // BOUTON NOUVEAU POST (toujours visible sur mon profil)
        if (isCurrentUserProfile) 
          ElevatedButton.icon(
            onPressed: isSaving ? null : onShowCreatePostModal,
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
            label: const Text(
              "Nouveau post",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFriendshipButton() {
    if (isLoadingFriendship) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (friendshipStatus['isFriend'] == true) {
      return ElevatedButton.icon(
        onPressed: onRemoveFriend,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.check, size: 20),
        label: const Text("Ami"),
      );
    } else if (friendshipStatus['hasSentRequest'] == true) {
      return OutlinedButton.icon(
        onPressed: onCancelFriendRequest,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.pending, size: 20),
        label: const Text("Demande envoyée"),
      );
    } else if (friendshipStatus['hasReceivedRequest'] == true) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAcceptFriendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text("Accepter"),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDeclineFriendRequest,
            icon: const Icon(Icons.close, color: Colors.red, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onSendFriendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.person_add, size: 20),
        label: const Text("Ajouter en ami"),
      );
    }
  }
}