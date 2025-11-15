// lib/services/interaction_service.dart (version sans share_plus)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static User? get _currentUser => FirebaseAuth.instance.currentUser;

  // ========== CONSTANTES FIRESTORE ==========
  static const String _users = 'users';
  static const String _posts = 'posts';
  static const String _comments = 'comments';
  static const String _likes = 'likes';
  static const String _shares = 'shares';
  static const String _favorites = 'favorites';

  // ========== LIKES ==========
  static Future<void> toggleLike(String postId) async {
    if (_currentUser == null) return;

    final likeRef = _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_likes)
        .doc(_currentUser!.uid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'userId': _currentUser!.uid,
        'userName':
            _currentUser!.displayName ?? _currentUser!.email!.split('@').first,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<int> getLikesCount(String postId) {
    return _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_likes)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<bool> isLikedByUser(String postId) async {
    if (_currentUser == null) return false;

    final likeDoc = await _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_likes)
        .doc(_currentUser!.uid)
        .get();

    return likeDoc.exists;
  }

  static Stream<QuerySnapshot> getLikes(String postId) {
    return _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_likes)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ========== COMMENTAIRES ==========
  static Future<void> addComment(String postId, String content) async {
    if (_currentUser == null || content.trim().isEmpty) return;

    await _firestore.collection(_posts).doc(postId).collection(_comments).add({
      'userId': _currentUser!.uid,
      'userName':
          _currentUser!.displayName ?? _currentUser!.email!.split('@').first,
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_comments)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    final commentRef = _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_comments)
        .doc(commentId);

    final commentDoc = await commentRef.get();
    if (commentDoc.exists && commentDoc['userId'] == _currentUser?.uid) {
      await commentRef.delete();
    }
  }

  // ========== FAVORIS ==========
  static Future<void> toggleFavorite(String postId) async {
    if (_currentUser == null) return;

    final favoriteRef = _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_favorites)
        .doc(postId);

    final favoriteDoc = await favoriteRef.get();

    if (favoriteDoc.exists) {
      await favoriteRef.delete();
      print('🗑️ Favori supprimé: $postId');
    } else {
      // Récupérer les données du post pour les sauvegarder dans les favoris
      final postDoc = await _firestore.collection(_posts).doc(postId).get();
      if (postDoc.exists) {
        await favoriteRef.set({
          'postData': postDoc.data(),
          'addedAt': FieldValue.serverTimestamp(),
        });
        print('⭐ Favori ajouté: $postId');
      }
    }
  }

  static Future<bool> isFavorite(String postId) async {
    if (_currentUser == null) return false;

    final favoriteDoc = await _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_favorites)
        .doc(postId)
        .get();

    return favoriteDoc.exists;
  }

  static Stream<QuerySnapshot> getUserFavorites() {
    if (_currentUser == null) return const Stream.empty();

    return _firestore
        .collection(_users)
        .doc(_currentUser!.uid)
        .collection(_favorites)
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // ========== PARTAGES ==========
  static Future<void> addShare(String postId) async {
    if (_currentUser == null) return;

    await _firestore.collection(_posts).doc(postId).collection(_shares).add({
      'userId': _currentUser!.uid,
      'userName':
          _currentUser!.displayName ?? _currentUser!.email!.split('@').first,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<int> getSharesCount(String postId) {
    return _firestore
        .collection(_posts)
        .doc(postId)
        .collection(_shares)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ========== UTILITAIRES ==========
  static String getCurrentUserId() {
    return _currentUser?.uid ?? 'unknown';
  }

  static String getCurrentUserName() {
    return _currentUser?.displayName ??
        _currentUser?.email?.split('@').first ??
        'Utilisateur';
  }
}
