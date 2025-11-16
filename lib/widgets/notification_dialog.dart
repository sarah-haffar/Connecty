// lib/widgets/notification_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationDialog extends StatefulWidget {
  final int unreadCount;

  const NotificationDialog({super.key, required this.unreadCount});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding: const EdgeInsets.all(24.0),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.0, // Largeur maximale fixe
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHeader(),

            const Divider(height: 1.0, thickness: 1.0),

            const SizedBox(height: 8.0),

            // CONTENU DES NOTIFICATIONS
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisSize:
                MainAxisSize.min, // ← IMPORTANT : Évite le débordement
            children: [
              if (widget.unreadCount > 0)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 150.0, // ← LIMITE LA LARGEUR MAXIMALE
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, // ← RÉDUIT LE PADDING
                        vertical: 8.0,
                      ),
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      NotificationService.markAllAsRead();
                    },
                    child: const Text(
                      "Tout marquer comme lu",
                      style: TextStyle(
                        fontSize: 12.0, // ← RÉDUIT LA TAILLE DE POLICE
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1, // ← GARANTIT 1 SEULE LIGNE
                      overflow:
                          TextOverflow.ellipsis, // ← AJOUTE "..." SI TROP LONG
                    ),
                  ),
                ),
              const SizedBox(width: 8.0), // ← ESPACEMENT FIXE
              Container(
                width: 36.0, // ← TAILLE RÉDUITE
                height: 36.0,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20.0),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final data = notification.data() as Map<String, dynamic>;
            return _buildNotificationItem(data, notification.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64.0, color: Colors.grey),
          SizedBox(height: 16.0),
          Text(
            "Aucune notification",
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> data,
    String notificationId,
  ) {
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Dismissible(
        key: Key(notificationId),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          child: const Icon(Icons.delete, color: Colors.white, size: 24.0),
        ),
        onDismissed: (direction) {
          NotificationService.deleteNotification(notificationId);
        },
        child: Material(
          color: isRead ? Colors.white : const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(12.0),
          elevation: 1.0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            leading: Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: _getNotificationBackgroundColor(type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationIconColor(type),
                size: 20.0,
              ),
            ),
            title: Text(
              data['message'] ?? '',
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                fontSize: 14.0,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(data['timestamp']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
                  ),
                  // Ajouter des boutons d'action pour les demandes d'amitié
                  if (type == 'friend_request' && !isRead)
                    _buildFriendRequestActions(
                      notificationId,
                      data['fromUserId'],
                      data['fromUserName'],
                    ),
                ],
              ),
            ),
            trailing: !isRead && type != 'friend_request'
                ? Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            onTap: () {
              NotificationService.markAsRead(notificationId);
              _handleNotificationTap(type, data);
            },
          ),
        ),
      ),
    );
  }

  // Widget pour les boutons d'action des demandes d'amitié
  Widget _buildFriendRequestActions(
    String notificationId,
    String friendUserId,
    String friendName,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              onPressed: () {
                NotificationService.acceptFriendRequest(
                  notificationId,
                  friendUserId,
                  friendName,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande d\'amitié acceptée')),
                );
              },
              child: const Text(
                'Accepter',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              onPressed: () {
                NotificationService.declineFriendRequest(notificationId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande d\'amitié refusée')),
                );
              },
              child: const Text(
                'Refuser',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationBackgroundColor(String type) {
    switch (type) {
      case 'like':
        return const Color(0xFFE3F2FD);
      case 'comment':
        return const Color(0xFFE8F5E8);
      case 'friend_request':
        return const Color(
          0xFFE8F5E9,
        ); // Vert très clair pour les demandes d'amitié
      case 'friend_request_accepted':
        return const Color(0xFFE0F2F1);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;
      case 'friend_request':
        return Icons.person_add; // Icône pour les demandes d'amitié
      case 'friend_request_accepted':
        return Icons.people; // Icône pour les acceptations
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type) {
      case 'like':
        return const Color(0xFF1976D2);
      case 'comment':
        return const Color(0xFF388E3C);
      case 'friend_request':
        return const Color(0xFF2E7D32); // Vert foncé pour les demandes
      case 'friend_request_accepted':
        return const Color(0xFF00796B); // Turquoise pour les acceptations
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return "À l'instant";
    if (difference.inMinutes < 60) return "Il y a ${difference.inMinutes} min";
    if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
    if (difference.inDays < 7) return "Il y a ${difference.inDays} j";

    return "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
  }

  // Mettez à jour la méthode de navigation
  void _handleNotificationTap(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'like':
      case 'comment':
        _navigateToPost(data['postId']);
        break;
      case 'friend_request':
      case 'friend_request_accepted':
        // Navigation vers le profil de l'utilisateur
        _navigateToProfile(data['fromUserId']);
        break;
      default:
        print('Notification de type inconnu: $type');
    }
  }

  // MÉTHODE AJOUTÉE - Navigation vers le profil utilisateur
  void _navigateToProfile(String userId) {
    print('Navigation vers le profil: $userId');
    // Implémentez la navigation vers le profil utilisateur
    Navigator.pop(context); // Ferme le dialog des notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers le profil: $userId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToPost(String postId) {
    print('Navigation vers le post: $postId');
    // Implémentez la navigation vers le post
    Navigator.pop(context); // Ferme le dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers le post: $postId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
