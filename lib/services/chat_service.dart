import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  // Génère un ID unique pour le chat entre 2 utilisateurs
  static String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Envoyer un message
  static Future<void> sendMessage(String friendId, String text) async {
    if (currentUser == null || text.trim().isEmpty) return;

    final chatId = getChatId(currentUser!.uid, friendId);

    await _db
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': currentUser!.uid,
      'receiverId': friendId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  // Lire les messages d’un chat
  static Stream<QuerySnapshot> getMessages(String friendId) {
    final chatId = getChatId(currentUser!.uid, friendId);
    return _db
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Liste des discussions (dernier message par ami)
  static Stream<List<Map<String, dynamic>>> getChatPreviews() async* {
    if (currentUser == null) yield [];

    final friendsSnapshot = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .get();

    final List<Map<String, dynamic>> previews = [];

    for (var friend in friendsSnapshot.docs) {
      final friendId = friend.id;
      final friendData = friend.data();
      final chatId = getChatId(currentUser!.uid, friendId);

      final lastMsgSnap = await _db
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMsgSnap.docs.isNotEmpty) {
        final msg = lastMsgSnap.docs.first.data();
        previews.add({
          'friendId': friendId,
          'friendName': friendData['friendName'] ?? 'Ami',
          'lastMessage': msg['text'] ?? '',
          'timestamp': msg['timestamp'],
          'unseenCount': 0, // À implémenter plus tard
        });
      }
    }

    // Trier par date du dernier message
    previews.sort((a, b) {
      final timeA = a['timestamp'] ?? Timestamp.now();
      final timeB = b['timestamp'] ?? Timestamp.now();
      return timeB.compareTo(timeA);
    });

    yield previews;
  }
}