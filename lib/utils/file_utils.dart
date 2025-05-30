import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'; // Required for BuildContext if we show Snackbars from here

// A result class to hold file path and content
class PickedFileResult {
  final String path;
  final String name;
  String? content; // Content might not always be read by the picker utility

  PickedFileResult({required this.path, required this.name, this.content});
}

Future<PickedFileResult?> pickFile({
  required BuildContext context, // To show Snackbars or other UI feedback
  required List<String> allowedExtensions,
  bool readBytes =
      false, // If true, reads as bytes; otherwise, tries to read as string
}) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: readBytes, // If true, reads bytes into memory immediately
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      if (readBytes) {
        // If bytes were read by the picker (withData: true)
        // For now, we are not directly using the bytes here, but this is how you'd get them
        // Uint8List? fileBytes = result.files.single.bytes;
        // And then you might convert to string if appropriate or pass bytes along
        // For simplicity, we'll re-read as string if not reading bytes directly.
        // This part needs refinement based on how we handle different file types (binary vs text)
      }

      // For non-binary files or if not reading bytes directly with picker
      // We will read content as string here. For binary files like .docx, this will be handled differently later.
      String? fileContent;
      // For now, only attempt to read content for .txt and .md as they are plain text
      // .docx and .scrivx will need specialized parsing later
      final extension = fileName.split('.').last.toLowerCase();
      if (['txt', 'md'].contains(extension)) {
        try {
          fileContent = await File(filePath).readAsString();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reading file content: $e')),
          );
          return null; // Don't proceed if content reading fails for text files
        }
      }

      return PickedFileResult(
        path: filePath,
        name: fileName,
        content: fileContent,
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File picking cancelled.')));
      return null;
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    return null;
  }
}
