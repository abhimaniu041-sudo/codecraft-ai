import 'package:flutter/material.dart';
import '../models/video_models.dart';

class TimelineEngine extends ChangeNotifier {
  List<StoryScene> scenes = [];
  int currentSceneIndex = 0;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  double _sceneElapsed = 0.0;

  StoryScene? get currentScene =>
      scenes.isNotEmpty && currentSceneIndex < scenes.length
          ? scenes[currentSceneIndex]
          : null;

  double get sceneProgress {
    final scene = currentScene;
    if (scene == null) return 0.0;
    return (_sceneElapsed / scene.durationSeconds).clamp(0.0, 1.0);
  }

  double get totalProgress {
    if (scenes.isEmpty) return 0.0;
    double total = scenes.fold(0.0, (s, sc) => s + sc.durationSeconds);
    double elapsed = 0.0;
    for (int i = 0; i < currentSceneIndex; i++) {
      elapsed += scenes[i].durationSeconds;
    }
    elapsed += _sceneElapsed;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  void tick(double dt) {
    if (!isPlaying || scenes.isEmpty) return;
    _sceneElapsed += dt * playbackSpeed;
    final scene = currentScene;
    if (scene != null && _sceneElapsed >= scene.durationSeconds) {
      _sceneElapsed = 0;
      if (currentSceneIndex < scenes.length - 1) {
        currentSceneIndex++;
        notifyListeners();
      } else {
        isPlaying = false;
        currentSceneIndex = 0;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  void play() {
    isPlaying = true;
    notifyListeners();
  }

  void pause() {
    isPlaying = false;
    notifyListeners();
  }

  void stop() {
    isPlaying = false;
    currentSceneIndex = 0;
    _sceneElapsed = 0;
    notifyListeners();
  }

  void jumpToScene(int index) {
    if (scenes.isEmpty) return;
    currentSceneIndex = index.clamp(0, scenes.length - 1);
    _sceneElapsed = 0;
    notifyListeners();
  }

  void nextScene() {
    if (currentSceneIndex < scenes.length - 1) {
      currentSceneIndex++;
      _sceneElapsed = 0;
      notifyListeners();
    }
  }

  void prevScene() {
    if (currentSceneIndex > 0) {
      currentSceneIndex--;
      _sceneElapsed = 0;
      notifyListeners();
    }
  }

  void addScene(StoryScene scene) {
    scenes.add(scene);
    notifyListeners();
  }

  void removeScene(int index) {
    if (index < 0 || index >= scenes.length) return;
    scenes.removeAt(index);
    if (currentSceneIndex >= scenes.length) {
      currentSceneIndex = scenes.isEmpty ? 0 : scenes.length - 1;
    }
    notifyListeners();
  }

  void updateScene(int index, StoryScene scene) {
    if (index < 0 || index >= scenes.length) return;
    scenes[index] = scene;
    notifyListeners();
  }

  void reorderScenes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final scene = scenes.removeAt(oldIndex);
    scenes.insert(newIndex, scene);
    notifyListeners();
  }
}
