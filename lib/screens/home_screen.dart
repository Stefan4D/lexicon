import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lexicon/services/word_frequency_analyser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Home Page"),
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
