import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Uploads duty task-completion proof photos to Cloudinary.
///
/// Same unsigned upload-preset flow as the teachers module's
/// `CloudinaryService`, but sourced from `.env` (`CLOUDINARY_CLOUD_NAME`,
/// `CLOUDINARY_UPLOAD_PRESET`) instead of hardcoded constants, per the
/// values already configured in the project's `.env`.
///
/// `CLOUDINARY_API_KEY`/`CLOUDINARY_API_SECRET` aren't needed for this
/// unsigned preset-based upload (only relevant for signed operations, e.g.
/// deleting a photo later), but are exposed here in case that's needed
/// down the line.
class DutyCloudinaryService {
  DutyCloudinaryService._();

  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  /// Uploads a task-completion proof photo and returns its secure URL, or
  /// `null` if the upload failed (including missing `.env` config).
  static Future<String?> uploadTaskProof(
    List<int> fileBytes,
    String fileName, {
    String folder = 'duty-task-proofs',
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}