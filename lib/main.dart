import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lexicon/services/word_frequency_analyser.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const LexiconApp());
}

class LexiconApp extends StatelessWidget {
  const LexiconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexicon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const HomeScreen(title: 'Lexicon Home Page'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fileContent;
  Map<String, int> _frequencyCount = {};
  List<MapEntry<String, int>> _topNWords = [];

  // Method to pick a file and read its content
  Future<void> _pickFile() async {
    // Show file picker dialog and get the file path
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      // Get the file path and read it
      String filePath = result.files.single.path!;
      File file = File(filePath);
      String fileContent = await file.readAsString();

      // Process the content using WordFrequencyAnalyser
      setState(() {
        _fileContent = fileContent;
        _frequencyCount = WordFrequencyAnalyser.countWordFrequency(fileContent);
        _topNWords = WordFrequencyAnalyser.getTopNWords(_frequencyCount, 5);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final String testString =
    //     'Hello, Lexicon! Do you like bananas? I like bananas. I like apples too. Do you like apples? One thing I will never get over is how much I like bananas. Bananas are the best fruit. Apples are good too, but bananas are better.';

    // Map<String, int> frequencyCount = WordFrequencyAnalyser.countWordFrequency(
    //   testString,
    // );

    // var topNWords = WordFrequencyAnalyser.getTopNWords(frequencyCount, 5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // const Text('This is the Home screen'),
            // // Need to refactor this to use a ListView or similar widget so it is scrollable
            // // for (var entry in frequencyCount.entries)
            // //   Text('${entry.key}: ${entry.value}'),
            // // const SizedBox(height: 20),
            // const Text(
            //   'Top 5 words:',
            //   style: TextStyle(fontWeight: FontWeight.bold),
            // ),
            // for (var entry in topNWords) Text('${entry.key}: ${entry.value}'),
            // const SizedBox(height: 20),
            // Display the file content if available
            if (_fileContent != null) Text('File content:\n$_fileContent\n\n'),

            // Display the word frequency count
            // if (_frequencyCount.isNotEmpty)
            //   ..._frequencyCount.entries.map(
            //     (entry) => Text('${entry.key}: ${entry.value}'),
            //   ),
            if (_topNWords.isNotEmpty)
              const Text(
                'Top 5 words:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            for (var entry in _topNWords) Text('${entry.key}: ${entry.value}'),

            SizedBox(height: 20),

            // Button to pick a file
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Pick a .txt File'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllProjectsScreen extends StatelessWidget {
  const AllProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
