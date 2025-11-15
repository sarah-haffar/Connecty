// lib/services/friendship_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendshipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static User? get _currentUser => FirebaseAuth.instance.currentUser;

  // ========== CONSTANTES FIRESTORE ==========
  static const String _users = 'users';
  static const String _friends = 'friends';
  static const String _friendRequests = 'friendRequests';

  // ========== ENVOYER UNE DEMANDE D'AMI ==========
  static Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUser == null) throw Exception("Utilisateur non connecté");
    if (_currentUser!.uid == targetUserId) throw Exception("Impossible de s'ajouter soi-même");

    final currentUserId = _currentUser!.uid;

    // Vérifier si une demande existe déjà
    final existingRequest = await _checkExistingRequest(targetUserId);
    if (existingRequest['exists']) {
      throw Exception("Demande d'ami déjà envoyée");
    }

    // Vérifier si déjà amis
    final areAlreadyFriends = await _areFriends(targetUserId);
    if (areAlreadyFriends) {
      throw Exception("Déjà amis");
    }

    // Créer la demande d'ami
    final requestId = _firestore.collection(_users).doc(targetUserId).collection(_friendRequests).doc().id;

    await _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_friendRequests)
        .doc(requestId)
        .set({
          'from': currentUserId,
          'fromName': _currentUser!.displayName ?? _currentUser!.email!.split('@').first,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

    print("✅ Demande d'ami envoyée à $targetUserId");
  }

  // ========== ACCEPTER UNE DEMANDE D'AMI ==========
  static Future<void> acceptFriendRequest(String requestId) async {
    if (_currentUser == null) throw Exception("Utilisateur non connecté");

    final currentUserId = _currentUser!.uid;

    // Récupérer la demande
    final requestDoc = await _firestore
        .collection(_users)
        .doc(currentUserId)
        .collection(_friendRequests)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception("Demande d'ami non trouvée");
    }

    final requestData = requestDoc.data()!;
    final fromUserId = requestData['from'] as String;

    // Batch pour opérations atomiques
    final batch = _firestore.batch();

    // 1. Mettre à jour la demande → accepted
    batch.update(
      _firestore.collection(_users).doc(currentUserId).collection(_friendRequests).doc(requestId),
      {'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp()}
    );

    // 2. Ajouter l'ami dans MA liste d'amis
    batch.set(
      _firestore.collection(_users).doc(currentUserId).collection(_friends).doc(fromUserId),
      {
        'since': FieldValue.serverTimestamp(),
        'friendName': requestData['fromName'],
      }
    );

    // 3. Ajouter l'ami dans SA liste d'amis
    batch.set(
      _firestore.collection(_users).doc(fromUserId).collection(_friends).doc(currentUserId),
      {
        'since': FieldValue.serverTimestamp(),
        'friendName': _currentUser!.displayName ?? _currentUser!.email!.split('@').first,
      }
    );

    await batch.commit();
    print("✅ Demande d'ami acceptée de $fromUserId");
  }

  // ========== REFUSER UNE DEMANDE D'AMI ==========
  static Future<void> declineFriendRequest(String requestId) async {
    if (_currentUser == null) throw Exception("Utilisateur non connecté");

    await _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_friendRequests)
        .doc(requestId)
        .update({
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
        });

    print("✅ Demande d'ami refusée");
  }

  // ========== ANNULER UNE DEMANDE ENVOYÉE ==========
  static Future<void> cancelFriendRequest(String targetUserId) async {
    if (_currentUser == null) throw Exception("Utilisateur non connecté");

    // Trouver la demande pending envoyée à cet utilisateur
    final requestsSnapshot = await _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_friendRequests)
        .where('from', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (requestsSnapshot.docs.isNotEmpty) {
      for (final doc in requestsSnapshot.docs) {
        await doc.reference.delete();
      }
      print("✅ Demande d'ami annulée pour $targetUserId");
    }
  }

  // ========== SUPPRIMER UN AMI ==========
  static Future<void> removeFriend(String friendId) async {
    if (_currentUser == null) throw Exception("Utilisateur non connecté");

    final batch = _firestore.batch();

    // Supprimer de MA liste d'amis
    batch.delete(
      _firestore.collection(_users).doc(_currentUser!.uid).collection(_friends).doc(friendId)
    );

    // Supprimer de SA liste d'amis
    batch.delete(
      _firestore.collection(_users).doc(friendId).collection(_friends).doc(_currentUser!.uid)
    );

    await batch.commit();
    print("✅ Ami $friendId supprimé");
  }

  // ========== RÉCUPÉRER LA LISTE D'AMIS ==========
  static Stream<QuerySnapshot> getUserFriends() {
    if (_currentUser == null) return const Stream<QuerySnapshot>.empty();

    return _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_friends)
        .orderBy('since', descending: true)
        .snapshots();
  }

  // ========== RÉCUPÉRER LES IDS DES AMIS ==========
  static Future<List<String>> getUserFriendsIds() async {
    if (_currentUser == null) return [];

    final friendsSnapshot = await _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_friends)
        .get();

    return friendsSnapshot.docs.map((doc) => doc.id).toList();
  }

  // ========== RÉCUPÉRER LES DEMANDES D'AMI ==========
  static Stream<QuerySnapshot> getFriendRequests() {
    if (_currentUser == null) return const Stream<QuerySnapshot>.empty();

    return _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_friendRequests)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ========== VÉRIFIER LE STATUT D'AMITIÉ ==========
  static Future<Map<String, dynamic>> checkFriendshipStatus(String targetUserId) async {
    if (_currentUser == null) {
      return {'error': 'Utilisateur non connecté'};
    }

    if (_currentUser!.uid == targetUserId) {
      return {
        'isCurrentUser': true,
        'isFriend': false,
        'hasSentRequest': false,
        'hasReceivedRequest': false,
      };
    }

    // Vérifier si amis
    final areFriends = await _areFriends(targetUserId);

    // Vérifier les demandes en attente
    final pendingRequest = await _checkPendingRequest(targetUserId);

    return {
      'isCurrentUser': false,
      'isFriend': areFriends,
      'hasSentRequest': pendingRequest['sent'],
      'hasReceivedRequest': pendingRequest['received'],
      'requestId': pendingRequest['requestId'],
    };
  }

  // ========== MÉTHODES PRIVÉES ==========
  static Future<bool> _areFriends(String targetUserId) async {
    final friendDoc = await _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_friends)
        .doc(targetUserId)
        .get();

    return friendDoc.exists;
  }

  static Future<Map<String, dynamic>> _checkExistingRequest(String targetUserId) async {
    final requestSnapshot = await _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_friendRequests)
        .where('from', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return {
      'exists': requestSnapshot.docs.isNotEmpty,
      'requestId': requestSnapshot.docs.isNotEmpty ? requestSnapshot.docs.first.id : null,
    };
  }

  static Future<Map<String, dynamic>> _checkPendingRequest(String targetUserId) async {
    final currentUserId = _currentUser!.uid;

    // Vérifier si J'AI envoyé une demande
    final sentRequest = await _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_friendRequests)
        .where('from', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    // Vérifier si J'AI reçu une demande
    final receivedRequest = await _firestore
        .collection(_users)
        .doc(currentUserId)
        .collection(_friendRequests)
        .where('from', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    return {
      'sent': sentRequest.docs.isNotEmpty,
      'received': receivedRequest.docs.isNotEmpty,
      'requestId': receivedRequest.docs.isNotEmpty ? receivedRequest.docs.first.id : null,
    };
  }

  // ========== RECHERCHER DES UTILISATEURS ==========
  static Stream<QuerySnapshot> searchUsers(String query) {
    if (query.isEmpty) return const Stream<QuerySnapshot>.empty();

    return _firestore
        .collection(_users)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }

  // ========== RÉCUPÉRER LES INFOS D'UN UTILISATEUR ==========
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection(_users).doc(userId).get();
      return userDoc.data();
    } catch (e) {
      print("❌ Erreur récupération user data: $e");
      return null;
    }
  }
}