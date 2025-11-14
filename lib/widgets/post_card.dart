import 'package:cloud_firestore/cloud_firestore.dart'; // ← IMPORT AJOUTÉ
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:connecty_app/widgets/pdf_view_page.dart';
import 'package:connecty_app/screens/video_player_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/interaction_service.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String username;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;
  final Color usernameColor;
  final Color contentColor;
  final String? fileType;
  final void Function(Map<String, dynamic> postMap, bool isFavorite)?
  onFavoriteToggle;

  const PostCard({
    super.key,
    required this.postId,
    required this.username,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
    this.usernameColor = Colors.black,
    this.contentColor = Colors.black,
    this.fileType,
    this.onFavoriteToggle,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool showComments = false;
  bool showLikes = false;
  bool isFavorite = false;
  bool isLiked = false;

  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color backgroundColor = const Color(0xFFEDE7F6);
  final TextEditingController _commentController = TextEditingController();

  // Variables pour le modal
  final List<Map<String, String>> _modalComments = [];
  final TextEditingController _modalCommentController = TextEditingController();

  bool get isNetworkImage =>
      widget.imageUrl != null && widget.imageUrl!.startsWith('http');
  bool get isPdfFile =>
      widget.fileType == 'pdf' ||
      (widget.imageUrl?.toLowerCase().contains('.pdf') ?? false);
  bool get isVideoFile =>
      widget.fileType == 'video' ||
      (widget.imageUrl?.toLowerCase().contains('/video/') ?? false);
  bool get isImageFile =>
      widget.fileType == 'image' ||
      (isNetworkImage && !isPdfFile && !isVideoFile);

  @override
  void initState() {
    super.initState();
    _checkUserInteractions();
  }

  void _checkUserInteractions() async {
    final liked = await InteractionService.isLikedByUser(widget.postId);
    final favorited = await InteractionService.isFavorite(widget.postId);
    if (mounted) {
      setState(() {
        isLiked = liked;
        isFavorite = favorited;
      });
    }
  }

  // ========== INTERACTIONS ==========
  void _toggleLike() async {
    await InteractionService.toggleLike(widget.postId);
    if (mounted) {
      setState(() {
        isLiked = !isLiked;
      });
    }
  }

  void _toggleFavorite() async {
    await InteractionService.toggleFavorite(widget.postId);
    final newFavoriteState = !isFavorite;
    if (mounted) {
      setState(() {
        isFavorite = newFavoriteState;
      });
    }

    widget.onFavoriteToggle?.call({
      "username": widget.username,
      "content": widget.content,
      "imageUrl": widget.imageUrl ?? "",
      "postId": widget.postId,
    }, newFavoriteState);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newFavoriteState ? 'Ajouté aux favoris !' : 'Retiré des favoris !',
        ),
      ),
    );
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    await InteractionService.addComment(widget.postId, _commentController.text);
    _commentController.clear();
  }

  void _deleteComment(String commentId) async {
    await InteractionService.deleteComment(widget.postId, commentId);
  }

  void _sharePost() async {
    await InteractionService.addShare(widget.postId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post partagé !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ========== BUILD METHOD ==========
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec avatar et username
          Row(
            children: [
              if (widget.profileImageUrl != null)
                CircleAvatar(
                  radius: isMobile ? 16 : 18,
                  backgroundImage: AssetImage(widget.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: isMobile ? 16 : 18,
                  backgroundColor: primaryColor,
                  child: Text(
                    widget.username[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.username,
                  style: TextStyle(
                    color: widget.usernameColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Contenu texte
          Text(
            widget.content,
            style: TextStyle(
              color: widget.contentColor,
              fontSize: isMobile ? 13 : 14,
            ),
          ),

          // Fichier (Image, PDF ou Vidéo)
          if (widget.imageUrl != null) ...[
            const SizedBox(height: 8),
            _buildFileAttachment(isMobile),
          ],

          // Actions
          const SizedBox(height: 8),
          _buildActionBar(isMobile),

          // Section likes
          if (showLikes) _buildLikesSection(isMobile),

          // Section commentaires
          if (showComments) _buildCommentsSection(isMobile),
        ],
      ),
    );
  }

  // ========== MÉTHODES D'AFFICHAGE DES FICHIERS ==========
  Widget _buildFileAttachment(bool isMobile) {
    if (widget.imageUrl == null) return const SizedBox();

    if (isPdfFile) {
      return _buildPdfCard(isMobile);
    } else if (isVideoFile) {
      return _buildVideoCard(isMobile);
    } else if (isImageFile) {
      return _buildImageCard(isMobile);
    } else {
      return _buildGenericFileCard(isMobile);
    }
  }

  Widget _buildPdfCard(bool isMobile) {
    return GestureDetector(
      onTap: () => _openPdf(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Document PDF",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cliquez pour ouvrir le document",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(bool isMobile) {
    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.videocam, color: Colors.purple, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vidéo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cliquez pour regarder la vidéo",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow, color: Colors.purple, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(bool isMobile) {
    return GestureDetector(
      onTap: () => _showImageModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImage(isMobile),
      ),
    );
  }

  Widget _buildGenericFileCard(bool isMobile) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFileName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Cliquez pour ouvrir le fichier",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }

  // ========== MÉTHODES D'OUVERTURE DES FICHIERS ==========
  void _openPdf(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fichier PDF disponible.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewPage(pdfUrl: widget.imageUrl!)),
    );
  }

  void _openVideo(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucune vidéo disponible"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoUrl: widget.imageUrl!, title: ''),
      ),
    );
  }


  void _openFile(BuildContext context) async {
    if (widget.imageUrl == null) return;

    try {
      final url = Uri.parse(widget.imageUrl!);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir le fichier"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFileName() {
    if (widget.imageUrl == null) return "Fichier";

    final uri = Uri.parse(widget.imageUrl!);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      String fileName = pathSegments.last;
      if (fileName.length > 20) {
        fileName = '${fileName.substring(0, 17)}...';
      }
      return fileName;
    }
    return "Document";
  }

  Widget _buildImage(bool isMobile) {
    if (widget.imageUrl == null) return const SizedBox();

    return Image.network(
      widget.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: isMobile ? 180 : 250,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: isMobile ? 180 : 250,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: isMobile ? 180 : 250,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: isMobile ? 30 : 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                "Image non chargée",
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== BARRE D'ACTIONS ==========
  Widget _buildActionBar(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // LIKE
        StreamBuilder<int>(
          stream: InteractionService.getLikesCount(widget.postId),
          builder: (context, snapshot) {
            final likesCount = snapshot.data ?? 0;
            return _buildActionIcon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
              'J\'aime ($likesCount)',
              _toggleLike,
              isLiked ? primaryColor : Colors.grey[700]!,
              isMobile,
            );
          },
        ),

        // COMMENTAIRES
        StreamBuilder<QuerySnapshot>(
          stream: InteractionService.getComments(widget.postId),
          builder: (context, snapshot) {
            final commentsCount = snapshot.data?.docs.length ?? 0;
            return _buildActionIcon(
              Icons.comment,
              'Commenter ($commentsCount)',
              () => setState(() => showComments = !showComments),
              showComments ? primaryColor : Colors.grey[700]!,
              isMobile,
            );
          },
        ),

        // PARTAGE
        StreamBuilder<int>(
          stream: InteractionService.getSharesCount(widget.postId),
          builder: (context, snapshot) {
            final sharesCount = snapshot.data ?? 0;
            return _buildActionIcon(
              Icons.share,
              'Partager ($sharesCount)',
              _sharePost,
              Colors.grey[700]!,
              isMobile,
            );
          },
        ),

        // FAVORI
        _buildActionIcon(
          isFavorite ? Icons.star : Icons.star_border,
          'Favori',
          _toggleFavorite,
          isFavorite ? Colors.amber : Colors.grey[700]!,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
    Color color,
    bool isMobile,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: isMobile ? 20 : 22),
        ),
      ),
    );
  }

  // ========== MÉTHODE POUR LES ICÔNES DU MODAL ==========
  Widget _buildModalActionIcon(
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: isActive ? primaryColor : Colors.grey[700],
          size: isMobile ? 20 : 22,
        ),
      ),
    );
  }

  // ========== SECTION COMMENTAIRES ==========
  Widget _buildCommentsSection(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: InteractionService.getComments(widget.postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Commentaires (${comments.length})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),

            // LISTE DES COMMENTAIRES
            ...comments.map((doc) {
              final comment = doc.data() as Map<String, dynamic>;
              final isCurrentUser =
                  comment['userId'] == InteractionService.getCurrentUserId();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: isMobile ? 14 : 16,
                  backgroundColor: primaryColor,
                  child: Text(
                    comment['userName'][0],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                title: Text(
                  comment['userName'],
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  comment['content'],
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.black54,
                  ),
                ),
                trailing: isCurrentUser
                    ? IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: isMobile ? 16 : 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteComment(doc.id),
                      )
                    : null,
              );
            }),

            // CHAMP DE SAISIE
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ajouter un commentaire...",
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, size: isMobile ? 20 : 22),
                  color: primaryColor,
                  onPressed: _addComment,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ========== SECTION LIKES ==========
  Widget _buildLikesSection(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: InteractionService.getLikes(widget.postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final likes = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "J'aime (${likes.length})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            ...likes.take(10).map((doc) {
              final like = doc.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: isMobile ? 14 : 16,
                  backgroundColor: primaryColor,
                  child: Text(
                    like['userName'][0],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                title: Text(
                  like['userName'],
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              );
            }),
            if (likes.length > 10) ...[
              const SizedBox(height: 4),
              Text(
                "Et ${likes.length - 10} autres...",
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ========== MODAL POUR IMAGES ==========
  void _showImageModal(BuildContext context) {
    if (widget.imageUrl == null || !isImageFile) return;

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: isMobile
                ? _buildMobileModal(context)
                : _buildDesktopModal(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileModal(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final bool isMobile = true;
        bool showLikes = false;
        bool showComments = true;

        return SingleChildScrollView(
          child: Column(
            children: [
              if (widget.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(true),
                ),
              const SizedBox(height: 12),
              _buildModalContent(
                showLikes,
                showComments,
                setModalState,
                context,
                isMobile,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopModal(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final bool isMobile = false;
        bool showLikes = false;
        bool showComments = true;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(false),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModalContent(
                showLikes,
                showComments,
                setModalState,
                context,
                isMobile,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalContent(
    bool showLikes,
    bool showComments,
    Function(void Function()) setModalState,
    BuildContext context,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.profileImageUrl != null)
              CircleAvatar(
                radius: isMobile ? 16 : 18,
                backgroundImage: AssetImage(widget.profileImageUrl!),
              )
            else
              CircleAvatar(
                radius: isMobile ? 16 : 18,
                backgroundColor: primaryColor,
                child: Text(
                  widget.username[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(width: 10),
            Text(
              widget.username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(widget.content, style: TextStyle(fontSize: isMobile ? 13 : 14)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildModalActionIcon(Icons.thumb_up, showLikes, () {
              setModalState(() {
                showLikes = !showLikes;
              });
            }, isMobile),
            const SizedBox(width: 20),
            _buildModalActionIcon(Icons.comment, showComments, () {
              setModalState(() {
                showComments = !showComments;
              });
            }, isMobile),
            const SizedBox(width: 20),
            _buildModalActionIcon(Icons.share, false, _sharePost, isMobile),
          ],
        ),
        const SizedBox(height: 12),
        if (showComments)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Commentaires",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              ..._modalComments.map(
                (comment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: isMobile ? 14 : 16,
                    backgroundColor: primaryColor,
                    child: Text(
                      comment['username']![0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ),
                  title: Text(
                    comment['username']!,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    comment['content']!,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modalCommentController,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ajouter un commentaire...",
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 13 : 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, size: isMobile ? 20 : 22),
                    color: primaryColor,
                    onPressed: () {
                      if (_modalCommentController.text.isNotEmpty) {
                        setModalState(() {
                          _modalComments.add({
                            'username': 'Vous',
                            'content': _modalCommentController.text,
                          });
                          _modalCommentController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ),
      ],
    );
  }
}
