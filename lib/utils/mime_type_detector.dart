import 'package:mime/mime.dart';

class MimeTypeDetector {
  static String getMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType ?? 'application/octet-stream';
  }
}
