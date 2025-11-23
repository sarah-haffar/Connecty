import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static User? get user => FirebaseAuth.instance.currentUser;
  static String get uid => user?.uid ?? '';

  /// Générer l'ID de chat entre deux utilisateurs
  static String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Envoyer un message
  static Future<void> sendMessage({
    required String friendId,
    String text = '',
    String? replyTo,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    if (user == null) return;
    if (text.trim().isEmpty && imageUrl == null && voiceUrl == null) return;

    final chatRef = _db.collection('chats').doc(chatId(uid, friendId));
    final msgRef = chatRef.collection('messages').doc();

    Map<String, dynamic> messageData = {
      'id': msgRef.id,
      'senderId': uid,
      'receiverId': friendId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // <-- IMPORTANT
      'isDeleted': false,
      'isEdited': false,
      'reactions': <String, String>{},
      'replyTo': replyTo,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
    };

    // Gestion réponse
    if (replyTo != null) {
      final originalMsgSnap = await chatRef
          .collection('messages')
          .doc(replyTo)
          .get();
      if (originalMsgSnap.exists) {
        final data = originalMsgSnap.data()!;
        String originalText;
        if (data['isDeleted'] == true)
          originalText = "Ce message a été supprimé";
        else if (data['imageUrl'] != null)
          originalText = "Photo";
        else if (data['voiceUrl'] != null)
          originalText = "Message vocal";
        else
          originalText = data['text'] ?? "Message";

        messageData['repliedText'] = originalText;
        messageData['repliedSenderId'] = data['senderId'];
      }
    }

    final batch = _db.batch();
    batch.set(msgRef, messageData);

    // Mettre à jour le chat
    final previewText = text.isNotEmpty
        ? text.trim()
        : imageUrl != null
        ? 'Photo'
        : voiceUrl != null
        ? 'Message vocal'
        : 'Message';

    batch.set(chatRef, {
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'users': [uid, friendId],
      'unreadCount_$uid': 0,
      'unreadCount_$friendId': FieldValue.increment(1),
      'typing_$uid': false,
      'typing_$friendId': false,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static Future<void> markMessagesAsSeen(String friendId) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final id = chatId(currentUid, friendId);

    final chatRef = _db.collection('chats').doc(id);
    final messagesRef = chatRef.collection('messages');

    final snap = await messagesRef
        .where('receiverId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    batch.update(chatRef, {'unreadCount_$currentUid': 0});

    await batch.commit();
  }

  /// Réaction
  static Future<void> addReaction(
    String friendId,
    String messageId,
    String emoji,
  ) async {
    final ref = _db
        .collection('chats')
        .doc(chatId(uid, friendId))
        .collection('messages')
        .doc(messageId);
    await ref.update({'reactions.$uid': emoji});
  }

  /// Supprimer un message
  static Future<void> deleteMessage(
    String friendId,
    String messageId,
    bool forEveryone,
  ) async {
    final ref = _db
        .collection('chats')
        .doc(chatId(uid, friendId))
        .collection('messages')
        .doc(messageId);

    if (forEveryone) {
      await ref.update({
        'isDeleted': true,
        'text': 'Ce message a été supprimé',
        'imageUrl': FieldValue.delete(),
        'voiceUrl': FieldValue.delete(),
        'reactions': FieldValue.delete(),
      });
    } else {
      await ref.update({'deletedFor_$uid': true});
    }
  }

  /// Modifier un message
  static Future<void> editMessage({
    required String friendId,
    required String messageId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;
    final ref = _db
        .collection('chats')
        .doc(chatId(uid, friendId))
        .collection('messages')
        .doc(messageId);
    await ref.update({
      'text': newText.trim(),
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Typing indicator
  static Future<void> setTyping(String friendId, bool typing) async {
    final chatRef = _db.collection('chats').doc(chatId(uid, friendId));
    await chatRef.set({'typing_$uid': typing}, SetOptions(merge: true));
  }

  /// Statut en ligne
  static Future<void> updateOnlineStatus(bool online) async {
    if (user == null) return;
    await _db.collection('users').doc(uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams
  static Stream<QuerySnapshot> getMessages(String friendId) => _db
      .collection('chats')
      .doc(chatId(uid, friendId))
      .collection('messages')
      .orderBy('timestamp')
      .snapshots();

  static Stream<DocumentSnapshot> friendStatus(String friendId) =>
      _db.collection('users').doc(friendId).snapshots();

  static Stream<List<Map<String, dynamic>>> getChatPreviews() => _db
      .collection('chats')
      .where('users', arrayContains: uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          final otherId = (data['users'] as List).firstWhere(
            (id) => id != uid,
            orElse: () => '',
          );
          return {
            'friendId': otherId,
            'friendName': data['friendName_$otherId'] ?? 'Utilisateur',
            'friendPhotoUrl': data['friendPhotoUrl_$otherId'],
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'unreadCount': data['unreadCount_$uid'] ?? 0,
            'isTyping': data['typing_$otherId'] == true,
          };
        }).toList(),
      );
}
