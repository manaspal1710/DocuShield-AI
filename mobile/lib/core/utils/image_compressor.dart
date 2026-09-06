import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<File> compressImage(File file, {int maxWidth = 1600, int quality = 85}) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return file;

      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

      final compressedBytes = img.encodeJpg(image, quality: quality);
      
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      // Fallback to original file if compression fails
      return file;
    }
  }
}
