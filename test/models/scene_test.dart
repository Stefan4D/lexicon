import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/models/scene.dart';

void main() {
  group('Scene Model Tests', () {
    test('toMap() and fromMap() should work correctly', () {
      final originalScene = Scene(
        sceneId: 1,
        chapterId: 201,
        sceneOrder: 1,
        sceneTitle: 'The First Encounter',
      );

      final sceneMap = originalScene.toMap();
      final sceneFromMap = Scene.fromMap(sceneMap);

      expect(sceneFromMap.sceneId, originalScene.sceneId);
      expect(sceneFromMap.chapterId, originalScene.chapterId);
      expect(sceneFromMap.sceneOrder, originalScene.sceneOrder);
      expect(sceneFromMap.sceneTitle, originalScene.sceneTitle);
    });

    test('copyWith should work correctly', () {
      final originalScene = Scene(
        sceneId: 1,
        chapterId: 201,
        sceneOrder: 1,
        sceneTitle: 'Initial Scene',
      );

      final updatedScene = originalScene.copyWith(
        sceneTitle: 'Revised Scene',
        sceneOrder: 2,
      );

      expect(updatedScene.sceneId, originalScene.sceneId);
      expect(updatedScene.chapterId, originalScene.chapterId);
      expect(updatedScene.sceneOrder, 2);
      expect(updatedScene.sceneTitle, 'Revised Scene');
    });
  });
}
