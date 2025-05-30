import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/main.dart'; // Added for detailPageProvider
import 'package:lexicon/models/project.dart';
import 'package:lexicon/screens/project_screen.dart'; // Import the ProjectScreen
import 'package:lexicon/services/project_import_service.dart'; // Import the new service
import 'package:lexicon/services/project_service.dart';
import 'package:lexicon/utils/file_utils.dart'; // Import the new utility

class AllProjectsScreen extends ConsumerWidget {
  const AllProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectServiceAsyncValue = ref.watch(projectServiceProvider);

    return Scaffold(
      backgroundColor:
          Theme.of(
            context,
          ).colorScheme.primaryContainer, // Restored background color
      appBar: AppBar(
        title: const Text('All Projects'),
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainer, // AppBar background
      ),
      body: projectServiceAsyncValue.when(
        data: (projectService) {
          return FutureBuilder<List<Project>>(
            future: projectService.getAllProjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error fetching projects: \${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Display a centered message when the list is empty
                return const Center(
                  child: Text(
                    'No projects yet. Tap the + button to import one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              final projects = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(
                  8.0,
                ), // Add padding around the list
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Card(
                    elevation: 2.0, // Add some elevation to the card
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ), // Add margin
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ), // Padding inside ListTile
                      title: Text(
                        project.projectName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // subtitle: Text('Word Count: \${project.wordCount}'), // Example: Display word count
                      trailing: const Icon(
                        Icons.chevron_right,
                      ), // Indicate tappable
                      onTap: () {
                        // Set the detail page to ProjectScreen
                        ref
                            .read(detailPageProvider.notifier)
                            .state = ProjectScreen(
                          initialProject: project,
                        ); // Changed project to initialProject
                        // We are not changing selectedNavIndexProvider here, so the nav rail selection will remain on "All Projects".
                        // This is usually fine, as the detail view overlays or replaces the main content area for the selected nav item.
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                Center(child: Text('Error loading ProjectService: \$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final pickedFileResult = await pickFile(
            context: context,
            allowedExtensions: ['txt', 'md', 'docx', 'scrivx'],
          );

          if (pickedFileResult != null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Importing project...')),
            );

            try {
              final importService = await ref.read(
                projectImportServiceProvider.future,
              );
              final newProject = await importService.importProject(
                pickedFileResult,
              );

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (newProject != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Project "${newProject.projectName}" imported successfully!', // Removed unnecessary escapes
                    ),
                  ),
                );
                // Refresh the project list
                ref.invalidate(projectServiceProvider);
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error importing project: \$e')),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Import Project'),
        tooltip: 'Import New Project',
      ),
    );
  }
}
