import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Models/book.dart';

class Download {
  Future<void> downloadFile(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      // Check if file already exists
      if (await file.exists()) {
        developer.log('File already exists at: ${file.path}');
        return;
      }

      developer.log('Starting download from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        developer.log('File downloaded successfully to: ${file.path}');
      } else {
        developer.log(
            'Failed to download file. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to download file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      throw Exception('Error downloading file: $e');
    }
  }

  Future<void> downloadBookAssets(List<Book> books, String userEmail) async {
    try {
      for (final book in books) {
        developer.log('Processing book: ${book.name}');
        final isFree = book.price == 0;
        final isPurchased = book.purchased.contains(userEmail);

        if (isFree || isPurchased) {
          // developer.log('Downloading assets for book: ${book.name}');

          // Download PDF
          if (book.pdfFile.url.isNotEmpty) {
            // developer.log('Downloading PDF from: ${book.pdfFile.url}');

            await downloadFile(book.pdfFile.url, '${book.id}.pdf');
          }

          // Download animation
          if (book.animationUrl.isNotEmpty) {
            // developer.log('Downloading animation from: ${book.animationUrl}');
            await downloadFile(book.animationUrl, '${book.id}_animation.mp4');
          }

          // Download audio files
          for (final audio in book.audioFiles) {
            if (audio.url.isNotEmpty) {
              // developer.log('Downloading audio from: ${audio.url}');
              await downloadFile(audio.url, '${book.id}_${audio.name}.mp3');
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error in downloadBookAssets: $e');
      throw Exception('Error downloading book assets: $e');
    }
  }
}
