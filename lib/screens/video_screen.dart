import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import '../engines/character_engine.dart';
import '../engines/particle_engine.dart';
import '../engines/scene_engine.dart';
import '../engines/timeline_engine.dart';
import '../services/ai_service.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with TickerProviderStateMixin {
  final TimelineEngine _timeline = TimelineEngine();
  late AnimationController _renderController;
  late AnimationController _cameraController;
  double _cameraShake = 0;
  double _cameraZoom = 1.0;
  double _parallaxOffset = 0;
  double _bgAnimProgress = 0;

  final List<ParticleSystem> _particles = [];
  final TextEditingController _promptCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _isExporting = false;
  bool _showSubtitles = true;
  String _projectName = 'My Story';

  @override
  void initState() {
    super.initState();

    _renderController = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onRenderTick)
      ..repeat();

    _cameraController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _timeline.addListener(() { if (mounted) setState(() {}); });
    _loadProject();
    _addDefaultScene();
  }

  double _lastTime = 0;

  void _onRenderTick() {
    final now = _renderController.value * 86400;
    final dt = (_lastTime > 0) ? (now - _lastTime).clamp(0, 0.05) : 0.016;
    _lastTime = now;

    _timeline.tick(dt);
    _bgAnimProgress = (now * 0.1) % 1.0;

    // Camera effects
    final scene = _timeline.currentScene;
    if (scene != null) {
      switch (scene.cameraEffect) {
        case CameraEffect.shake:
          _cameraShake = math.sin(now * 30) * 6;
          break;
        case CameraEffect.zoomIn:
          _cameraZoom = 1.0 + _timeline.sceneProgress * 0.3;
          break;
        case CameraEffect.zoomOut:
          _cameraZoom = 1.3 - _timeline.sceneProgress * 0.3;
          break;
        case CameraEffect.pan:
          _parallaxOffset = _timeline.sceneProgress * 100;
          break;
        default:
          _cameraShake = 0;
          _cameraZoom = 1.0;
      }
    }

    // Update particles
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => !p.active && p.count == 0);

    if (mounted) setState(() {});
  }

  void _addDefaultScene() {
    if (_timeline.scenes.isEmpty) {
      _timeline.addScene(StoryScene(
        id: DateTime.now().toString(),
        background: BackgroundType.city,
        timeOfDay: TimeOfDay.day,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: CharacterState.idle,
            positionX: 0.35,
            positionY: 0.62,
            dialogue: 'Hero is ready!',
          ),
        ],
        narration: 'The story begins...',
        durationSeconds: 4,
      ));
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final result = await AIService.sendMessage(
        userMessage: '''Create 6 cinematic scenes for: "$prompt"

Return ONLY a valid JSON array like this:
[
  {
    "background": "city",
    "timeOfDay": "day",
    "weather": "none",
    "characters": [
      {
        "characterId": "hero",
        "state": "idle",
        "positionX": 0.3,
        "positionY": 0.62,
        "facingRight": true,
        "dialogue": "I will save everyone!",
        "scale": 1.0
      },
      {
        "characterId": "villain",
        "state": "angry",
        "positionX": 0.7,
        "positionY": 0.62,
        "facingRight": false,
        "dialogue": "You cannot stop me!",
        "scale": 1.0
      }
    ],
    "narration": "In the heart of the city...",
    "durationSeconds": 4,
    "transition": "fade",
    "cameraEffect": "none",
    "music": "epic",
    "ambience": "city"
  }
]

backgrounds: city, cyberpunk, forest, space, underwater, volcano, castle, battlefield, beach, snow, desert, jungle
timeOfDay: day, sunset, night
weather: none, rain, snow, storm, fog
characterIds: hero, villain, robot, wizard, ninja, dragon, princess, warrior, alien, zombie
states: idle, walk, run, attack, jump, fly, talk, angry, happy, sad, victory, death, cast, defend
cameraEffect: none, shake, zoomIn, zoomOut, pan
transitions: fade, flash, wipe, zoom, none''',
        systemPrompt: 'You are a cinematic AI director. Return ONLY valid JSON array. No markdown, no explanation.',
        maxTokens: 3000,
      );

      String clean = result.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final List scenesJson = jsonDecode(clean.substring(start, end + 1));
        _timeline.scenes.clear();

        for (int i = 0; i < scenesJson.length; i++) {
          final s = scenesJson[i];
          _timeline.addScene(StoryScene.fromJson({
            ...s,
            'id': '${DateTime.now().millisecondsSinceEpoch}_$i',
          }));
        }

        _timeline.jumpToScene(0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cinematic story generated!'), backgroundColor: Color(0xFF6C63FF)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }

    setState(() => _isGenerating = false);
  }

  void _triggerEffect(ParticleType type, double x, double y) {
    final ps = ParticleSystem(type: type, x: x, y: y);
    if (type == ParticleType.explosion) {
      ps.burst(count: 40);
    }
    _particles.add(ps);
    Future.delayed(const Duration(seconds: 3), () {
      ps.active = false;
    });
  }

  Future<void> _saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cinematic_project', jsonEncode({
      'name': _projectName,
      'scenes': _timeline.scenes.map((s) => s.toJson()).toList(),
    }));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Project saved!'), backgroundColor: Color(0xFF6C63FF)));
  }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cinematic_project');
    if (saved != null) {
      try {
        final data = jsonDecode(saved);
        _projectName = data['name'] ?? 'My Story';
        _timeline.scenes.clear();
        for (final s in data['scenes'] as List) {
          _timeline.addScene(StoryScene.fromJson(s));
        }
        if (_timeline.scenes.isEmpty) _addDefaultScene();
      } catch (_) {}
    }
  }

  Future<void> _exportHTML() async {
    setState(() => _isExporting = true);
    try {
      final html = _buildHTMLExport();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${_projectName.replaceAll(' ', '_')}_cinematic.html');
      await file.writeAsString(html);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12122A),
            title: const Text('🎬 Export Ready!', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie_filter, color: Color(0xFF6C63FF), size: 56),
                const SizedBox(height: 12),
                const Text('Cinematic HTML exported!\nOpen in browser for full experience.',
                    style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(file.path, style: const TextStyle(color: Color(0xFF3ECFCF), fontSize: 10)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF6C63FF)))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isExporting = false);
  }

  @override
  void dispose() {
    _renderController.dispose();
    _cameraController.dispose();
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Row(children: [
          const Icon(Icons.movie_filter, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _renameProject,
            child: Text(_projectName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: Color(0xFF3ECFCF)), onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.folder_open, color: Colors.grey), onPressed: _loadProject),
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.file_download, color: Color(0xFFFFD700)),
            onPressed: _isExporting ? null : _exportHTML,
          ),
        ],
      ),
      body: Column(
        children: [
          // MAIN VIEWPORT
          Expanded(
            flex: 5,
            child: _buildViewport(),
          ),

          // TIMELINE CONTROLS
          _buildTimelineControls(),

          // AI PROMPT
          _buildPromptBar(),

          // SCENE LIST
          Expanded(
            flex: 4,
            child: _buildSceneList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    final scene = _timeline.currentScene;

    return GestureDetector(
      onTapDown: (details) {
        // Tap to trigger effect
        _triggerEffect(
          ParticleType.magic,
          details.localPosition.dx,
          details.localPosition.dy,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Transform.translate(
          offset: Offset(_cameraShake, _cameraShake * 0.5),
          child: Transform.scale(
            scale: _cameraZoom,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: scene == null
                  ? const Center(child: Text('Add a scene', style: TextStyle(color: Colors.grey)))
                  : CustomPaint(
                      painter: _ViewportPainter(
                        scene: scene,
                        bgAnimProgress: _bgAnimProgress,
                        parallaxOffset: _parallaxOffset,
                        particles: _particles,
                        sceneProgress: _timeline.sceneProgress,
                      ),
                      child: _buildCharactersOverlay(scene),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharactersOverlay(StoryScene scene) {
    return Stack(
      children: [
        // Scene info
        Positioned(top: 8, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'Scene ${_timeline.currentSceneIndex + 1}/${_timeline.scenes.length} • ${scene.background.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),

        // Time indicator
        Positioned(top: 8, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${(_timeline.sceneProgress * scene.durationSeconds).toStringAsFixed(1)}s / ${scene.durationSeconds}s',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),

        // Characters
        ...scene.characters.map((char) => _buildCharacterOnStage(char)),

        // Dialogue bubbles
        if (_showSubtitles)
          ...scene.characters.where((c) => c.dialogue.isNotEmpty).map((c) => _buildDialogueBubble(c)),

        // Narration
        if (_showSubtitles && scene.narration.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Text(scene.narration, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
            ),
          ),

        // Progress bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            value: _timeline.sceneProgress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6C63FF)),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterOnStage(SceneCharacter char) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final charSize = constraints.maxHeight * 0.4 * char.scale;
        final x = constraints.maxWidth * char.positionX - charSize / 2;
        final y = constraints.maxHeight * char.positionY - charSize;

        return Positioned(
          left: x, top: y,
          child: AnimatedCharacterWidget(
            characterId: char.characterId,
            state: char.state,
            size: charSize,
            facingRight: char.facingRight,
          ),
        );
      },
    );
  }

  Widget _buildDialogueBubble(SceneCharacter char) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final x = constraints.maxWidth * char.positionX;
        final y = constraints.maxHeight * char.positionY - constraints.maxHeight * 0.2;
        final isRight = x > constraints.maxWidth * 0.5;

        return Positioned(
          left: isRight ? null : x,
          right: isRight ? constraints.maxWidth - x : null,
          top: y - 60,
          child: Container(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isRight ? 14 : 2),
                bottomRight: Radius.circular(isRight ? 2 : 14),
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Text(char.dialogue,
                style: const TextStyle(color: Color(0xFF111111), fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }

  Widget _buildTimelineControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0D0D1A),
      child: Row(
        children: [
          _ctrlBtn(Icons.skip_previous, _timeline.prevScene),
          const SizedBox(width: 6),
          _ctrlBtn(Icons.stop, _timeline.stop),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: _timeline.isPlaying ? _timeline.pause : _timeline.play,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Icon(
                  _timeline.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white, size: 22,
                )),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _ctrlBtn(Icons.skip_next, _timeline.nextScene),
          const SizedBox(width: 6),
          _ctrlBtn(_showSubtitles ? Icons.subtitles : Icons.subtitles_off,
              () => setState(() => _showSubtitles = !_showSubtitles)),
          const SizedBox(width: 6),
          // Speed control
          GestureDetector(
            onTap: () => setState(() => _timeline.playbackSpeed = _timeline.playbackSpeed == 1.0 ? 2.0 : 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text('${_timeline.playbackSpeed}x',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '🎬 AI Director: "Dragon attacks cyberpunk city at night"',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                filled: true, fillColor: const Color(0xFF12122A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isGenerating ? null : _generateFromPrompt,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _timeline.scenes.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _timeline.scenes.length) {
          return GestureDetector(
            onTap: () {
              _timeline.addScene(StoryScene(
                id: DateTime.now().toString(),
                background: BackgroundType.city,
                characters: [SceneCharacter(characterId: 'hero')],
              ));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF6C63FF)),
                  SizedBox(width: 6),
                  Text('Add Scene', style: TextStyle(color: Color(0xFF6C63FF))),
                ],
              )),
            ),
          );
        }

        final scene = _timeline.scenes[i];
        final isSelected = i == _timeline.currentSceneIndex;
        final primaryChar = scene.characters.isNotEmpty ? scene.characters.first : null;
        final charData = primaryChar != null ? CharacterRegistry.get(primaryChar.characterId) : null;

        return GestureDetector(
          onTap: () => _timeline.jumpToScene(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E1E3A) : const Color(0xFF12122A),
              border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.white12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Mini preview
                Container(
                  width: 50, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _getBgColors(scene.background)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      scene.characters.map((c) => CharacterRegistry.get(c.characterId)?.emoji ?? '').join(''),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Scene ${i + 1}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(scene.background.name,
                                style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 9)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3ECFCF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(scene.timeOfDay.name,
                                style: const TextStyle(color: Color(0xFF3ECFCF), fontSize: 9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scene.narration.isNotEmpty ? scene.narration : 'No narration',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text('${scene.durationSeconds}s',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(width: 8),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _editScene(i),
                      child: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 18),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _timeline.removeScene(i),
                      child: const Icon(Icons.delete, color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getBgColors(BackgroundType type) {
    switch (type) {
      case BackgroundType.city: return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
      case BackgroundType.cyberpunk: return [const Color(0xFF1A0033), const Color(0xFF2D004D)];
      case BackgroundType.forest: return [const Color(0xFF0D2818), const Color(0xFF1A4731)];
      case BackgroundType.space: return [const Color(0xFF000011), const Color(0xFF0A0A2E)];
      case BackgroundType.underwater: return [const Color(0xFF006994), const Color(0xFF001F3F)];
      case BackgroundType.volcano: return [const Color(0xFF3D0000), const Color(0xFF7A1500)];
      case BackgroundType.castle: return [const Color(0xFF1C1C1C), const Color(0xFF2D2D2D)];
      case BackgroundType.battlefield: return [const Color(0xFF2D2D1A), const Color(0xFF4A4A2E)];
      case BackgroundType.beach: return [const Color(0xFF006994), const Color(0xFFF5DEB3)];
      case BackgroundType.snow: return [const Color(0xFFE3F2FD), const Color(0xFF2C3E50)];
      case BackgroundType.desert: return [const Color(0xFFD2691E), const Color(0xFFC19A6B)];
      default: return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    }
  }

  void _editScene(int index) {
    final scene = _timeline.scenes[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SceneEditor(
        scene: scene,
        onUpdate: (updated) {
          _timeline.updateScene(index, updated);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _renameProject() {
    final ctrl = TextEditingController(text: _projectName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        title: const Text('Rename Project', style: TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(filled: true, fillColor: Color(0xFF1A1A2E),
            border: OutlineInputBorder(), hintText: 'Project name...', hintStyle: TextStyle(color: Colors.grey))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { setState(() => _projectName = ctrl.text.trim()); Navigator.pop(ctx); },
              child: const Text('Save', style: TextStyle(color: Color(0xFF6C63FF)))),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF12122A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
      child: Icon(icon, color: Colors.white70, size: 20),
    ),
  );

  String _buildHTMLExport() {
    // Full cinematic HTML with all character animations, backgrounds, particles
    final scenesData = _timeline.scenes.map((s) => s.toJson()).toList();
    final allChars = CharacterRegistry.getAllIds();

    return '''<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>$_projectName</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;overflow:hidden;width:100vw;height:100vh;font-family:sans-serif}
canvas{display:block;width:100%;height:100%}
#ui{position:fixed;bottom:0;left:0;right:0;padding:12px;background:rgba(0,0,0,0.8);display:flex;align-items:center;gap:10px}
.btn{background:rgba(255,255,255,0.1);border:1px solid rgba(255,255,255,0.2);color:#fff;padding:10px 16px;border-radius:20px;cursor:pointer;font-size:15px}
.btn.primary{background:linear-gradient(135deg,#6c63ff,#3ecfcf);border:none;padding:12px 28px;font-size:18px}
#progress{flex:1;height:4px;background:rgba(255,255,255,0.2);border-radius:2px;overflow:hidden}
#progress-fill{height:100%;background:linear-gradient(90deg,#6c63ff,#3ecfcf);width:0%;transition:width 0.1s}
#title-screen{position:fixed;inset:0;background:linear-gradient(135deg,#0a0a14,#1a1a2e);display:flex;flex-direction:column;align-items:center;justify-content:center;color:#fff;z-index:10}
h1{font-size:clamp(24px,6vw,48px);background:linear-gradient(135deg,#6c63ff,#3ecfcf);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:8px}
#start-btn{margin-top:30px;padding:16px 40px;border-radius:30px;border:none;font-size:18px;font-weight:bold;cursor:pointer;background:linear-gradient(135deg,#6c63ff,#3ecfcf);color:#fff}
#ui{display:none}
</style>
</head><body>
<div id="title-screen">
  <div style="font-size:64px">🎬</div>
  <h1>$_projectName</h1>
  <p style="color:#888">${_timeline.scenes.length} cinematic scenes</p>
  <button id="start-btn" onclick="startMovie()">▶ Play Movie</button>
</div>
<canvas id="c"></canvas>
<div id="ui">
  <button class="btn" onclick="prev()">⏮</button>
  <button class="btn primary" id="pb" onclick="togglePlay()">⏸</button>
  <button class="btn" onclick="next()">⏭</button>
  <div id="progress"><div id="progress-fill"></div></div>
  <button class="btn" onclick="toggleSub()">💬</button>
</div>
<script>
const SCENES=${jsonEncode(scenesData)};
const canvas=document.getElementById('c');
const ctx=canvas.getContext('2d');
let W,H,cur=0,playing=true,sub=true,elapsed=0,anim=0,audioCtx=null;
let particles=[];

function resize(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight-60}
window.addEventListener('resize',resize);

function startMovie(){
  document.getElementById('title-screen').style.display='none';
  document.getElementById('ui').style.display='flex';
  resize();
  requestAnimationFrame(loop);
}

let last=0;
function loop(ts){
  requestAnimationFrame(loop);
  const dt=Math.min((ts-last)/1000,0.05);last=ts;
  if(playing){elapsed+=dt;anim+=dt;}
  const scene=SCENES[cur];
  if(scene&&elapsed>=scene.durationSeconds){
    elapsed=0;
    if(cur<SCENES.length-1)cur++;
    else{playing=false;document.getElementById('pb').textContent='▶';}
  }
  render(dt);
  document.getElementById('progress-fill').style.width=((cur/SCENES.length)*100)+'%';
}

function render(dt){
  ctx.clearRect(0,0,W,H);
  const scene=SCENES[cur];
  if(!scene)return;
  drawBackground(scene);
  updateParticles(dt);
  drawParticles();
  drawCharacters(scene);
  if(sub)drawSubtitles(scene);
  drawVignette();
}

function drawBackground(scene){
  const bgs={
    city:['#1a1a2e','#16213e'],cyberpunk:['#1a0033','#2d004d'],
    forest:['#0d2818','#1a4731'],space:['#000011','#0a0a2e'],
    underwater:['#006994','#001f3f'],volcano:['#3d0000','#7a1500'],
    castle:['#1c1c1c','#2d2d2d'],beach:['#006994','#87ceeb'],
    snow:['#e3f2fd','#2c3e50'],desert:['#d2691e','#c19a6b'],
    battlefield:['#2d2d1a','#4a4a2e'],jungle:['#0d3318','#1a5031']
  };
  const c=bgs[scene.background]||bgs.city;
  const g=ctx.createLinearGradient(0,0,0,H);
  g.addColorStop(0,c[0]);g.addColorStop(1,c[1]);
  ctx.fillStyle=g;ctx.fillRect(0,0,W,H);
  drawBgDetails(scene);
  if(scene.timeOfDay==='night'){ctx.fillStyle='rgba(10,10,46,0.4)';ctx.fillRect(0,0,W,H);}
  if(scene.timeOfDay==='sunset'){ctx.fillStyle='rgba(255,107,53,0.2)';ctx.fillRect(0,0,W,H);}
}

function drawBgDetails(scene){
  const bg=scene.background;
  if(bg==='city'||bg==='cyberpunk'){drawCity(bg==='cyberpunk');}
  else if(bg==='forest'||bg==='jungle'){drawForest();}
  else if(bg==='space'){drawSpace();}
  else if(bg==='beach'){drawBeach();}
  else if(bg==='snow'){drawSnow();}
  else if(bg==='desert'){drawDesert();}
  else if(bg==='volcano'){drawVolcano();}
  else if(bg==='castle'){drawCastle();}
  if(scene.timeOfDay==='night'||bg==='space'){drawStars();}
}

function drawCity(cyber){
  const ground=cyber?'#1a0033':'#4a4a4a';
  ctx.fillStyle=ground;ctx.fillRect(0,H*0.65,W,H*0.35);
  const buildings=[[0,0.35,0.12],[0.15,0.25,0.1],[0.28,0.4,0.09],[0.4,0.2,0.11],[0.54,0.32,0.1],[0.67,0.22,0.12],[0.82,0.38,0.09]];
  buildings.forEach(([x,h,w])=>{
    const bx=x*W,bw=w*W,bh=h*H,by=H*0.65-bh;
    ctx.fillStyle=cyber?`hsl(${270+x*30},50%,${8+x*5}%)`:`hsl(${220+x*20},10%,${20+x*8}%)`;
    ctx.fillRect(bx,by,bw,bh);
    for(let r=0;r<6;r++)for(let c2=0;c2<3;c2++){
      if((r+c2+Math.floor(x*10))%3!==0){
        ctx.fillStyle=cyber?`hsla(${r*60},100%,60%,0.7)`:'rgba(255,230,100,0.7)';
        ctx.fillRect(bx+bw*0.1+c2*bw*0.28,by+bh*0.08+r*bh*0.13,bw*0.18,bh*0.08);
      }
    }
  });
  ctx.fillStyle='#333';ctx.fillRect(0,H*0.78,W,H*0.22);
  ctx.strokeStyle='rgba(255,255,255,0.4)';ctx.lineWidth=3;
  for(let x2=-50;x2<W+50;x2+=80){ctx.beginPath();ctx.moveTo(x2,H*0.89);ctx.lineTo(x2+50,H*0.89);ctx.stroke();}
}

function drawForest(){
  ctx.fillStyle='#2d5a27';ctx.fillRect(0,H*0.65,W,H*0.35);
  for(let x=0;x<W+80;x+=70)drawTree(x,H*0.67,35,80,'#1b5e20');
  for(let x=30;x<W+50;x+=90)drawTree(x+35,H*0.69,45,100,'#388e3c');
}
function drawTree(x,y,w,h,c){
  ctx.fillStyle='#5d4037';ctx.fillRect(x-w*0.12,y-h*0.3,w*0.24,h*0.3);
  ctx.fillStyle=c;
  ctx.beginPath();ctx.moveTo(x,y-h);ctx.lineTo(x+w*0.65,y-h*0.42);ctx.lineTo(x-w*0.65,y-h*0.42);ctx.fill();
  ctx.fillStyle=c.replace('1b','38').replace('5e','8e').replace('20','3c');
  ctx.beginPath();ctx.moveTo(x,y-h*0.65);ctx.lineTo(x+w*0.75,y-h*0.2);ctx.lineTo(x-w*0.75,y-h*0.2);ctx.fill();
}
function drawSpace(){
  // extra nebula
  const g=ctx.createRadialGradient(W*0.3,H*0.3,10,W*0.3,H*0.3,W*0.4);
  g.addColorStop(0,'rgba(100,0,255,0.15)');g.addColorStop(1,'transparent');
  ctx.fillStyle=g;ctx.fillRect(0,0,W,H);
  ctx.fillStyle='#1a1a3e';ctx.fillRect(0,H*0.72,W,H*0.28);
  ctx.fillStyle='rgba(255,255,255,0.1)';
  ctx.beginPath();ctx.ellipse(W/2,H*0.72,W*0.6,H*0.08,0,0,Math.PI*2);ctx.fill();
}
function drawBeach(){
  ctx.fillStyle='#0099cc';ctx.fillRect(0,H*0.5,W,H*0.25);
  ctx.fillStyle='#f5deb3';ctx.fillRect(0,H*0.72,W,H*0.28);
  ctx.strokeStyle='rgba(255,255,255,0.5)';ctx.lineWidth=2;
  for(let i=0;i<3;i++){
    ctx.beginPath();ctx.moveTo(0,H*(0.58+i*0.04));
    for(let x=0;x<W;x+=40)ctx.quadraticCurveTo(x+20,H*(0.575+i*0.04),x+40,H*(0.58+i*0.04));
    ctx.stroke();
  }
}
function drawSnow(){
  ctx.fillStyle='#fff';ctx.fillRect(0,H*0.65,W,H*0.35);
  for(let x=0;x<W;x+=100){
    ctx.fillStyle='#1b5e20';
    ctx.beginPath();ctx.moveTo(x,H*0.65-90);ctx.lineTo(x+35,H*0.65-20);ctx.lineTo(x-35,H*0.65-20);ctx.fill();
    ctx.fillStyle='rgba(255,255,255,0.8)';
    ctx.beginPath();ctx.moveTo(x,H*0.65-90);ctx.lineTo(x+22,H*0.65-52);ctx.lineTo(x-22,H*0.65-52);ctx.fill();
    ctx.fillStyle='#5d4037';ctx.fillRect(x-5,H*0.65-20,10,20);
  }
}
function drawDesert(){
  const g=ctx.createLinearGradient(0,H*0.5,0,H);
  g.addColorStop(0,'#d2691e');g.addColorStop(1,'#c19a6b');
  ctx.fillStyle=g;ctx.fillRect(0,H*0.5,W,H*0.5);
  [W*0.2,W*0.75].forEach(x=>{
    ctx.fillStyle='#228b22';
    ctx.fillRect(x-6,H*0.65-60,12,60);
    ctx.fillRect(x-22,H*0.65-42,15,8);
    ctx.fillRect(x-22,H*0.65-52,8,22);
    ctx.fillRect(x+8,H*0.65-35,15,8);
    ctx.fillRect(x+14,H*0.65-48,8,22);
    ctx.fillStyle='#1a6b1a';
    ctx.beginPath();ctx.arc(x,H*0.65-60,10,0,Math.PI*2);ctx.fill();
  });
}
function drawVolcano(){
  ctx.fillStyle='#3d0000';ctx.fillRect(0,H*0.65,W,H*0.35);
  ctx.fillStyle='#4a0000';
  ctx.beginPath();ctx.moveTo(W*0.35,H*0.65);ctx.lineTo(W*0.5,H*0.22);ctx.lineTo(W*0.65,H*0.65);ctx.fill();
  ctx.shadowColor='#ff4500';ctx.shadowBlur=30;
  ctx.fillStyle='rgba(255,69,0,0.8)';ctx.beginPath();ctx.arc(W*0.5,H*0.25,18,0,Math.PI*2);ctx.fill();
  ctx.shadowBlur=0;
  spawnParticle('fire',W*0.5,H*0.27);
}
function drawCastle(){
  ctx.fillStyle='#3d3d3d';ctx.fillRect(0,H*0.65,W,H*0.35);
  ctx.fillStyle='#5a5a5a';ctx.fillRect(W*0.3,H*0.22,W*0.4,H*0.43);
  ctx.fillStyle='#4a4a4a';
  ctx.fillRect(W*0.15,H*0.35,W*0.15,H*0.3);
  ctx.fillRect(W*0.7,H*0.35,W*0.15,H*0.3);
  for(let bx=W*0.3;bx<W*0.7;bx+=W*0.06){ctx.fillRect(bx,H*0.17,W*0.04,H*0.06);}
  ctx.fillStyle='#1a1a1a';
  ctx.beginPath();ctx.arc(W*0.5,H*0.52,W*0.07,Math.PI,0);ctx.fill();
  ctx.strokeStyle='#888';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(W*0.5,H*0.22);ctx.lineTo(W*0.5,H*0.09);ctx.stroke();
  ctx.fillStyle='red';ctx.beginPath();ctx.moveTo(W*0.5,H*0.09);ctx.lineTo(W*0.62,H*0.12);ctx.lineTo(W*0.5,H*0.16);ctx.fill();
}
function drawStars(){
  const stars=[[0.05,0.05],[0.15,0.1],[0.25,0.04],[0.4,0.08],[0.55,0.03],[0.7,0.09],[0.85,0.05],[0.92,0.12]];
  stars.forEach(([x,y])=>{
    const twinkle=Math.sin(anim*3+x*10)>0;
    ctx.fillStyle=`rgba(255,255,255,${twinkle?0.9:0.5})`;
    ctx.beginPath();ctx.arc(x*W,y*H,twinkle?2.5:1.5,0,Math.PI*2);ctx.fill();
  });
}

// PARTICLE SYSTEM
function spawnParticle(type,x,y,count=1){
  for(let i=0;i<count;i++){
    const p={type,x,y,vx:0,vy:0,life:1,maxLife:1,size:8,color:'#ff4500',rot:0,rotV:0};
    switch(type){
      case 'fire':p.vx=(Math.random()-0.5)*40;p.vy=-(Math.random()*60+40);p.life=p.maxLife=Math.random()*0.8+0.3;p.size=Math.random()*16+8;p.color=['#ff6d00','#ff3d00','#ffd600','#ff1744'][Math.floor(Math.random()*4)];break;
      case 'smoke':p.vx=(Math.random()-0.5)*20;p.vy=-(Math.random()*30+10);p.life=p.maxLife=Math.random()*1.5+0.5;p.size=Math.random()*25+10;p.color=`rgba(150,150,150,${Math.random()*0.3+0.1})`;break;
      case 'explosion':const a=Math.random()*Math.PI*2,s=Math.random()*200+100;p.vx=Math.cos(a)*s;p.vy=Math.sin(a)*s-100;p.life=p.maxLife=Math.random()*0.6+0.2;p.size=Math.random()*14+4;p.color=['#ff6d00','#ffd600','#ff1744','#fff'][Math.floor(Math.random()*4)];break;
      case 'magic':p.vx=(Math.random()-0.5)*30;p.vy=-(Math.random()*50+20);p.life=p.maxLife=Math.random()+0.4;p.size=Math.random()*8+3;p.color=['#aa00ff','#e040fb','#7c4dff','#00e5ff'][Math.floor(Math.random()*4)];break;
      case 'sparks':const a2=Math.random()*Math.PI*2,s2=Math.random()*150+50;p.vx=Math.cos(a2)*s2;p.vy=Math.sin(a2)*s2-80;p.life=p.maxLife=Math.random()*0.3+0.1;p.size=Math.random()*4+2;p.color=['yellow','orange','white'][Math.floor(Math.random()*3)];break;
    }
    particles.push(p);
  }
}

function updateParticles(dt){
  particles=particles.filter(p=>{
    p.life-=dt;
    if(p.life<=0)return false;
    p.x+=p.vx*dt;p.y+=p.vy*dt;
    if(p.type==='fire'){p.vy-=80*dt;p.vx+=(Math.random()-0.5)*30*dt;p.size*=(1-dt*0.8);}
    if(p.type==='smoke'){p.vy-=20*dt;p.size*=(1+dt*0.3);}
    if(p.type==='explosion')p.vy+=150*dt;
    if(p.type==='magic')p.vy-=40*dt;
    if(p.type==='sparks')p.vy+=200*dt;
    return p.life>0&&p.size>0.5;
  });
}

function drawParticles(){
  particles.forEach(p=>{
    const alpha=(p.life/p.maxLife);
    ctx.save();
    ctx.globalAlpha=alpha;
    if(p.type==='fire'||p.type==='magic'){ctx.shadowColor=p.color;ctx.shadowBlur=p.size*0.8;}
    ctx.fillStyle=p.color;
    ctx.beginPath();ctx.arc(p.x,p.y,p.size/2,0,Math.PI*2);ctx.fill();
    ctx.restore();
  });
}

// CHARACTER DRAWING
const CHARS={
  hero:{emoji:'🦸',color:'#6c63ff'},villain:{emoji:'🦹',color:'#ff1744'},
  robot:{emoji:'🤖',color:'#00e676'},wizard:{emoji:'🧙',color:'#cc5de8'},
  ninja:{emoji:'🥷',color:'#212121'},dragon:{emoji:'🐲',color:'#ff6d00'},
  princess:{emoji:'👸',color:'#ff80ab'},warrior:{emoji:'⚔️',color:'#bdb76b'},
  alien:{emoji:'👽',color:'#69f0ae'},zombie:{emoji:'🧟',color:'#558b2f'},
  knight:{emoji:'🛡️',color:'#90a4ae'},archer:{emoji:'🏹',color:'#a1887f'}
};

function drawCharacters(scene){
  (scene.characters||[]).forEach(char=>{
    drawCharacter(char,scene);
  });
}

function drawCharacter(char,scene){
  const data=CHARS[char.characterId]||CHARS.hero;
  const x=char.positionX*W;
  const y=char.positionY*H;
  const size=H*0.3*(char.scale||1);
  const t=anim;
  const state=char.state||'idle';

  ctx.save();
  ctx.translate(x,y);
  if(!char.facingRight)ctx.scale(-1,1);

  // Shadow
  ctx.fillStyle='rgba(0,0,0,0.3)';
  ctx.beginPath();ctx.ellipse(0,10,size*0.25,size*0.06,0,0,Math.PI*2);ctx.fill();

  // Glow for special states
  if(state==='attack'||state==='cast'||state==='victory'){
    ctx.shadowColor=data.color;ctx.shadowBlur=30;
  }

  // Body transforms per state
  let bodyY=0,scaleX=1,scaleY=1,rot=0;
  switch(state){
    case 'idle':bodyY=Math.sin(t*2)*4;break;
    case 'walk':bodyY=Math.sin(t*6)*3;rot=Math.sin(t*6)*0.06;break;
    case 'run':bodyY=Math.sin(t*10)*5;rot=Math.sin(t*10)*0.1;scaleX=1+Math.abs(Math.sin(t*10))*0.05;break;
    case 'jump':bodyY=-Math.abs(Math.sin(t*3))*size*0.4;scaleX=1+Math.sin(t*3)*0.08;scaleY=1-Math.sin(t*3)*0.08;break;
    case 'attack':rot=Math.sin(t*8)*0.3;ctx.shadowColor=data.color;ctx.shadowBlur=20;break;
    case 'fly':bodyY=Math.sin(t*3)*8;rot=-0.15;ctx.shadowColor=data.color;ctx.shadowBlur=15;break;
    case 'talk':bodyY=Math.sin(t*5)*2;break;
    case 'angry':rot=Math.sin(t*12)*0.05;ctx.shadowColor='#ff0000';ctx.shadowBlur=15;break;
    case 'happy':bodyY=-Math.abs(Math.sin(t*4))*10;scaleX=1+Math.sin(t*4)*0.06;break;
    case 'sad':bodyY=3;rot=0.05;break;
    case 'victory':bodyY=-Math.abs(Math.sin(t*3))*20;ctx.shadowColor='#ffd700';ctx.shadowBlur=25;break;
    case 'death':rot=t<2?t*Math.PI/4:Math.PI/2;bodyY=t<2?t*size*0.2:size*0.4;break;
    case 'cast':rot=Math.sin(t*4)*0.12;ctx.shadowColor='#aa00ff';ctx.shadowBlur=30;
      spawnParticle('magic',x+Math.sin(t*5)*30,y-size*0.5);break;
    case 'defend':scaleX=0.88;bodyY=-5;ctx.shadowColor='#4488ff';ctx.shadowBlur=20;break;
  }

  ctx.translate(0,bodyY);
  ctx.rotate(rot);
  ctx.scale(scaleX,scaleY);

  // Draw detailed character body
  drawCharacterBody(ctx,data.color,size,state,t);

  ctx.restore();

  // Dialogue bubble
  if(char.dialogue){
    drawDialogueBubble(char.dialogue,x,y-size*0.9,char.facingRight);
  }
}

function drawCharacterBody(c,color,size,state,t){
  const bw=size*0.42,bh=size*0.5;
  const r=(hex)=>parseInt(hex.slice(1,3),16);
  const g=(hex)=>parseInt(hex.slice(3,5),16);
  const b=(hex)=>parseInt(hex.slice(5,7),16);

  // Legs
  const legSwing=Math.sin(t*6)*(state==='run'?20:state==='walk'?12:0)*Math.PI/180;
  [-1,1].forEach(side=>{
    c.save();c.translate(side*bw*0.18,bh*0.52);c.rotate(side*legSwing);
    c.fillStyle=color;c.fillRect(-bw*0.13,0,bw*0.26,bh*0.36);
    c.fillStyle='#111';c.fillRect(-bw*0.18,bh*0.33,bw*0.35,bh*0.1);
    c.restore();
  });

  // Body
  const grad=c.createLinearGradient(-bw*0.5,-bh*0.5,bw*0.5,bh*0.5);
  grad.addColorStop(0,`rgba(${r(color)+40},${g(color)+40},${b(color)+40},0.9)`);
  grad.addColorStop(1,color);
  c.fillStyle=grad;
  c.beginPath();c.roundRect(-bw*0.5,-bh*0.35,bw,bh*0.7,10);c.fill();

  // Chest emblem
  c.fillStyle='rgba(255,255,255,0.85)';
  drawStar(c,0,-bh*0.05,bw*0.1);

  // Arms
  const armSwing=Math.sin(t*6)*(state==='run'?25:state==='walk'?15:0)*Math.PI/180;
  [-1,1].forEach(side=>{
    c.save();c.translate(side*bw*0.5,-bh*0.05);
    c.rotate(state==='attack'&&side===1?-Math.PI/3+Math.sin(t*8)*0.5:side*armSwing);
    c.fillStyle=color;c.beginPath();c.roundRect(-bw*0.11,0,bw*0.22,bh*0.34,5);c.fill();
    c.fillStyle='#FFDBA0';c.beginPath();c.arc(0,bh*0.36,bw*0.12,0,Math.PI*2);c.fill();
    c.restore();
  });

  // Neck
  c.fillStyle='#FFDBA0';c.fillRect(-bw*0.1,-bh*0.36,bw*0.2,bh*0.1);

  // Head
  c.fillStyle='#FFDBA0';
  c.beginPath();c.ellipse(0,-bh*0.55,bw*0.28,bh*0.22,0,0,Math.PI*2);c.fill();

  // Hair
  c.fillStyle='#3e2723';
  c.beginPath();c.ellipse(0,-bh*0.68,bw*0.27,bh*0.12,0,-Math.PI,0);c.fill();

  // Eyes
  const mouthOpen=(state==='talk')?Math.abs(Math.sin(t*8))*bh*0.06:0;
  [-1,1].forEach(side=>{
    c.fillStyle='white';c.beginPath();c.ellipse(side*bw*0.12,-bh*0.56,bw*0.07,bh*0.055,0,0,Math.PI*2);c.fill();
    c.fillStyle='#111';c.beginPath();c.arc(side*bw*0.12,-bh*0.555,bw*0.035,0,Math.PI*2);c.fill();
    c.fillStyle='white';c.beginPath();c.arc(side*bw*0.1,-bh*0.565,bw*0.02,0,Math.PI*2);c.fill();
  });

  // Brows
  const browTilt=state==='angry'?0.4:state==='sad'?-0.25:0;
  c.strokeStyle='#3e2723';c.lineWidth=2.5;c.lineCap='round';
  [-1,1].forEach(side=>{
    c.save();c.translate(side*bw*0.12,-bh*0.63);c.rotate(side*browTilt);
    c.beginPath();c.moveTo(-bw*0.09,0);c.lineTo(bw*0.09,0);c.stroke();
    c.restore();
  });

  // Mouth
  const my=-bh*0.475;
  c.strokeStyle='#111';c.lineWidth=2;c.lineCap='round';
  if(state==='happy'||state==='victory'){
    c.beginPath();c.moveTo(-bw*0.1,my);c.quadraticCurveTo(0,my+bh*0.07,bw*0.1,my);c.stroke();
  } else if(state==='sad'||state==='death'){
    c.beginPath();c.moveTo(-bw*0.1,my+bh*0.04);c.quadraticCurveTo(0,my-bh*0.02,bw*0.1,my+bh*0.04);c.stroke();
  } else if(state==='angry'){
    c.beginPath();c.moveTo(-bw*0.1,my+bh*0.02);c.lineTo(bw*0.1,my+bh*0.02);c.stroke();
  } else {
    c.beginPath();c.moveTo(-bw*0.08,my);c.lineTo(bw*0.08,my);c.stroke();
    if(mouthOpen>2){
      c.fillStyle='#b71c1c';
      c.beginPath();c.ellipse(0,my+mouthOpen/2,bw*0.08,mouthOpen*0.5,0,0,Math.PI*2);c.fill();
    }
  }
}

function drawStar(c,x,y,r){
  c.beginPath();
  for(let i=0;i<10;i++){
    const a=i*Math.PI/5-Math.PI/2;
    const radius=i%2===0?r:r*0.4;
    i===0?c.moveTo(x+Math.cos(a)*radius,y+Math.sin(a)*radius):c.lineTo(x+Math.cos(a)*radius,y+Math.sin(a)*radius);
  }
  c.closePath();c.fill();
}

function drawDialogueBubble(text,x,y,right){
  const maxW=Math.min(W*0.35,200);
  ctx.font='bold 13px sans-serif';
  const lines=[];let line='';
  text.split(' ').forEach(w=>{
    const test=line+w+' ';
    if(ctx.measureText(test).width>maxW-20&&line!=''){lines.push(line.trim());line=w+' ';}
    else line=test;
  });
  lines.push(line.trim());
  const lh=18,pad=10,bw=maxW,bh=lines.length*lh+pad*2;
  const bx=right?x-bw/2-10:x-bw/2+10;
  const by=y-bh-20;
  ctx.fillStyle='rgba(255,255,255,0.96)';
  ctx.beginPath();ctx.roundRect(bx,by,bw,bh,12);ctx.fill();
  ctx.fillStyle='#e0e0e0';ctx.beginPath();
  ctx.moveTo(x-8,by+bh);ctx.lineTo(x+8,by+bh);ctx.lineTo(x,by+bh+12);ctx.fill();
  ctx.fillStyle='#111';ctx.font='bold 12px sans-serif';ctx.textAlign='left';
  lines.forEach((l,i)=>ctx.fillText(l,bx+10,by+pad+14+i*lh));
}

function drawSubtitles(scene){
  const chars=scene.characters||[];
  const narration=scene.narration||'';
  const text=chars.find(c=>c.dialogue)?.dialogue||narration;
  if(!text)return;
  const grad=ctx.createLinearGradient(0,H*0.82,0,H);
  grad.addColorStop(0,'transparent');grad.addColorStop(1,'rgba(0,0,0,0.85)');
  ctx.fillStyle=grad;ctx.fillRect(0,H*0.82,W,H*0.18);
  ctx.fillStyle='white';ctx.font='bold 15px sans-serif';ctx.textAlign='center';
  ctx.shadowColor='black';ctx.shadowBlur=4;
  ctx.fillText(text,W/2,H*0.94);ctx.shadowBlur=0;
}

function drawVignette(){
  const g=ctx.createRadialGradient(W/2,H/2,H*0.3,W/2,H/2,W*0.7);
  g.addColorStop(0,'transparent');g.addColorStop(1,'rgba(0,0,0,0.35)');
  ctx.fillStyle=g;ctx.fillRect(0,0,W,H);
}

// Controls
let togSub=true;
function togglePlay(){playing=!playing;document.getElementById('pb').textContent=playing?'⏸':'▶';}
function next(){if(cur<SCENES.length-1){cur++;elapsed=0;}}
function prev(){if(cur>0){cur--;elapsed=0;}}
function toggleSub(){togSub=!togSub;sub=togSub;}

// Touch
let tx=0;
document.addEventListener('touchstart',e=>tx=e.touches[0].clientX);
document.addEventListener('touchend',e=>{const d=tx-e.changedTouches[0].clientX;if(Math.abs(d)>50){d>0?next():prev();}});
canvas.addEventListener('click',e=>{
  const scene=SCENES[cur];
  if(scene&&(scene.background==='volcano'||scene.background==='battlefield')){
    for(let i=0;i<15;i++)spawnParticle('explosion',e.clientX,e.clientY);
    for(let i=0;i<8;i++)spawnParticle('sparks',e.clientX,e.clientY);
  } else {
    for(let i=0;i<10;i++)spawnParticle('magic',e.clientX,e.clientY);
  }
});
</script>
</body></html>''';
  }
}

class _ViewportPainter extends CustomPainter {
  final StoryScene scene;
  final double bgAnimProgress;
  final double parallaxOffset;
  final List<ParticleSystem> particles;
  final double sceneProgress;

  _ViewportPainter({
    required this.scene,
    required this.bgAnimProgress,
    required this.parallaxOffset,
    required this.particles,
    required this.sceneProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    BackgroundPainter(
      type: scene.background,
      timeOfDay: scene.timeOfDay,
      weather: scene.weather,
      animProgress: bgAnimProgress,
      parallaxOffset: parallaxOffset,
    ).paint(canvas, size);

    for (final ps in particles) {
      ps.render(canvas);
    }
  }

  @override
  bool shouldRepaint(_ViewportPainter old) => true;
}

class _SceneEditor extends StatefulWidget {
  final StoryScene scene;
  final Function(StoryScene) onUpdate;
  const _SceneEditor({required this.scene, required this.onUpdate});
  @override
  State<_SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<_SceneEditor> {
  late StoryScene _scene;
  final TextEditingController _narrationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scene = StoryScene.fromJson(widget.scene.toJson());
    _narrationCtrl.text = _scene.narration;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            const Text('🎬 Edit Scene', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            _label('🌍 Background'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: BackgroundType.values.map((bg) => GestureDetector(
                onTap: () => setState(() => _scene = StoryScene.fromJson({..._scene.toJson(), 'background': bg.name})),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scene.background == bg ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(bg.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 12),
            _label('🌅 Time of Day'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: TimeOfDay.values.map((t) => GestureDetector(
                onTap: () => setState(() => _scene = StoryScene.fromJson({..._scene.toJson(), 'timeOfDay': t.name})),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scene.timeOfDay == t ? const Color(0xFFFF922B) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 12),
            _label('🎭 Characters'),
            const SizedBox(height: 6),
            ..._scene.characters.asMap().entries.map((entry) => _buildCharEditor(entry.key, entry.value)),
            GestureDetector(
              onTap: () {
                if (_scene.characters.length < 3) {
                  setState(() {
                    final chars = List<SceneCharacter>.from(_scene.characters);
                    chars.add(SceneCharacter(characterId: 'villain', positionX: 0.7, facingRight: false));
                    _scene = StoryScene.fromJson({..._scene.toJson(), 'characters': chars.map((c) => c.toJson()).toList()});
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('+ Add Character', style: TextStyle(color: Color(0xFF6C63FF)))),
              ),
            ),

            const SizedBox(height: 12),
            _label('📝 Narration'),
            const SizedBox(height: 6),
            TextField(
              controller: _narrationCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              onChanged: (v) => _scene = StoryScene.fromJson({..._scene.toJson(), 'narration': v}),
              decoration: InputDecoration(
                hintText: 'Scene narration...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 12),
            _label('📷 Camera Effect'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: CameraEffect.values.map((c) => GestureDetector(
                onTap: () => setState(() => _scene = StoryScene.fromJson({..._scene.toJson(), 'cameraEffect': c.name})),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scene.cameraEffect == c ? const Color(0xFF20C997) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 12),
            _label('⏱️ Duration: ${_scene.durationSeconds}s'),
            Slider(
              value: _scene.durationSeconds.toDouble(),
              min: 1, max: 15, divisions: 14,
              activeColor: const Color(0xFF6C63FF),
              label: '${_scene.durationSeconds}s',
              onChanged: (v) => setState(() => _scene = StoryScene.fromJson({..._scene.toJson(), 'durationSeconds': v.toInt()})),
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => widget.onUpdate(_scene),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('Save Scene ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCharEditor(int index, SceneCharacter char) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Character ${index + 1}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            const Spacer(),
            if (_scene.characters.length > 1)
              GestureDetector(
                onTap: () => setState(() {
                  final chars = List<SceneCharacter>.from(_scene.characters);
                  chars.removeAt(index);
                  _scene = StoryScene.fromJson({..._scene.toJson(), 'characters': chars.map((c) => c.toJson()).toList()});
                }),
                child: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
              ),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4,
            children: CharacterRegistry.getAllIds().map((id) {
              final data = CharacterRegistry.get(id)!;
              return GestureDetector(
                onTap: () => setState(() {
                  final chars = List<SceneCharacter>.from(_scene.characters);
                  chars[index] = SceneCharacter(characterId: id, positionX: char.positionX, positionY: char.positionY, facingRight: char.facingRight, dialogue: char.dialogue, scale: char.scale);
                  _scene = StoryScene.fromJson({..._scene.toJson(), 'characters': chars.map((c) => c.toJson()).toList()});
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: char.characterId == id ? const Color(0xFF6C63FF) : const Color(0xFF0A0A14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${data.emoji} $id', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4,
            children: CharacterState.values.map((s) => GestureDetector(
              onTap: () => setState(() {
                final chars = List<SceneCharacter>.from(_scene.characters);
                chars[index] = SceneCharacter(characterId: char.characterId, positionX: char.positionX, positionY: char.positionY, facingRight: char.facingRight, dialogue: char.dialogue, state: s, scale: char.scale);
                _scene = StoryScene.fromJson({..._scene.toJson(), 'characters': chars.map((c) => c.toJson()).toList()});
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: char.state == s ? const Color(0xFFCC5DE8) : const Color(0xFF0A0A14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: char.dialogue),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: (v) {
              final chars = List<SceneCharacter>.from(_scene.characters);
              chars[index] = SceneCharacter(characterId: char.characterId, positionX: char.positionX, positionY: char.positionY, facingRight: char.facingRight, dialogue: v, state: char.state, scale: char.scale);
              _scene = StoryScene.fromJson({..._scene.toJson(), 'characters': chars.map((c) => c.toJson()).toList()});
            },
            decoration: InputDecoration(
              hintText: 'Dialogue...', hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              filled: true, fillColor: const Color(0xFF0A0A14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));
}
