import 'dart:io';
import 'package:teacher_management/core/services/cloudinary_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/cloudinary_test.dart <image_path>');
    exit(64);
  }

  final path = args[0];
  final file = File(path);
  if (!await file.exists()) {
    print('File not found: $path');
    exit(66);
  }

  final bytes = await file.readAsBytes();
  final filename = file.uri.pathSegments.isNotEmpty
      ? file.uri.pathSegments.last
      : 'upload.bin';

  print('Uploading $filename to Cloudinary...');
  const folder = 'training_posts/test_cli';

  try {
    final url = await CloudinaryService.uploadFile(bytes, filename, folder: folder);
    if (url != null && url.isNotEmpty) {
      print('Upload succeeded: $url');
      exit(0);
    } else {
      print('Upload failed: received null or empty URL');
      exit(1);
    }
  } catch (e, s) {
    print('Upload threw: $e');
    print(s);
    exit(1);
  }
}
