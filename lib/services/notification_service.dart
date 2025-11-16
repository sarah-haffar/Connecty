// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _notifications = 'notifications';
  static const String _posts = 'posts';
  static const String _users = 'users';

  // Créer une notification pour un like
  static Future<void> createLikeNotification({
    required String postId,
    required String postOwnerId,
    required String likerName,
  }) async {
    if (_auth.currentUser == null) return;

    // Ne pas notifier si l'utilisateur like son propre post
    if (_auth.currentUser!.uid == postOwnerId) return;

    final notificationRef = _firestore
        .collection(_users)
        .doc(postOwnerId)
        .collection(_notifications)
        .doc();

    await notificationRef.set({
      'type': 'like',
      'postId': postId,
      'fromUserId': _auth.currentUser!.uid,
      'fromUserName': likerName,
      'message': '$likerName a aimé votre publication',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Créer une notification pour un commentaire
  static Future<void> createCommentNotification({
    required String postId,
    required String postOwnerId,
    required String commenterName,
    required String commentContent,
  }) async {
    if (_auth.currentUser == null) return;

    // Ne pas notifier si l'utilisateur commente son propre post
    if (_auth.currentUser!.uid == postOwnerId) return;

    final notificationRef = _firestore
        .collection(_users)
        .doc(postOwnerId)
        .collection(_notifications)
        .doc();

    String truncatedComment = commentContent.length > 50
        ? '${commentContent.substring(0, 50)}...'
        : commentContent;

    await notificationRef.set({
      'type': 'comment',
      'postId': postId,
      'fromUserId': _auth.currentUser!.uid,
      'fromUserName': commenterName,
      'commentContent': truncatedComment,
      'message':
          '$commenterName a commenté votre publication: "$truncatedComment"',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les notifications de l'utilisateur
  static Stream<QuerySnapshot> getUserNotifications() {
    if (_auth.currentUser == null) return const Stream.empty();

    return _firestore
        .collection(_users)
        .doc(_auth.currentUser!.uid)
        .collection(_notifications)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    if (_auth.currentUser == null) return;

    await _firestore
        .collection(_users)
        .doc(_auth.currentUser!.uid)
        .collection(_notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead() async {
    if (_auth.currentUser == null) return;

    final notifications = await _firestore
        .collection(_users)
        .doc(_auth.currentUser!.uid)
        .collection(_notifications)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Compter les notifications non lues
  static Stream<int> getUnreadCount() {
    if (_auth.currentUser == null) return Stream.value(0);

    return _firestore
        .collection(_users)
        .doc(_auth.currentUser!.uid)
        .collection(_notifications)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    if (_auth.currentUser == null) return;

    await _firestore
        .collection(_users)
        .doc(_auth.currentUser!.uid)
        .collection(_notifications)
        .doc(notificationId)
        .delete();
  }

  // Ajoutez ces méthodes dans votre NotificationService (lib/services/notification_service.dart)

  // Créer une notification pour une demande d'amitié
  static Future<void> createFriendRequestNotification({
    required String targetUserId,
    required String senderName,
  }) async {
    if (_auth.currentUser == null) return;

    // Ne pas notifier si l'utilisateur s'envoie une demande à lui-même
    if (_auth.currentUser!.uid == targetUserId) return;

    final notificationRef = _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_notifications)
        .doc();

    await notificationRef.set({
      'type': 'friend_request',
      'fromUserId': _auth.currentUser!.uid,
      'fromUserName': senderName,
      'message': '$senderName vous a envoyé une demande d\'amitié',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Accepter une demande d'amitié
  static Future<void> acceptFriendRequest(
    String notificationId,
    String friendUserId,
    String friendName,
  ) async {
    if (_auth.currentUser == null) return;

    final currentUserId = _auth.currentUser!.uid;

    // Ajouter l'ami à la liste d'amis de l'utilisateur actuel
    await _firestore.collection(_users).doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([friendUserId]),
    });

    // Ajouter l'utilisateur actuel à la liste d'amis de l'ami
    await _firestore.collection(_users).doc(friendUserId).update({
      'friends': FieldValue.arrayUnion([currentUserId]),
    });

    // Créer une notification de confirmation pour l'ami
    await createFriendRequestAcceptedNotification(
      targetUserId: friendUserId,
      accepterName: _auth.currentUser!.displayName ?? 'Quelqu\'un',
    );

    // Marquer la notification comme lue
    await markAsRead(notificationId);
  }

  // Créer une notification d'acceptation de demande d'amitié
  static Future<void> createFriendRequestAcceptedNotification({
    required String targetUserId,
    required String accepterName,
  }) async {
    if (_auth.currentUser == null) return;

    final notificationRef = _firestore
        .collection(_users)
        .doc(targetUserId)
        .collection(_notifications)
        .doc();

    await notificationRef.set({
      'type': 'friend_request_accepted',
      'fromUserId': _auth.currentUser!.uid,
      'fromUserName': accepterName,
      'message': '$accepterName a accepté votre demande d\'amitié',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Refuser une demande d'amitié
  static Future<void> declineFriendRequest(String notificationId) async {
    if (_auth.currentUser == null) return;

    // Simplement marquer la notification comme lue
    await markAsRead(notificationId);
  }
}
