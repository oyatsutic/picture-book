import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Models/book.dart';

class Download {
  Future<bool> isDownloaded(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      // Check if file exists and has content
      if (await file.exists()) {
        final fileSize = await file.length();
        return fileSize > 0; // Return true only if file exists and has content
      }
      return false;
    } catch (e) {
      developer.log('Error checking if file exists: $e');
      return false;
    }
  }

  Future<void> downloadFile(String url, String filename,
      {Function(double)? onProgress}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      // Check if file already exists
      if (await file.exists()) {
        developer.log('File already exists at: ${file.path}');
        return;
      }

      developer.log('Starting download from: $url');
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = file.openWrite();
        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0 && onProgress != null) {
              final progress = receivedBytes / totalBytes;
              onProgress(progress);
            }
          },
          onDone: () async {
            await sink.close();
            developer.log('File downloaded successfully to: ${file.path}');
          },
          onError: (error) {
            sink.close();
            throw Exception('Error downloading file: $error');
          },
        ).asFuture();
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

  Future<void> downloadBook(Book book, String userEmail,
      {Function(double)? onProgress}) async {
    try {
      // Download PDF
      if (book.pdfFile.url.isNotEmpty) {
        await downloadFile(book.pdfFile.url, '${book.id}.pdf',
            onProgress: onProgress);
      }
    } catch (e) {
      developer.log('Error in downloadBook: $e');
      throw Exception('Error downloading book: $e');
    }
  }
}
