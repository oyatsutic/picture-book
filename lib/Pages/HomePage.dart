import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Pages/Pay/PayPage.dart';
import 'package:picturebook/Providers/book_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch books when the page loads
    Future.microtask(() => ref.read(booksProvider.notifier).fetchBooks());
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PayPage()),
              );
            },
            child: const Text('pay page'),
          ),
          Expanded(
            child: books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return ListTile(
                        title: Text(book.name),
                        subtitle: Text(book.description),
                        // Add more book details as needed
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
