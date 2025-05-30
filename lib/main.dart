import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lexicon/constants/navigation_items.dart';

// Provider for the selected navigation index
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// Provider for the detail page content
final detailPageProvider = StateProvider<Widget?>((ref) => null);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: LexiconApp()));
}

class LexiconApp extends StatelessWidget {
  const LexiconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexicon',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const BaseCanvas(title: 'Lexicon Home Page'),
    );
  }
}

class BaseCanvas extends ConsumerStatefulWidget {
  const BaseCanvas({super.key, required this.title});

  final String title;

  @override
  ConsumerState<BaseCanvas> createState() => _BaseCanvasState();
}

class _BaseCanvasState extends ConsumerState<BaseCanvas> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final detailPage = ref.watch(detailPageProvider);

    final Widget pageToShow;
    if (detailPage != null) {
      pageToShow = detailPage;
    } else {
      pageToShow = navigationItems[selectedIndex].page;
    }

    final Widget contentPane = ColoredBox(
      color: colorScheme.primaryContainer,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: pageToShow, // Use pageToShow here
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar on narrow screens.
            return Column(
              children: [
                Expanded(child: contentPane),
                SafeArea(
                  child: BottomNavigationBar(
                    items:
                        navigationItems
                            .map(
                              (item) => BottomNavigationBarItem(
                                icon: Icon(item.icon),
                                label: item.label,
                              ),
                            )
                            .toList(),
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      ref.read(detailPageProvider.notifier).state =
                          null; // Clear detail page
                      ref.read(selectedNavIndexProvider.notifier).state = value;
                    },
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations:
                        navigationItems
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      ref.read(detailPageProvider.notifier).state =
                          null; // Clear detail page
                      ref.read(selectedNavIndexProvider.notifier).state = value;
                    },
                  ),
                ),
                Expanded(child: contentPane),
              ],
            );
          }
        },
      ),
    );
  }
}
