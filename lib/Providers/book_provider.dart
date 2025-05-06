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

      if (response.isEmpty) {
        state = [];
        return;
      }
      final jsonResponse = jsonDecode(response) as Map<String, dynamic>;

      final Map<String, dynamic> jsonData = json.decode(response);
      final List<dynamic> products = jsonResponse['products'] ?? [];
      console([products]);
      final List<Book> books =
          products.map((json) => Book.fromJson(json)).toList();

      state = books;
    } catch (e) {
      state = [];
    }
  }
}
