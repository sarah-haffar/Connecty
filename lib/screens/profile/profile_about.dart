import 'package:flutter/material.dart';

class ProfileAbout extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isCurrentUser;
  final Color primaryColor;

  const ProfileAbout({
    super.key,
    required this.userData,
    required this.isCurrentUser,
    required this.primaryColor,
  });

  Map<String, String> get _aboutInfo {
    return {
      "Âge": userData['age']?.isNotEmpty == true
          ? userData['age']
          : 'Non renseigné',
      "École": userData['school']?.isNotEmpty == true
          ? userData['school']
          : 'Non renseigné',
      "Lieu": userData['location']?.isNotEmpty == true
          ? userData['location']
          : 'Non renseigné',
      "Centres d'intérêt": userData['interests']?.isNotEmpty == true
          ? userData['interests']
          : 'Non renseigné',
    };
  }

  @override
  Widget build(BuildContext context) {
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

          // Indicateur si profil incomplet (seulement pour l'utilisateur courant)
          if (_aboutInfo.values.every((value) => value == 'Non renseigné') && isCurrentUser)
            _buildIncompleteProfileWarning(),

          // Liste des informations
          ..._buildInfoList(),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileWarning() {
    return Container(
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
    );
  }

  List<Widget> _buildInfoList() {
    return _aboutInfo.entries.map(
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
    ).toList();
  }
}