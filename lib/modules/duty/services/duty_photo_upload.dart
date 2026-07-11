// NOTE: adjust this import to match where CloudinaryService actually lives
// in your project (seen working elsewhere, e.g. the reports module, as a
// static `CloudinaryService.uploadFile(bytes, filename, {folder})`).
import '../../../core/services/cloudinary_service.dart';

/// Uploads a duty task-completion proof photo via the shared, already-
/// working `CloudinaryService` (the same one the reports module calls),
/// instead of the earlier duty-specific `.env`-based service. That one
/// technically had the right shape but its config reads (`dotenv.env[...]`)
/// were silently coming back empty -- almost certainly because
/// `dotenv.load()` was never actually called anywhere in `main()`, so every
/// upload short-circuited on the empty-config check and returned null. The
/// shared service sidesteps that entirely since it uses known-good
/// hardcoded constants rather than reading `.env`.
///
/// Generates a unique filename (timestamp + original extension) the same
/// way the reports module does, so two teachers submitting proof around
/// the same time don't collide on a generic camera filename like
/// `IMG_0001.jpg`.
Future<String?> uploadDutyProofPhoto(List<int> fileBytes, String originalFileName) {
  final ext = (originalFileName.split('.').last).toLowerCase();
  final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
  return CloudinaryService.uploadFile(
    fileBytes,
    uniqueName,
    folder: 'duty-task-proofs',
  );
}