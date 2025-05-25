import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Services/api.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:picturebook/Services/config.dart';

final booksProvider = StateNotifierProvider<BooksNotifier, List<Book>>((ref) {
  return BooksNotifier();
});

class BooksNotifier extends StateNotifier<List<Book>> {
  BooksNotifier() : super([]);

  Future<void> fetchBooks() async {
    try {
      final response = await Api().getBooks();
      console(['sfasfs']);

      if (response.isEmpty) {
        state = [];
        return;
      }
      final jsonResponse = jsonDecode(response) as Map<String, dynamic>;

      final Map<String, dynamic> jsonData = json.decode(response);
      final List<dynamic> products = jsonResponse['products'] ?? [];
      final List<Book> books =
          products.map((json) => Book.fromJson(json)).toList();
      console([books]);
      // Sort books so that free books (price = 0) appear first
      books.sort((a, b) => a.price.compareTo(b.price));

      state = books;
    } catch (e) {
      state = [];
    }
  }
}
