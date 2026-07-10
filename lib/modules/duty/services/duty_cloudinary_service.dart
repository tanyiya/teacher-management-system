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

  // `dotenv.env` throws if `dotenv.load()` hasn't run yet, and that throw
  // was happening OUTSIDE this class's try/catch (in the emptiness check
  // below), which propagated all the way up through an un-guarded `await`
  // in the calling widgets and left their "uploading" spinner stuck
  // forever since the code that resets it never ran. `dotenv.isInitialized`
  // lets us check safely instead of relying on the throw.
  static String get _cloudName {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  }

  static String get _uploadPreset {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  }

  static String get apiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  }

  static String get apiSecret {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  }

  /// Uploads a task-completion proof photo and returns its secure URL, or
  /// `null` if the upload failed (including missing `.env` config).
  static Future<String?> uploadTaskProof(
    List<int> fileBytes,
    String fileName, {
    String folder = 'duty-task-proofs',
  }) async {
    try {
      final cloudName = _cloudName;
      final uploadPreset = _uploadPreset;
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        return null;
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
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