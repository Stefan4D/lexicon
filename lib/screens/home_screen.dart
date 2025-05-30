import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/main.dart'; // Import main.dart to access selectedNavIndexProvider
import 'package:lexicon/services/project_import_service.dart';
import 'package:lexicon/utils/file_utils.dart';

class HomeScreen extends ConsumerWidget {
  // Changed to ConsumerWidget
  const HomeScreen({super.key});

  Future<void> _handlePickFileAndNavigate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pickedFileResult = await pickFile(
      context: context,
      allowedExtensions: ['txt', 'md', 'docx', 'scrivx'],
    );

    if (pickedFileResult != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Importing project...')));

      try {
        final importService = await ref.read(
          projectImportServiceProvider.future,
        );
        final newProject = await importService.importProject(pickedFileResult);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (newProject != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Project "${newProject.projectName}" imported successfully!',
              ),
            ),
          );
          // Navigate to AllProjectsScreen (index 1)
          ref.read(selectedNavIndexProvider.notifier).state = 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to import project. Check logs.'),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing project: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed:
                  () => _handlePickFileAndNavigate(
                    context,
                    ref,
                  ), // Pass context and ref
              icon: const Icon(Icons.file_open),
              label: const Text('Import Project & View All'), // Updated label
            ),
          ],
        ),
      ),
    );
  }
}
