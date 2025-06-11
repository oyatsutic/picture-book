import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Services/download.dart';
import 'package:picturebook/Widgets/BookTitle.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiUrl = dotenv.env['API_URL'];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation
    _animationController.forward();

    // Fetch books in parallel
    Future.microtask(() async {
      await ref.read(booksProvider.notifier).fetchBooks();
      final books = ref.read(booksProvider);
      final userEmail = '';
      // await Download().downloadBookAssets(books, userEmail);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background with fade animation
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/background.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Book list with fade and slide animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: books.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SlideTransition(
                        position: _slideAnimation,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              crossAxisCount: 3,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  // Calculate delay based on index
                                  final delay = index * 0.1;
                                  final itemAnimation = Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        delay,
                                        delay + 0.5,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  );

                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 - itemAnimation.value) * 50,
                                    ),
                                    child: Opacity(
                                      opacity: itemAnimation.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: BookTitle(book: book, userEmail: ''),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
