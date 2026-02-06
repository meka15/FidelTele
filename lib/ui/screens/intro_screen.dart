import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onDone;
  const IntroScreen({super.key, required this.onDone});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _page = 0;

  final List<_IntroPage> _pages = const [
    _IntroPage(
      title: 'Welcome to FidelTele',
      description: 'Track your mobile usage, balances, and plans with ease.',
      image: Icons.phone_android,
    ),
    _IntroPage(
      title: 'All your package information',
      description: 'Make sure your text language is English.',
      image: Icons.dashboard,
    ),
    _IntroPage(
      title: 'Make sure you accept message read access',
      description: 'Get alerts before your plans expire and never run out.',
      image: Icons.notifications_active,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(page.image, size: 120, color: colorScheme.primary),
                const SizedBox(height: 40),
                Text(
                  page.title,
                  style: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  page.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage {
  final String title;
  final String description;
  final IconData image;
  const _IntroPage({required this.title, required this.description, required this.image});
}
