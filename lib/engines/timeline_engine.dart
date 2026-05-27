import 'package:flutter/material.dart';
import 'scene_engine.dart';
import 'character_engine.dart';

class TimelineEvent {
  final double timeSeconds;
  final String type; // 'character_state', 'effect', 'camera', 'dialogue'
  final Map<String, dynamic> data;

  const TimelineEvent({
    required this.timeSeconds,
    required this.type,
    required this.data,
  });
}

class TimelineEngine extends ChangeNotifier {
  List<StoryScene> scenes = [];
  int currentSceneIndex = 0;
  double currentTime = 0;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  double _sceneElapsed = 0;

  StoryScene? get currentScene =>
      scenes.isNotEmpty && currentSceneIndex < scenes.length
          ? scenes[currentSceneIndex]
          : null;

  double get sceneProgress {
    final scene = currentScene;
    if (scene == null) return 0;
    return (_sceneElapsed / scene.durationSeconds).clamp(0, 1);
  }

  double get totalDuration =>
      scenes.fold(0, (sum, s) => sum + s.durationSeconds);

  void tick(double dt) {
    if (!isPlaying || scenes.isEmpty) return;

    _sceneElapsed += dt * playbackSpeed;
    currentTime += dt * playbackSpeed;

    final scene = currentScene;
    if (scene != null && _sceneElapsed >= scene.durationSeconds) {
      _sceneElapsed = 0;
      if (currentSceneIndex < scenes.length - 1) {
        currentSceneIndex++;
        notifyListeners();
      } else {
        isPlaying = false;
        currentSceneIndex = 0;
        currentTime = 0;
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
    currentTime = 0;
    _sceneElapsed = 0;
    notifyListeners();
  }

  void jumpToScene(int index) {
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
    scenes.removeAt(index);
    if (currentSceneIndex >= scenes.length) {
      currentSceneIndex = (scenes.length - 1).clamp(0, scenes.length);
    }
    notifyListeners();
  }

  void updateScene(int index, StoryScene scene) {
    scenes[index] = scene;
    notifyListeners();
  }
}
