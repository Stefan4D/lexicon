import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexicon/utils/mime_type_detector.dart';

void main() {
  group('MimeTypeDetector', () {
    test('should return correct MIME type for known file extensions', () {
      expect(MimeTypeDetector.getMimeType('test_plan_text.txt'), 'text/plain');
      // expect(MimeTypeDetector.getMimeType('example.jpg'), 'image/jpeg');
      // expect(MimeTypeDetector.getMimeType('example.png'), 'image/png');
      // expect(MimeTypeDetector.getMimeType('example.mp3'), 'audio/mpeg');
      // expect(MimeTypeDetector.getMimeType('example.mp4'), 'video/mp4');
    });

    // test('should return application/octet-stream for unknown file extensions', () {
    //   expect(MimeTypeDetector.getMimeType('example.unknown'), 'application/octet-stream');
    // });

    // test('should return application/octet-stream for files without extension', () {
    //   expect(MimeTypeDetector.getMimeType('example'), 'application/octet-stream');
    // });
  });
}
