import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:connecty_app/widgets/pdf_view_page.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;
  final Color usernameColor;
  final Color contentColor;
  final String? fileType; // ← AJOUT: 'image', 'pdf', 'video'
  final void Function(Map<String, dynamic> postMap, bool isFavorite)? onFavoriteToggle;

  const PostCard({
    super.key,
    required this.username,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
    this.usernameColor = Colors.black,
    this.contentColor = Colors.black,
    this.fileType, // ← AJOUT
    this.onFavoriteToggle,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool showComments = false;
  bool showLikes = false;
  bool isFavorite = false;

  final List<String> likedUsers = ["Sarah", "Ahmed", "Feriel"];
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color backgroundColor = const Color(0xFFEDE7F6);
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> comments = [];

  bool get isNetworkImage => widget.imageUrl != null && widget.imageUrl!.startsWith('http');

  // ✅ Détection du type de fichier
  bool get isPdfFile => widget.fileType == 'pdf' || (widget.imageUrl?.toLowerCase().contains('.pdf') ?? false);
  bool get isVideoFile => widget.fileType == 'video' || (widget.imageUrl?.toLowerCase().contains('/video/') ?? false);
  bool get isImageFile => widget.fileType == 'image' || (isNetworkImage && !isPdfFile && !isVideoFile);

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

          // ✅ Fichier (Image, PDF ou Vidéo)
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

  // ✅ AFFICHAGE DES FICHIERS
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

  // ✅ CARTE PDF
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
              child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Document PDF",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cliquez pour ouvrir le document",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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

  // ✅ CARTE VIDÉO
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cliquez pour regarder la vidéo",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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

  // ✅ CARTE IMAGE
  Widget _buildImageCard(bool isMobile) {
    return GestureDetector(
      onTap: () => _showImageModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImage(isMobile),
      ),
    );
  }

  // ✅ CARTE FICHIER GÉNÉRIQUE
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
              child: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 30),
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
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
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

  // ✅ OUVRIR PDF - VERSION ULTRA-AMÉLIORÉE
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

    final String cleanUrl = widget.imageUrl!.trim();

    print('📄 === OUVERTURE PDF ===');
    print('URL: $cleanUrl');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewPage(pdfUrl: cleanUrl),
      ),
    );
  }

  // ✅ OUVRIR VIDÉO
  void _openVideo(BuildContext context) async {
    if (widget.imageUrl == null) return;

    try {
      final url = Uri.parse(widget.imageUrl!);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir la vidéo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur ouverture vidéo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ OUVRIR FICHIER GÉNÉRIQUE
  void _openFile(BuildContext context) async {
    if (widget.imageUrl == null) return;

    try {
      final url = Uri.parse(widget.imageUrl!);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir le fichier"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur ouverture fichier: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ EXTRAIRE LE NOM DU FICHIER
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

  // ✅ IMAGE RESPONSIVE
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
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
              Icon(Icons.broken_image, size: isMobile ? 30 : 50, color: Colors.grey),
              const SizedBox(height: 8),
              Text("Image non chargée", style: TextStyle(fontSize: isMobile ? 12 : 14)),
            ],
          ),
        );
      },
    );
  }

  // ✅ BARRE D'ACTIONS RESPONSIVE
  Widget _buildActionBar(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionIcon(Icons.thumb_up, showLikes, () {
          setState(() => showLikes = !showLikes);
        }, isMobile),
        _buildActionIcon(Icons.comment, showComments, () {
          setState(() => showComments = !showComments);
        }, isMobile),
        _buildActionIcon(Icons.share, false, () {}, isMobile),
        _buildActionIcon(
          isFavorite ? Icons.star : Icons.star_border,
          isFavorite,
              () {
            setState(() {
              isFavorite = !isFavorite;
              widget.onFavoriteToggle?.call(
                {
                  "username": widget.username,
                  "content": widget.content,
                  "imageUrl": widget.imageUrl ?? "",
                },
                isFavorite,
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris !'),
              ),
            );
          },
          isMobile,
        ),
      ],
    );
  }

  // ✅ SECTION COMMENTAIRES
  Widget _buildCommentsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Commentaires",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 13 : 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        ...comments.map(
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                  onPressed: () => _editComment(comment),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: isMobile ? 16 : 18),
                  onPressed: () {
                    setState(() {
                      comments.remove(comment);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: TextStyle(color: primaryColor, fontSize: isMobile ? 13 : 14),
                decoration: InputDecoration(
                  hintText: "Ajouter un commentaire...",
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 13 : 14),
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
                if (_commentController.text.isNotEmpty) {
                  setState(() {
                    comments.add({
                      'username': 'Vous',
                      'content': _commentController.text,
                    });
                    _commentController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ✅ SECTION LIKES
  Widget _buildLikesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "J'aime",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 13 : 14,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        ...likedUsers.map(
              (user) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: isMobile ? 14 : 16,
              backgroundColor: primaryColor,
              child: Text(
                user[0],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
            title: Text(
              user,
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ MODAL POUR IMAGES
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
            child: isMobile ? _buildMobileModal(context) : _buildDesktopModal(context),
          ),
        ),
      ),
    );
  }

  // ✅ MODAL MOBILE
  Widget _buildMobileModal(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final bool isMobile = true;
        final TextEditingController _modalCommentController = TextEditingController();
        bool _showLikes = false;
        bool _showComments = true;

        return SingleChildScrollView(
          child: Column(
            children: [
              if (widget.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(true),
                ),
              const SizedBox(height: 12),
              _buildModalContent(_modalCommentController, _showLikes, _showComments, setModalState, context, isMobile),
            ],
          ),
        );
      },
    );
  }

  // ✅ MODAL DESKTOP
  Widget _buildDesktopModal(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final bool isMobile = false;
        final TextEditingController _modalCommentController = TextEditingController();
        bool _showLikes = false;
        bool _showComments = true;

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
              child: _buildModalContent(_modalCommentController, _showLikes, _showComments, setModalState, context, isMobile),
            ),
          ],
        );
      },
    );
  }

  // ✅ CONTENU MODAL
  Widget _buildModalContent(
      TextEditingController controller,
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
        Text(
          widget.content,
          style: TextStyle(fontSize: isMobile ? 13 : 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildActionIcon(Icons.thumb_up, showLikes, () {
              setModalState(() {
                showLikes = !showLikes;
              });
            }, isMobile),
            const SizedBox(width: 20),
            _buildActionIcon(Icons.comment, showComments, () {
              setModalState(() {
                showComments = !showComments;
              });
            }, isMobile),
            const SizedBox(width: 20),
            _buildActionIcon(Icons.share, false, () {}, isMobile),
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
              ...comments.map(
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
                      controller: controller,
                      style: TextStyle(color: primaryColor, fontSize: isMobile ? 13 : 14),
                      decoration: InputDecoration(
                        hintText: "Ajouter un commentaire...",
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 13 : 14),
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
                      if (controller.text.isNotEmpty) {
                        setModalState(() {
                          comments.add({
                            'username': 'Vous',
                            'content': controller.text,
                          });
                          controller.clear();
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

  // ✅ ICÔNE D'ACTION
  Widget _buildActionIcon(IconData icon, bool isActive, VoidCallback onTap, bool isMobile) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: isActive ? primaryColor : Colors.grey[700],
        size: isMobile ? 20 : 22,
      ),
    );
  }

  // ✅ ÉDITER COMMENTAIRE
  void _editComment(Map<String, String> comment) {
    final controller = TextEditingController(text: comment['content']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le commentaire"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Modifier...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                comment['content'] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }
}