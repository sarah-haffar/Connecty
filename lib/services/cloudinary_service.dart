// Fichier: lib/services/cloudinary_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static final String apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
  static final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;
  static final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;
  static final String uploadPresetRaw = dotenv.env['CLOUDINARY_UPLOAD_PRESET_RAW']!;

  // ✅ SOLUTION ULTIME: Upload signé avec accès public forcé
  static Future<String?> uploadFile(XFile file, String fileType) async {
    try {
      print('📤 Début upload Cloudinary: ${file.name} (type: $fileType)');

      // Déterminer le resource_type
      String resourceType = 'auto';
      if (fileType == 'pdf') {
        resourceType = 'raw';
      } else if (fileType == 'video') {
        resourceType = 'video';
      } else if (fileType == 'image') {
        resourceType = 'image';
      }

      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
      print('🔗 URL d\'upload: $url');

      // ✅ Créer une signature pour forcer l'accès public
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final folder = 'connecty_posts';

      // Paramètres à signer
      final paramsToSign = 'folder=$folder&timestamp=$timestamp&type=upload$apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();

      print('🔐 Signature générée');
      print('⏰ Timestamp: $timestamp');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // ✅ Paramètres signés (plus sécurisé et force l'accès public)
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;
      request.fields['type'] = 'upload'; // Type = upload (public par défaut)

      // Pour les PDFs
      if (fileType == 'pdf') {
        request.fields['resource_type'] = 'raw';
      }

      // Ajouter le fichier
      final fileStream = http.ByteStream(Stream.castFrom(file.openRead()));
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.name,
      );

      request.files.add(multipartFile);

      print('📤 Envoi de la requête signée...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: l\'upload a pris trop de temps');
        },
      );

      final responseData = await streamedResponse.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      print('📡 Réponse Cloudinary: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final fileUrl = jsonResponse['secure_url'] as String;
        final publicId = jsonResponse['public_id'] as String;
        final type = jsonResponse['type'] ?? 'unknown';

        print('✅ Upload réussi!');
        print('📝 URL: $fileUrl');
        print('📝 Public ID: $publicId');
        print('📝 Type: $type');
        print('📝 Format: ${jsonResponse['format']}');
        print('📝 Resource Type: ${jsonResponse['resource_type']}');

        // ✅ Vérifier que le type est bien "upload" (public)
        if (type != 'upload') {
          print('⚠️ ATTENTION: Type inattendu: $type');
        }

        // ✅ Tester immédiatement l'URL
        final isAccessible = await _testFileAccess(fileUrl);
        if (!isAccessible) {
          print('❌ Fichier uploadé mais non accessible!');
          // Retourner quand même l'URL pour débogage
        }

        return fileUrl;
      } else {
        print('❌ Erreur Cloudinary (${streamedResponse.statusCode}):');
        print('❌ Réponse: $responseData');

        if (jsonResponse['error'] != null) {
          print('❌ Message d\'erreur: ${jsonResponse['error']['message']}');
        }

        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception Cloudinary: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // ✅ Tester l'accès au fichier uploadé
  static Future<bool> _testFileAccess(String url) async {
    try {
      print('🧪 Test d\'accès au fichier...');

      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        print('✅ Fichier accessible publiquement!');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ ERREUR 401: Fichier non accessible (pas public)');
        print('⚠️ Le fichier nécessite une authentification');
        return false;
      } else {
        print('⚠️ Status inattendu: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur test d\'accès: $e');
      return false;
    }
  }

  // ✅ Méthode pour tester une URL existante
  static Future<bool> testPdfUrl(String url) async {
    try {
      print('🧪 Test de l\'URL PDF: $url');

      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      print('📡 Status code: ${response.statusCode}');
      print('📄 Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 401) {
        print('❌ ERREUR 401: Le fichier nécessite une authentification');
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur test URL: $e');
      return false;
    }
  }

  // Méthode simplifiée pour les tests
  static Future<String?> uploadImageSimple(XFile image) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['access_mode'] = 'public'; // ✅ Forcer public

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  // ✅ Suppression avec gestion du resource_type
  static Future<bool> deleteFile(String fileUrl, {String? resourceType}) async {
    try {
      print('🗑️ Tentative de suppression: $fileUrl');

      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        print('❌ URL Cloudinary invalide');
        return false;
      }

      String publicId = pathSegments.sublist(1).join('/');
      publicId = publicId.replaceFirst(RegExp(r'\.[^/.]+$'), '');

      print('🔍 Public ID extrait: $publicId');

      // Déterminer le resource_type
      String type = resourceType ?? 'image';
      if (fileUrl.contains('/raw/upload/')) {
        type = 'raw';
      } else if (fileUrl.contains('/video/upload/')) {
        type = 'video';
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final String toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$type/destroy';

      final response = await http.post(
        Uri.parse(deleteUrl),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      print('📡 Réponse suppression: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['result'] == 'ok') {
          print('✅ Fichier supprimé de Cloudinary: $publicId');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de la suppression Cloudinary: $e');
      return false;
    }
  }

  static Future<bool> deleteFileSimple(String fileUrl) async {
    try {
      print('🗑️ Suppression simple: $fileUrl');

      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        return false;
      }

      String publicId = pathSegments.sublist(1).join('/');
      publicId = publicId.replaceFirst(RegExp(r'\.[^/.]+$'), '');

      // Déterminer le resource_type
      String type = 'image';
      if (fileUrl.contains('/raw/upload/')) {
        type = 'raw';
      } else if (fileUrl.contains('/video/upload/')) {
        type = 'video';
      }

      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$type/destroy';

      final response = await http.post(
        Uri.parse(deleteUrl),
        body: {
          'public_id': publicId,
          'upload_preset': uploadPreset,
        },
      );

      print('📡 Réponse suppression simple: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('❌ Erreur suppression simple: $e');
      return false;
    }
  }
}