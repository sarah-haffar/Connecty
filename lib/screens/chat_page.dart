import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendPhotoUrl;
  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendPhotoUrl,
  });
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String? _replyTo;
  @override
  void initState() {
    super.initState();
    ChatService.markMessagesAsSeen(widget.friendId);
    _controller.addListener(
      () => ChatService.setTyping(widget.friendId, _controller.text.isNotEmpty),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    ChatService.sendMessage(
      friendId: widget.friendId,
      text: _controller.text.trim(),
      replyTo: _replyTo,
    );
    setState(() => _replyTo = null);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _editMessage(Map<String, dynamic> msg) {
    final controller = TextEditingController(text: msg['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le message"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nouveau message"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != msg['text']) {
                ChatService.editMessage(
                  friendId: widget.friendId,
                  messageId: msg['id'],
                  newText: newText,
                );
              }
              Navigator.pop(context);
            },
            child: const Text(
              "Envoyer",
              style: TextStyle(color: Color(0xFF6A1B9A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(
    BuildContext context,
    Map<String, dynamic> msg,
    bool isMe,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_emoticon_outlined),
                title: const Text("Réagir"),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiReaction(msg['id']);
                },
              ),
              if (isMe) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text("Répondre"),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _replyTo = msg['id']);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                  title: const Text("Modifier"),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(msg);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    "Supprimer pour tous",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ChatService.deleteMessage(widget.friendId, msg['id'], true);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiReaction(String messageId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            ChatService.addReaction(widget.friendId, messageId, emoji.emoji);
            Navigator.pop(context);
          },
          config: Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              columns: 8,
              emojiSizeMax:
                  28 *
                  (foundation.defaultTargetPlatform == TargetPlatform.iOS
                      ? 1.2
                      : 1.0),
              verticalSpacing: 0,
              horizontalSpacing: 0,
              backgroundColor: Colors.white,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            categoryViewConfig: CategoryViewConfig(
              indicatorColor: const Color(0xFF6A1B9A),
              iconColorSelected: const Color(0xFF6A1B9A),
              backspaceColor: const Color(0xFF6A1B9A),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.friendPhotoUrl != null
                  ? NetworkImage(widget.friendPhotoUrl!)
                  : null,
              child: widget.friendPhotoUrl == null
                  ? Text(
                      widget.friendName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: ChatService.friendStatus(widget.friendId),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final online = data?['isOnline'] == true;
                      return Text(
                        online ? "En ligne" : "Hors ligne",
                        style: TextStyle(
                          fontSize: 13,
                          color: online ? Colors.green[300] : Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService.getMessages(widget.friendId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                  );
                final docs = snapshot.data!.docs;
                _scrollToBottom();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == me;
                    final reactions =
                        (msg['isDeleted'] == true ||
                            msg['deletedFor_$me'] == true)
                        ? <String, String>{}
                        : (msg['reactions'] as Map<String, dynamic>?)
                                  ?.cast<String, String>() ??
                              {};
                    if (!isMe) ChatService.markMessagesAsSeen(widget.friendId);
                    return Dismissible(
                      key: Key(msg['id']),
                      direction: isMe
                          ? DismissDirection.startToEnd
                          : DismissDirection.none,
                      background: Container(
                        color: const Color(0xFF0088CC),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(
                          Icons.reply,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          setState(() => _replyTo = msg['id']);
                          return false;
                        }
                        return false;
                      },
                      child: GestureDetector(
                        onLongPress: () => _showMessageMenu(context, msg, isMe),
                        child: _WhatsAppMessageBubble(
                          message: msg,
                          isMe: isMe,
                          reactions: reactions,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    color: const Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.reply, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Répondre au message",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(ChatService.chatId(me, widget.friendId))
                .snapshots(),
            builder: (context, snap) {
              final typing =
                  (snap.data?.data()
                      as Map<String, dynamic>?)?['typing_${widget.friendId}'] ==
                  true;
              return typing
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          "en train d’écrire…",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Message",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF6A1B9A),
                  child: const Icon(Icons.send, color: Colors.white),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final Map<String, String> reactions;
  const _WhatsAppMessageBubble({
    required this.message,
    required this.isMe,
    required this.reactions,
  });
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final time = (message['timestamp'] as Timestamp?)?.toDate();
    final timeStr = time != null
        ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
        : "";
    final bool isDeleted =
        message['isDeleted'] == true ||
        (message['deletedFor_$currentUid'] ?? false) == true;
    final String? repliedText = message['repliedText'] as String?;
    final String? repliedSenderId = message['repliedSenderId'] as String?;
    final bool isReplyToMe = repliedSenderId == currentUid;
    final bool isRead = message['isRead'] == true;
    final bool showReactions = reactions.isNotEmpty && !isDeleted;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: repliedText != null ? 16 : 10,
                  bottom: showReactions ? 22 : 16,
                ),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6A1B9A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (repliedText != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.18)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFF6A1B9A),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReplyToMe ? "Toi" : "Réponse à",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.purple[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedText,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black87,
                                fontSize: 13.5,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    Text(
                      isDeleted
                          ? "Ce message a été supprimé"
                          : (message['text'] ?? ''),
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (isDeleted ? Colors.grey[600] : Colors.black87),
                        fontSize: 16,
                        fontStyle: isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (message['isEdited'] == true) ...[
                          const SizedBox(width: 4),
                          Text(
                            "modifié",
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 16,
                            color: isRead ? Colors.cyanAccent : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showReactions)
                Positioned(
                  bottom: -10,
                  left: isMe ? null : 8,
                  right: isMe ? 8 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: reactions.values
                          .take(6)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
