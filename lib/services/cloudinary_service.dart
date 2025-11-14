// Fichier: lib/services/cloudinary_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static final String apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
  static final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;
  static final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;
  static final String uploadPresetRaw = dotenv.env['CLOUDINARY_UPLOAD_PRESET_RAW']!;

  // ------------------- UPLOAD SIGNÉ -------------------
  static Future<String?> uploadFile(XFile file, String fileType) async {
    try {
      print('📤 Début upload Cloudinary: ${file.name} (type: $fileType)');

      // Upload vidéo avec Dio séparé pour éviter le timeout
      if (fileType == 'video') {
        return await _uploadVideoWithDio(file);
      }

      final resourceType = _getResourceType(fileType);
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final folder = 'connecty_posts';
      final signature = _generateSignature(folder, timestamp);

      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields.addAll({
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'folder': folder,
          'type': 'upload',
          if (fileType == 'pdf') 'resource_type': 'raw',
        })
        ..files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.name));

      print('📤 Envoi de la requête signée...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout: l\'upload a pris trop de temps'),
      );

      final responseData = await streamedResponse.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (streamedResponse.statusCode == 200) {
        final fileUrl = jsonResponse['secure_url'] as String;
        print('✅ Upload réussi! URL: $fileUrl');

        final isAccessible = await _testFileAccess(fileUrl);
        if (!isAccessible) print('❌ Fichier uploadé mais non accessible!');

        return fileUrl;
      } else {
        print('❌ Erreur Cloudinary (${streamedResponse.statusCode}): $responseData');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception Cloudinary: $e');
      print(stackTrace);
      return null;
    }
  }

  // ------------------- VIDEO UPLOAD DIO -------------------
  static Future<String?> _uploadVideoWithDio(XFile file) async {
    final url = "https://api.cloudinary.com/v1_1/$cloudName/video/upload";
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: file.name),
      "upload_preset": uploadPreset,
      "resource_type": "video",
    });

    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(minutes: 5)
        ..options.receiveTimeout = const Duration(minutes: 5);

      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        print('✅ Upload vidéo réussi: ${response.data["secure_url"]}');
        return response.data["secure_url"];
      } else {
        print("❌ Erreur Cloudinary (video): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Erreur Dio (video): $e");
      return null;
    }
  }

  // ------------------- UPLOAD SIMPLE -------------------
  static Future<String?> uploadImageSimple(XFile image) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = uploadPreset
        ..fields['access_mode'] = 'public' // Forcer public
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) return jsonResponse['secure_url'];
      return null;
    } catch (e) {
      print('❌ Erreur upload image simple: $e');
      return null;
    }
  }

  // ------------------- TEST D’ACCÈS -------------------
  static Future<bool> _testFileAccess(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) print('❌ Fichier non accessible (pas public)');
      return false;
    } catch (e) {
      print('❌ Erreur test d\'accès: $e');
      return false;
    }
  }

  static Future<bool> testPdfUrl(String url) => _testFileAccess(url);

  // ------------------- DELETE -------------------
  static Future<bool> deleteFile(String fileUrl, {String? resourceType}) async {
    try {
      final publicId = _extractPublicId(fileUrl);
      final type = resourceType ?? _determineType(fileUrl);
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final signature = sha1.convert(utf8.encode('public_id=$publicId&timestamp=$timestamp$apiSecret')).toString();

      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$type/destroy';
      final response = await http.post(Uri.parse(deleteUrl), body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      if (response.statusCode == 200 && jsonDecode(response.body)['result'] == 'ok') {
        print('✅ Fichier supprimé: $publicId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  static Future<bool> deleteFileSimple(String fileUrl) async {
    try {
      final publicId = _extractPublicId(fileUrl);
      final type = _determineType(fileUrl);
      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$type/destroy';

      final response = await http.post(Uri.parse(deleteUrl), body: {
        'public_id': publicId,
        'upload_preset': uploadPreset,
      });

      if (response.statusCode == 200 && jsonDecode(response.body)['result'] == 'ok') {
        print('✅ Fichier supprimé (simple): $publicId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur suppression simple: $e');
      return false;
    }
  }

  // ------------------- UTILITAIRES -------------------
  static String _getResourceType(String fileType) {
    switch (fileType) {
      case 'pdf':
        return 'raw';
      case 'image':
        return 'image';
      default:
        return 'auto';
    }
  }

  static String _generateSignature(String folder, String timestamp) {
    final paramsToSign = 'folder=$folder&timestamp=$timestamp&type=upload$apiSecret';
    return sha1.convert(utf8.encode(paramsToSign)).toString();
  }

  static String _extractPublicId(String fileUrl) {
    var segments = Uri.parse(fileUrl).pathSegments;
    return segments.sublist(1).join('/').replaceFirst(RegExp(r'\.[^/.]+$'), '');
  }

  static String _determineType(String fileUrl) {
    if (fileUrl.contains('/raw/upload/')) return 'raw';
    if (fileUrl.contains('/video/upload/')) return 'video';
    return 'image';
  }
}
