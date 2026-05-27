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

class _VideoScreenState extends State<VideoScreen>
    with TickerProviderStateMixin {
  final TimelineEngine _timeline = TimelineEngine();
  late AnimationController _renderCtrl;
  double _cameraShake = 0;
  double _cameraZoom = 1.0;
  double _parallax = 0;
  double _bgAnim = 0;
  double _lastT = 0;
  final List<ParticleSystem> _particles = [];
  final TextEditingController _promptCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _isExporting = false;
  bool _showSubtitles = true;
  String _projectName = 'My Story';

  @override
  void initState() {
    super.initState();
    _renderCtrl =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick)
          ..repeat();
    _timeline.addListener(_onTimelineChange);
    _loadProject();
    _addDefaultScene();
  }

  void _onTimelineChange() {
    if (mounted) setState(() {});
  }

  void _onTick() {
    final now = _renderCtrl.value * 86400.0;
    final dt = (_lastT > 0) ? (now - _lastT).clamp(0.0, 0.05) : 0.016;
    _lastT = now;

    _timeline.tick(dt);
    _bgAnim = (now * 0.08) % 1.0;

    final scene = _timeline.currentScene;
    if (scene != null) {
      switch (scene.cameraEffect) {
        case CameraEffect.shake:
          _cameraShake = math.sin(now * 28) * 5;
          break;
        case CameraEffect.zoomIn:
          _cameraZoom = 1.0 + _timeline.sceneProgress * 0.28;
          break;
        case CameraEffect.zoomOut:
          _cameraZoom = 1.28 - _timeline.sceneProgress * 0.28;
          break;
        case CameraEffect.pan:
          _parallax = _timeline.sceneProgress * 90;
          break;
        default:
          _cameraShake = 0;
          _cameraZoom = 1.0;
      }
    }

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
        timeOfDay: SceneTimeOfDay.day,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: CharacterState.idle,
            positionX: 0.35,
            positionY: 0.62,
            dialogue: 'I am ready!',
          ),
        ],
        narration: 'The adventure begins...',
        durationSeconds: 4,
      ));
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Story prompt daalo!')));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final result = await AIService.sendMessage(
        userMessage: '''Create 6 cinematic cartoon scenes for: "$prompt"

Return ONLY valid JSON array:
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

Allowed backgrounds: city,cyberpunk,forest,space,underwater,volcano,castle,battlefield,beach,snow,desert,jungle,fantasy
Allowed timeOfDay: day,sunset,night
Allowed characterIds: hero,villain,robot,wizard,ninja,dragon,princess,warrior,alien,zombie
Allowed states: idle,walk,run,attack,jump,fly,talk,angry,happy,sad,victory,death,cast,defend
Allowed cameraEffect: none,shake,zoomIn,zoomOut,pan
Allowed transitions: fade,flash,wipe,zoom,none''',
        systemPrompt:
            'You are a cinematic AI cartoon director. Return ONLY valid JSON array. No markdown. No explanation.',
        maxTokens: 3000,
      );

      String clean =
          result.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final List scenesJson = jsonDecode(clean.substring(start, end + 1));
        _timeline.scenes.clear();
        for (int i = 0; i < scenesJson.length; i++) {
          _timeline.addScene(StoryScene.fromJson({
            ...scenesJson[i],
            'id': '${DateTime.now().millisecondsSinceEpoch}_$i',
          }));
        }
        _timeline.jumpToScene(0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cinematic story generated!'),
              backgroundColor: Color(0xFF6C63FF)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isGenerating = false);
  }

  void _triggerEffect(ParticleType type, double x, double y) {
    final ps = ParticleSystem(type: type, x: x, y: y);
    if (type == ParticleType.explosion) ps.burst(count: 35);
    _particles.add(ps);
    Future.delayed(const Duration(seconds: 3), () => ps.active = false);
  }

  Future<void> _saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'cartoon_project',
        jsonEncode({
          'name': _projectName,
          'scenes': _timeline.scenes.map((s) => s.toJson()).toList(),
        }));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Project saved!'),
          backgroundColor: Color(0xFF6C63FF)));
    }
  }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cartoon_project');
    if (saved != null) {
      try {
        final data = jsonDecode(saved);
        _projectName = data['name'] ?? 'My Story';
        _timeline.scenes.clear();
        for (final s in data['scenes'] as List) {
          _timeline.addScene(StoryScene.fromJson(s));
        }
        if (_timeline.scenes.isEmpty) _addDefaultScene();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _exportHTML() async {
    setState(() => _isExporting = true);
    try {
      final html = _buildCinematicHTML();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/${_projectName.replaceAll(' ', '_')}_cartoon.html');
      await file.writeAsString(html);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12122A),
            title: const Text('Export Ready!',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie_filter,
                    color: Color(0xFF6C63FF), size: 56),
                const SizedBox(height: 12),
                const Text('Cinematic cartoon exported!\nOpen in browser.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(file.path,
                    style: const TextStyle(
                        color: Color(0xFF3ECFCF), fontSize: 10)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK',
                      style: TextStyle(color: Color(0xFF6C63FF)))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isExporting = false);
  }

  @override
  void dispose() {
    _renderCtrl.dispose();
    _timeline.removeListener(_onTimelineChange);
    _timeline.dispose();
    _promptCtrl.dispose();
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
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF3ECFCF)),
              onPressed: _saveProject),
          IconButton(
              icon: const Icon(Icons.folder_open, color: Colors.grey),
              onPressed: _loadProject),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.file_download, color: Color(0xFFFFD700)),
            onPressed: _isExporting ? null : _exportHTML,
          ),
        ],
      ),
      body: Column(children: [
        // VIEWPORT
        Expanded(flex: 5, child: _buildViewport()),
        // CONTROLS
        _buildControls(),
        // PROMPT
        _buildPromptBar(),
        // SCENE LIST
        Expanded(flex: 4, child: _buildSceneList()),
      ]),
    );
  }

  Widget _buildViewport() {
    final scene = _timeline.currentScene;
    return GestureDetector(
      onTapDown: (d) {
        final scene = _timeline.currentScene;
        final type = (scene?.background == BackgroundType.volcano ||
                scene?.background == BackgroundType.battlefield)
            ? ParticleType.explosion
            : ParticleType.magic;
        _triggerEffect(type, d.localPosition.dx, d.localPosition.dy);
      },
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(_cameraShake, _cameraShake * 0.4),
          child: Transform.scale(
            scale: _cameraZoom,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: scene == null
                  ? const Center(
                      child: Text('Add a scene to begin',
                          style: TextStyle(color: Colors.grey)))
                  : Stack(children: [
                      // Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BackgroundPainter(
                            type: scene.background,
                            timeOfDay: scene.timeOfDay,
                            weather: scene.weather,
                            animProgress: _bgAnim,
                            parallaxOffset: _parallax,
                          ),
                        ),
                      ),
                      // Particles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ParticlePainter(particles: _particles),
                        ),
                      ),
                      // Characters
                      Positioned.fill(child: _buildCharactersLayer(scene)),
                      // UI overlay
                      _buildViewportOverlay(scene),
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharactersLayer(StoryScene scene) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: scene.characters.map((char) {
          final size = constraints.maxHeight * 0.38 * char.scale;
          final x = constraints.maxWidth * char.positionX - size / 2;
          final y = constraints.maxHeight * char.positionY - size;
          return Positioned(
            left: x,
            top: y,
            child: Column(
              children: [
                // Dialogue bubble
                if (_showSubtitles && char.dialogue.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.38),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(
                            char.facingRight ? 14 : 2),
                        bottomRight: Radius.circular(
                            char.facingRight ? 2 : 14),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Text(
                      char.dialogue,
                      style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Character
                AnimatedCharacterWidget(
                  characterId: char.characterId,
                  state: char.state,
                  size: size,
                  facingRight: char.facingRight,
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildViewportOverlay(StoryScene scene) {
    return Stack(children: [
      // Scene info
      Positioned(
        top: 8,
        left: 12,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            'Scene ${_timeline.currentSceneIndex + 1}/${_timeline.scenes.length} • ${scene.background.name}',
            style:
                const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
      // Timer
      Positioned(
        top: 8,
        right: 12,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            '${(_timeline.sceneProgress * scene.durationSeconds).toStringAsFixed(1)}s / ${scene.durationSeconds}s',
            style:
                const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
      // Narration
      if (_showSubtitles && scene.narration.isNotEmpty)
        Positioned(
          bottom: 3,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
            child: Text(
              scene.narration,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black)
                  ]),
            ),
          ),
        ),
      // Progress bar
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: LinearProgressIndicator(
          value: _timeline.sceneProgress,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF6C63FF)),
          minHeight: 2,
        ),
      ),
    ]);
  }

  Widget _buildControls() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0D0D1A),
      child: Row(children: [
        _ctrlBtn(Icons.skip_previous, _timeline.prevScene),
        const SizedBox(width: 6),
        _ctrlBtn(Icons.stop, _timeline.stop),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: _timeline.isPlaying
                ? _timeline.pause
                : _timeline.play,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Icon(
                _timeline.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              )),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ctrlBtn(Icons.skip_next, _timeline.nextScene),
        const SizedBox(width: 6),
        _ctrlBtn(
          _showSubtitles ? Icons.subtitles : Icons.subtitles_off,
          () => setState(() => _showSubtitles = !_showSubtitles),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _timeline.playbackSpeed =
              _timeline.playbackSpeed == 1.0 ? 2.0 : 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12)),
            child: Text('${_timeline.playbackSpeed}x',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildPromptBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'AI Director: "Dragon attacks cyberpunk city at night"',
              hintStyle: const TextStyle(
                  color: Colors.grey, fontSize: 11),
              filled: true,
              fillColor: const Color(0xFF12122A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isGenerating ? null : _generateFromPrompt,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
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
                characters: [
                  SceneCharacter(characterId: 'hero')
                ],
              ));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF6C63FF)),
                  SizedBox(width: 6),
                  Text('Add Scene',
                      style:
                          TextStyle(color: Color(0xFF6C63FF))),
                ],
              )),
            ),
          );
        }

        final scene = _timeline.scenes[i];
        final isSelected = i == _timeline.currentSceneIndex;

        return GestureDetector(
          onTap: () => _timeline.jumpToScene(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1E1E3A)
                  : const Color(0xFF12122A),
              border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: _bgColors(scene.background)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    scene.characters
                        .map((c) =>
                            CharacterRegistry.get(c.characterId)
                                ?.emoji ??
                            '')
                        .join(''),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Scene ${i + 1}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        _chip(scene.background.name,
                            const Color(0xFF6C63FF)),
                        const SizedBox(width: 4),
                        _chip(scene.timeOfDay.name,
                            const Color(0xFFFF922B)),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        scene.narration.isNotEmpty
                            ? scene.narration
                            : 'No narration',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
              ),
              Text('${scene.durationSeconds}s',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 8),
              Column(children: [
                GestureDetector(
                  onTap: () => _editScene(i),
                  child: const Icon(Icons.edit,
                      color: Color(0xFF6C63FF), size: 18),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _timeline.removeScene(i),
                  child: const Icon(Icons.delete,
                      color: Colors.red, size: 18),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(5),
        ),
        child:
            Text(text, style: TextStyle(color: color, fontSize: 9)),
      );

  List<Color> _bgColors(BackgroundType t) {
    switch (t) {
      case BackgroundType.city:
        return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
      case BackgroundType.cyberpunk:
        return [const Color(0xFF1A0033), const Color(0xFF2D004D)];
      case BackgroundType.forest:
        return [const Color(0xFF0D2818), const Color(0xFF1A4731)];
      case BackgroundType.space:
        return [const Color(0xFF000011), const Color(0xFF0A0A2E)];
      case BackgroundType.underwater:
        return [const Color(0xFF006994), const Color(0xFF001F3F)];
      case BackgroundType.volcano:
        return [const Color(0xFF3D0000), const Color(0xFF7A1500)];
      case BackgroundType.castle:
        return [const Color(0xFF1C1C1C), const Color(0xFF2D2D2D)];
      case BackgroundType.battlefield:
        return [const Color(0xFF2D2D1A), const Color(0xFF4A4A2E)];
      case BackgroundType.beach:
        return [const Color(0xFF006994), const Color(0xFFF5DEB3)];
      case BackgroundType.snow:
        return [const Color(0xFFE3F2FD), const Color(0xFF2C3E50)];
      case BackgroundType.desert:
        return [const Color(0xFFD2691E), const Color(0xFFC19A6B)];
      case BackgroundType.fantasy:
        return [const Color(0xFF4A0080), const Color(0xFF1A0050)];
      default:
        return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    }
  }

  void _editScene(int index) {
    final scene = _timeline.scenes[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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
        title: const Text('Rename Project',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFF1A1A2E),
            border: OutlineInputBorder(),
            hintText: 'Project name...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                setState(() => _projectName = ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: Color(0xFF6C63FF)))),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      );

  String _buildCinematicHTML() {
    final scenesData =
        _timeline.scenes.map((s) => s.toJson()).toList();
    final scenesJson = jsonEncode(scenesData);

    return '''<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>$_projectName</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;overflow:hidden;width:100vw;height:100vh}
canvas{display:block}
#ui{position:fixed;bottom:0;left:0;right:0;padding:10px 16px;background:rgba(0,0,0,0.85);display:none;align-items:center;gap:10px}
.btn{background:rgba(255,255,255,0.1);border:1px solid rgba(255,255,255,0.2);color:#fff;padding:9px 15px;border-radius:20px;cursor:pointer;font-size:15px}
.btn.primary{background:linear-gradient(135deg,#6c63ff,#3ecfcf);border:none;padding:11px 28px;font-size:18px}
#pb{flex:1;height:3px;background:rgba(255,255,255,0.2);border-radius:2px;overflow:hidden}
#pf{height:100%;background:linear-gradient(90deg,#6c63ff,#3ecfcf);width:0%;transition:width .1s}
#ts{position:fixed;inset:0;background:linear-gradient(135deg,#0a0a14,#1a1a2e);display:flex;flex-direction:column;align-items:center;justify-content:center;color:#fff;z-index:10}
#ts h1{font-size:clamp(22px,6vw,46px);background:linear-gradient(135deg,#6c63ff,#3ecfcf);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:8px;text-align:center}
#sb{margin-top:28px;padding:14px 38px;border-radius:30px;border:none;font-size:17px;font-weight:bold;cursor:pointer;background:linear-gradient(135deg,#6c63ff,#3ecfcf);color:#fff}
</style>
</head><body>
<div id="ts">
  <div style="font-size:60px;margin-bottom:12px">🎬</div>
  <h1>$_projectName</h1>
  <p style="color:#888">${_timeline.scenes.length} cinematic scenes</p>
  <button id="sb" onclick="startMovie()">▶ Play Movie</button>
</div>
<canvas id="c"></canvas>
<div id="ui">
  <button class="btn" onclick="prev()">⏮</button>
  <button class="btn primary" id="pb2" onclick="togglePlay()">⏸</button>
  <button class="btn" onclick="next()">⏭</button>
  <div id="pb"><div id="pf"></div></div>
  <button class="btn" id="sb2" onclick="toggleSub()">💬</button>
</div>
<script>
const SCENES=${scenesJson};
const C=document.getElementById('c');
const X=C.getContext('2d');
let W,H,cur=0,playing=true,showSub=true,elapsed=0,tick=0,last=0;
const particles=[];

function resize(){
  W=C.width=window.innerWidth;
  H=C.height=window.innerHeight-52;
}
window.addEventListener('resize',resize);

function startMovie(){
  document.getElementById('ts').style.display='none';
  document.getElementById('ui').style.display='flex';
  resize();
  requestAnimationFrame(loop);
}

function loop(ts){
  requestAnimationFrame(loop);
  const dt=Math.min((ts-last)/1000,.05);last=ts;
  if(playing){elapsed+=dt;tick+=dt;}
  const sc=SCENES[cur];
  if(sc&&elapsed>=sc.durationSeconds){
    elapsed=0;
    if(cur<SCENES.length-1)cur++;
    else{playing=false;document.getElementById('pb2').textContent='▶';}
  }
  render(dt);
  document.getElementById('pf').style.width=((cur/SCENES.length)*100)+'%';
}

function render(dt){
  X.clearRect(0,0,W,H);
  const sc=SCENES[cur];
  if(!sc)return;
  drawBg(sc);
  updateParticles(dt);
  renderParticles();
  drawCharacters(sc);
  if(showSub)drawSubs(sc);
  drawVignette();
}

// ── BACKGROUNDS ──────────────────────────────────────────
function drawBg(sc){
  const bg=sc.background,tod=sc.timeOfDay;
  drawSky(bg,tod);
  switch(bg){
    case'city':case'cyberpunk':drawCity(bg==='cyberpunk',tod);break;
    case'forest':case'jungle':drawForest();break;
    case'space':drawSpace();break;
    case'underwater':drawUnderwater();break;
    case'volcano':drawVolcano();break;
    case'castle':drawCastle();break;
    case'beach':drawBeach();break;
    case'snow':drawSnow();break;
    case'desert':drawDesert();break;
    case'battlefield':drawBattlefield();break;
    case'fantasy':drawFantasy();break;
    default:drawCity(false,tod);
  }
  if(tod==='night')drawStars();
  if(tod==='day'||tod==='sunset')drawClouds();
}

function drawSky(bg,tod){
  const skies={
    day:['#4FC3F7','#0288D1'],sunset:['#FF7043','#880E4F'],night:['#0A0A2E','#1A1A4E']
  };
  const c=skies[tod]||skies.day;
  const g=X.createLinearGradient(0,0,0,H*.65);
  g.addColorStop(0,c[0]);g.addColorStop(1,c[1]);
  X.fillStyle=g;X.fillRect(0,0,W,H*.65);
  if(tod!=='night'){
    const sc=tod==='sunset'?'#FF7043':'#FFEB3B';
    X.shadowColor=sc;X.shadowBlur=25;
    X.fillStyle=sc;X.beginPath();X.arc(W*.14,H*.13,20,0,Math.PI*2);X.fill();
    X.shadowBlur=0;
  } else {
    X.fillStyle='#FFF9C4';X.beginPath();X.arc(W*.8,H*.13,22,0,Math.PI*2);X.fill();
    X.fillStyle='#0A0A2E';X.beginPath();X.arc(W*.83,H*.12,19,0,Math.PI*2);X.fill();
  }
}

function drawStars(){
  const pts=[[.05,.04],[.15,.1],[.25,.03],[.38,.08],[.5,.02],[.62,.09],[.74,.05],[.85,.11],[.93,.04],[.1,.18],[.3,.16],[.55,.19],[.78,.15]];
  pts.forEach(([px,py])=>{
    const tw=Math.sin(tick*4+px*10)>.3;
    X.fillStyle=`rgba(255,255,255,${tw?.9:.5})`;
    X.beginPath();X.arc(px*W,py*H,tw?2.5:1.5,0,Math.PI*2);X.fill();
  });
}

function drawClouds(){
  X.fillStyle='rgba(255,255,255,0.82)';
  [[.1,.08,80,32],[.45,.11,100,38],[.75,.07,70,28]].forEach(([cx,cy,cw,ch])=>{
    X.beginPath();X.ellipse(cx*W,cy*H,cw/2,ch/2,0,0,Math.PI*2);X.fill();
    X.beginPath();X.ellipse(cx*W-22,cy*H+6,cw*.3,ch*.33,0,0,Math.PI*2);X.fill();
    X.beginPath();X.ellipse(cx*W+26,cy*H+6,cw*.35,ch*.35,0,0,Math.PI*2);X.fill();
  });
}

function drawCity(cyber,tod){
  X.fillStyle=cyber?'#0D0020':'#3D3D3D';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle=cyber?'#1A0033':'#2A2A2A';X.fillRect(0,H*.77,W,H*.23);
  X.strokeStyle='rgba(255,255,255,.45)';X.lineWidth=2;
  for(let bx=0;bx<W+60;bx+=60){X.beginPath();X.moveTo(bx,H*.885);X.lineTo(bx+38,H*.885);X.stroke();}
  [[0,.38,.11],[.12,.26,.09],[.23,.42,.10],[.35,.2,.10],[.47,.35,.11],[.6,.28,.09],[.71,.44,.10],[.83,.22,.11],[.91,.33,.10]].forEach(([bx2,bh2,bw2])=>{
    const bx=bx2*W,bw=bw2*W,bh=bh2*H,by=H*.63-bh;
    X.fillStyle=cyber?`hsl(${270+bx2*30},50%,${8+bx2*8}%)`:`hsl(${220+bx2*20},10%,${20+bx2*10}%)`;
    X.fillRect(bx,by,bw,bh);
    const wc=cyber?`hsla(${bx2*360|0},100%,60%,.75)`:'rgba(255,230,100,.7)';
    for(let r=0;r<7;r++)for(let c=0;c<3;c++){
      if((r+c+(bx|0))%3!==0){X.fillStyle=wc;X.fillRect(bx+bw*.12+c*bw*.28,by+bh*.07+r*bh*.12,bw*.15,bh*.07);}
    }
    if(cyber){X.strokeStyle='rgba(0,255,255,.5)';X.lineWidth=1.5;X.beginPath();X.moveTo(bx,by);X.lineTo(bx+bw,by);X.stroke();}
  });
}

function drawForest(){
  X.fillStyle='#2E5D27';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle='#4CAF50';X.fillRect(0,H*.63,W,H*.04);
  for(let x=-80;x<W+80;x+=65)drawTree(x,H*.65,28,75,'#1B5E20','#2E7D32');
  for(let x=-50;x<W+50;x+=85)drawTree(x+32,H*.67,38,95,'#388E3C','#43A047');
}

function drawTree(x,y,w,h,d,l){
  X.fillStyle='#5D4037';X.fillRect(x-w*.11,y-h*.28,w*.22,h*.28);
  X.fillStyle=d;X.beginPath();X.moveTo(x,y-h);X.lineTo(x+w*.6,y-h*.44);X.lineTo(x-w*.6,y-h*.44);X.fill();
  X.fillStyle=l;X.beginPath();X.moveTo(x,y-h*.65);X.lineTo(x+w*.72,y-h*.22);X.lineTo(x-w*.72,y-h*.22);X.fill();
}

function drawSpace(){
  X.fillStyle='#000011';X.fillRect(0,0,W,H);
  const gn=X.createRadialGradient(W*.3,H*.3,10,W*.3,H*.3,W*.4);
  gn.addColorStop(0,'rgba(74,0,224,.12)');gn.addColorStop(1,'transparent');
  X.fillStyle=gn;X.fillRect(0,0,W,H);
  X.fillStyle='#1A1A3E';X.fillRect(0,H*.7,W,H*.3);
  X.fillStyle='rgba(255,255,255,.08)';X.beginPath();X.ellipse(W/2,H*.7,W*.6,H*.07,0,0,Math.PI*2);X.fill();
}

function drawUnderwater(){
  const g=X.createLinearGradient(0,0,0,H);
  g.addColorStop(0,'#006994');g.addColorStop(1,'#001F3F');
  X.fillStyle=g;X.fillRect(0,0,W,H);
  X.fillStyle='#C2A35A';X.fillRect(0,H*.75,W,H*.25);
  for(let cx=-40;cx<W+40;cx+=80){
    const cc=['#FF6B6B','#FF8E53','#FF006E'][(cx/40|0)%3];
    X.fillStyle=cc;
    X.fillRect(cx-4,H*.76-H*.15,8,H*.15);
    X.beginPath();X.arc(cx,H*.76-H*.15,10,0,Math.PI*2);X.fill();
    X.beginPath();X.arc(cx-9,H*.76-H*.1,7,0,Math.PI*2);X.fill();
    X.beginPath();X.arc(cx+9,H*.76-H*.09,8,0,Math.PI*2);X.fill();
  }
  X.strokeStyle='rgba(255,255,255,.25)';X.lineWidth=1.5;
  for(let i=0;i<8;i++){X.beginPath();X.arc(W*(i/8)+(tick*20%30),H*(.3+(i*.07)%.4),3.5+(i%3)*2,0,Math.PI*2);X.stroke();}
}

function drawVolcano(){
  X.fillStyle='#3D0000';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle='#4A0000';X.beginPath();X.moveTo(W*.35,H*.63);X.lineTo(W*.5,H*.22);X.lineTo(W*.65,H*.63);X.fill();
  X.shadowColor='#FF4500';X.shadowBlur=20;
  X.fillStyle='rgba(255,69,0,.8)';X.beginPath();X.arc(W*.5,H*.25,20,0,Math.PI*2);X.fill();
  X.shadowBlur=0;
  X.fillStyle='rgba(255,109,0,.85)';X.fillRect(W*.46,H*.28,W*.08,H*.35);
  if(Math.random()<.15)emitParticle('fire',W*.5,H*.27);
}

function drawCastle(){
  X.fillStyle='#3A3A3A';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle='#585858';X.fillRect(W*.28,H*.2,W*.44,H*.43);
  X.fillStyle='#4A4A4A';X.fillRect(W*.13,H*.33,W*.16,H*.3);X.fillRect(W*.71,H*.33,W*.16,H*.3);
  for(let bx=W*.28;bx<W*.72;bx+=W*.06){X.fillStyle='#585858';X.fillRect(bx,H*.15,W*.04,H*.06);}
  X.fillStyle='#1A1A1A';X.beginPath();X.ellipse(W*.5,H*.535,W*.08,H*.085,0,Math.PI,0);X.fill();
  X.strokeStyle='#888';X.lineWidth=2;X.beginPath();X.moveTo(W*.5,H*.2);X.lineTo(W*.5,H*.08);X.stroke();
  X.fillStyle='red';X.beginPath();X.moveTo(W*.5,H*.08);X.lineTo(W*.63,H*.12);X.lineTo(W*.5,H*.17);X.fill();
}

function drawBeach(){
  X.fillStyle='#0099CC';X.fillRect(0,H*.45,W,H*.3);
  X.fillStyle='#F5DEB3';X.fillRect(0,H*.72,W,H*.28);
  X.strokeStyle='rgba(255,255,255,.45)';X.lineWidth=2;
  for(let i=0;i<3;i++){
    X.beginPath();X.moveTo(0,H*(.57+i*.04));
    for(let wx=0;wx<W;wx+=40)X.quadraticCurveTo(wx+20,H*(.565+i*.04),wx+40,H*(.57+i*.04));
    X.stroke();
  }
}

function drawSnow(){
  X.fillStyle='#fff';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle='#E3F2FD';
  X.beginPath();X.ellipse(W*.2,H*.58,W*.28,H*.1,0,0,Math.PI*2);X.fill();
  X.beginPath();X.ellipse(W*.8,H*.57,W*.3,H*.1,0,0,Math.PI*2);X.fill();
  for(let x=-50;x<W+50;x+=95){
    X.fillStyle='#5D4037';X.fillRect(x-4,H*.65-20,8,20);
    X.fillStyle='#1B5E20';X.beginPath();X.moveTo(x,H*.65-85);X.lineTo(x+32,H*.65-20);X.lineTo(x-32,H*.65-20);X.fill();
    X.fillStyle='rgba(255,255,255,.85)';X.beginPath();X.moveTo(x,H*.65-85);X.lineTo(x+20,H*.65-52);X.lineTo(x-20,H*.65-52);X.fill();
  }
}

function drawDesert(){
  const g=X.createLinearGradient(0,H*.5,0,H);
  g.addColorStop(0,'#D2691E');g.addColorStop(1,'#C19A6B');
  X.fillStyle=g;X.fillRect(0,H*.5,W,H*.5);
  X.fillStyle='#DEB887';
  for(let dx=0;dx<W+100;dx+=200){X.beginPath();X.ellipse(dx,H*.65,100,35,0,0,Math.PI*2);X.fill();}
  [W*.2,W*.75].forEach(cx=>{
    X.fillStyle='#228B22';
    X.fillRect(cx-6,H*.65-62,12,62);
    X.fillRect(cx-22,H*.65-42,15,8);X.fillRect(cx-22,H*.65-52,8,22);
    X.fillRect(cx+8,H*.65-36,15,8);X.fillRect(cx+14,H*.65-49,8,22);
    X.beginPath();X.arc(cx,H*.65-62,10,0,Math.PI*2);X.fill();
  });
}

function drawBattlefield(){
  X.fillStyle='#2D2D1A';X.fillRect(0,H*.63,W,H*.37);
  X.fillStyle='#1A1A0D';
  for(let i=0;i<4;i++){X.beginPath();X.arc(W*(.15+i*.22),H*.7,18,0,Math.PI*2);X.fill();}
  X.fillStyle='#4A3728';
  for(let i=0;i<3;i++)X.fillRect(W*(.2+i*.28),H*.65,W*.08,H*.05);
  X.fillStyle='rgba(100,100,100,.18)';X.filter='blur(20px)';
  X.beginPath();X.arc(W*.3,H*.4,50,0,Math.PI*2);X.fill();
  X.beginPath();X.arc(W*.7,H*.35,40,0,Math.PI*2);X.fill();
  X.filter='none';
}

function drawFantasy(){
  const g=X.createLinearGradient(0,0,0,H*.65);
  g.addColorStop(0,'#4A0080');g.addColorStop(1,'#1A0050');
  X.fillStyle=g;X.fillRect(0,0,W,H*.65);
  X.fillStyle='#0D0025';X.fillRect(0,H*.63,W,H*.37);
  const mc=['#AA00FF','#00E5FF','#FFD700'];
  for(let i=0;i<12;i++){
    X.fillStyle=mc[i%3]+'66';
    X.beginPath();X.arc(W*((i*.087+tick*.01)%1),H*(.1+(i*.065)%.5),(4+(i%3)*2.5),0,Math.PI*2);X.fill();
  }
  X.fillStyle='rgba(123,0,255,.22)';X.fillRect(0,H*.6,W,H*.1);
}

// ── PARTICLES ───────────────────────────────────────────
function emitParticle(type,px,py,count=1){
  for(let i=0;i<count;i++){
    let p={type,x:px,y:py,vx:0,vy:0,life:1,maxLife:1,size:8,color:'#FF4500',alpha:1};
    const R=()=>Math.random();
    switch(type){
      case'fire':p.vx=(R()-.5)*40;p.vy=-(R()*60+40);p.life=p.maxLife=R()*.8+.3;p.size=R()*16+8;p.color=['#FF6D00','#FF3D00','#FFD600','#FF1744'][0|(R()*4)];break;
      case'smoke':p.vx=(R()-.5)*20;p.vy=-(R()*30+10);p.life=p.maxLife=R()*1.5+.5;p.size=R()*25+10;p.alpha=R()*.3+.1;p.color='rgb(140,140,140)';break;
      case'explosion':{const a=R()*Math.PI*2,s=R()*200+100;p.vx=Math.cos(a)*s;p.vy=Math.sin(a)*s-100;p.life=p.maxLife=R()*.6+.2;p.size=R()*14+4;p.color=['#FF6D00','#FFD600','#FF1744','#FFF'][0|(R()*4)];break;}
      case'magic':p.vx=(R()-.5)*30;p.vy=-(R()*50+20);p.life=p.maxLife=R()+.4;p.size=R()*8+3;p.color=['#AA00FF','#E040FB','#7C4DFF','#00E5FF'][0|(R()*4)];break;
      case'sparks':{const a=R()*Math.PI*2,s=R()*150+50;p.vx=Math.cos(a)*s;p.vy=Math.sin(a)*s-80;p.life=p.maxLife=R()*.3+.1;p.size=R()*4+2;p.color=['yellow','orange','white'][0|(R()*3)];break;}
    }
    particles.push(p);
  }
}

function updateParticles(dt){
  for(let i=particles.length-1;i>=0;i--){
    const p=particles[i];
    p.life-=dt;
    if(p.life<=0||p.size<.5){particles.splice(i,1);continue;}
    p.x+=p.vx*dt;p.y+=p.vy*dt;
    if(p.type==='fire'){p.vy-=80*dt;p.vx+=(Math.random()-.5)*30*dt;p.size*=(1-dt*.8);}
    if(p.type==='smoke'){p.vy-=20*dt;p.size*=(1+dt*.3);}
    if(p.type==='explosion')p.vy+=150*dt;
    if(p.type==='magic')p.vy-=40*dt;
    if(p.type==='sparks')p.vy+=200*dt;
  }
}

function renderParticles(){
  particles.forEach(p=>{
    const al=(p.life/p.maxLife);
    X.save();
    X.globalAlpha=al*(p.alpha||1);
    if(p.type==='fire'||p.type==='magic'){X.shadowColor=p.color;X.shadowBlur=p.size*.8;}
    X.fillStyle=p.color;
    X.beginPath();X.arc(p.x,p.y,p.size/2,0,Math.PI*2);X.fill();
    X.restore();
  });
}

// ── CHARACTERS ──────────────────────────────────────────
const CHARS={
  hero:{emoji:'🦸',color:'#6C63FF'},villain:{emoji:'🦹',color:'#FF1744'},
  robot:{emoji:'🤖',color:'#00E676'},wizard:{emoji:'🧙',color:'#CC5DE8'},
  ninja:{emoji:'🥷',color:'#546E7A'},dragon:{emoji:'🐲',color:'#FF6D00'},
  princess:{emoji:'👸',color:'#FF80AB'},warrior:{emoji:'⚔️',color:'#BDB76B'},
  alien:{emoji:'👽',color:'#69F0AE'},zombie:{emoji:'🧟',color:'#558B2F'},
  knight:{emoji:'🛡️',color:'#90A4AE'},archer:{emoji:'🏹',color:'#A1887F'}
};

function drawCharacters(sc){
  (sc.characters||[]).forEach(ch=>drawChar(ch));
}

// Character color palettes
const PALETTES={
  hero:{body:'#1565C0',skin:'#FFCC80',hair:'#4E342E',accent:'#FFD600'},
  villain:{body:'#4A0000',skin:'#B0BEC5',hair:'#212121',accent:'#FF1744'},
  robot:{body:'#37474F',skin:'#607D8B',hair:'#263238',accent:'#00E5FF'},
  wizard:{body:'#4A148C',skin:'#FFDBAC',hair:'#E0E0E0',accent:'#AA00FF'},
  ninja:{body:'#212121',skin:'#FFCC80',hair:'#212121',accent:'#FF1744'},
  princess:{body:'#AD1457',skin:'#FFDBAC',hair:'#FFD600',accent:'#FF80AB'},
  warrior:{body:'#4E342E',skin:'#FFCC80',hair:'#4E342E',accent:'#FFD600'},
  alien:{body:'#1B5E20',skin:'#69F0AE',hair:'#004D40',accent:'#00E5FF'},
  zombie:{body:'#33691E',skin:'#8D9A4A',hair:'#212121',accent:'#76FF03'},
  dragon:{body:'#7B1FA2',skin:'#9C27B0',hair:'#4A148C',accent:'#FF6D00'}
};

function drawChar(ch){
  const pal=PALETTES[ch.characterId]||PALETTES.hero;
  const cx=ch.positionX*W,cy=ch.positionY*H;
  const sz=H*.32*(ch.scale||1);
  const st=ch.state||'idle';
  X.save();
  X.translate(cx,cy);
  if(!ch.facingRight)X.scale(-1,1);

  // Shadow
  X.fillStyle='rgba(0,0,0,.22)';
  X.beginPath();X.ellipse(0,sz*.18,sz*.22,sz*.055,0,0,Math.PI*2);X.fill();

  // State transforms
  let dy=0,sx2=1,sy2=1,rot=0,glow=null;
  let ll=0,rl=0,la=0,ra=0,mo=0;
  const s=Math.sin,pi=Math.PI;
  switch(st){
    case'idle':dy=s(tick*pi*2)*sz*.015;break;
    case'walk':dy=Math.abs(s(tick*pi*4))*sz*.01;rot=s(tick*pi*2)*.04;ll=s(tick*pi*2)*.5;rl=-s(tick*pi*2)*.5;la=-s(tick*pi*2)*.4;ra=s(tick*pi*2)*.4;break;
    case'run':dy=Math.abs(s(tick*pi*6))*sz*.02;rot=s(tick*pi*4)*.07;ll=s(tick*pi*4)*.8;rl=-s(tick*pi*4)*.8;la=-s(tick*pi*4)*.7;ra=s(tick*pi*4)*.7;sx2=1+Math.abs(s(tick*pi*4))*.06;break;
    case'attack':rot=s(tick*pi*3)*.18;ra=-pi/2+s(tick*pi*3)*.8;la=.3;glow=pal.accent;break;
    case'jump':dy=-Math.abs(s(tick*pi))*sz*.22;sx2=1+s(tick*pi)*.08;sy2=1-s(tick*pi)*.08;ll=-.4;rl=-.4;la=-.5;ra=.5;break;
    case'fly':dy=s(tick*pi*2)*sz*.03;rot=-.12;la=-pi/4+s(tick*pi*2)*.2;ra=pi/4-s(tick*pi*2)*.2;glow=pal.accent;break;
    case'talk':dy=s(tick*pi*3)*sz*.008;mo=Math.abs(s(tick*pi*6));la=s(tick*pi*2)*.2;break;
    case'angry':rot=s(tick*pi*8)*.04;la=-.3;ra=.3;glow='#FF1744';break;
    case'happy':dy=-Math.abs(s(tick*pi*2))*sz*.04;sx2=1+Math.abs(s(tick*pi*2))*.06;la=-.7;ra=.7;break;
    case'sad':dy=sz*.02;rot=.04;la=.2;ra=-.2;break;
    case'victory':dy=-Math.abs(s(tick*pi*2))*sz*.06;la=-pi/2;ra=pi/2;glow='#FFD700';break;
    case'death':rot=Math.min(tick*.8,1)*pi*.5;dy=Math.min(tick*.8,1)*sz*.35;sy2=Math.max(.4,1-tick*.4);break;
    case'cast':rot=s(tick*pi*2)*.1;ra=-pi/2+s(tick*pi*3)*.3;la=.2;glow='#AA00FF';break;
    case'defend':sx2=.88;la=-.1;ra=-pi/2;glow='#4488FF';break;
  }
  X.translate(0,dy);X.rotate(rot);X.scale(sx2,sy2);
  if(glow){X.shadowColor=glow;X.shadowBlur=20;}
  if(ch.characterId==='robot')drawRobotBody(X,pal,sz,st,ll,rl,la,ra,mo);
  else if(ch.characterId==='dragon')drawDragonBody(X,pal,sz,st,ll,rl,la,ra,mo);
  else drawHumanBody(X,pal,sz,st,ch.characterId,ll,rl,la,ra,mo);
  X.shadowBlur=0;
  X.restore();
  if(ch.dialogue&&showSub)drawBubble(ch.dialogue,cx,cy-sz*.95,ch.facingRight);
}

function drawHumanBody(ctx,pal,sz,st,type,ll,rl,la,ra,mo){
  const bw=sz*.38,bh=sz*.32,lw=sz*.11,lh=sz*.22,aw=sz*.10,ah=sz*.24,hr=sz*.22;
  // Legs
  [[-1,ll],[1,rl]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.28,bh*.5);ctx.rotate(a);
    const lg=ctx.createLinearGradient(0,0,0,lh);
    lg.addColorStop(0,pal.body);lg.addColorStop(1,pal.body+'BB');
    ctx.fillStyle=lg;roundRect(ctx,-lw/2,0,lw,lh,lw/2);ctx.fill();
    ctx.fillStyle='#222';roundRect(ctx,-lw*.8,lh-lw*.4,lw*1.8,lw*.7,lw*.4);ctx.fill();
    ctx.restore();
  });
  // Body
  const bg2=ctx.createLinearGradient(-bw*.5,-bh*.5,bw*.5,bh*.5);
  bg2.addColorStop(0,pal.body+'DD');bg2.addColorStop(1,pal.body);
  ctx.fillStyle=bg2;roundRect(ctx,-bw/2,-bh/2,bw,bh,bw*.25);ctx.fill();
  ctx.strokeStyle='rgba(0,0,0,.15)';ctx.lineWidth=1.5;roundRect(ctx,-bw/2,-bh/2,bw,bh,bw*.25);ctx.stroke();
  // Accessories
  if(type==='hero'){
    // Cape
    ctx.fillStyle=pal.accent+'CC';
    ctx.beginPath();ctx.moveTo(-bw*.45,-bh*.3);ctx.quadraticCurveTo(-bw*.8,bh*.4,-bw*.3,bh*.55);ctx.lineTo(-bw*.45,-bh*.3);ctx.fill();
    // Star
    drawStarShape(ctx,0,-bh*.05,bw*.1,pal.accent);
  } else if(type==='wizard'){
    ctx.fillStyle=pal.accent+'88';roundRect(ctx,-bw/2,bh*.0,bw,bh*.12,4);ctx.fill();
  } else if(type==='warrior'){
    ctx.fillStyle='#9E9E9E';roundRect(ctx,-bw*.35,-bh*.45,bw*.7,bh*.7,6);ctx.fill();
    ctx.strokeStyle='rgba(0,0,0,.2)';ctx.lineWidth=1.5;roundRect(ctx,-bw*.35,-bh*.45,bw*.7,bh*.7,6);ctx.stroke();
  } else if(type==='villain'){
    ctx.fillStyle='#1A0000CC';
    ctx.beginPath();ctx.moveTo(-bw*.5,-bh*.35);ctx.quadraticCurveTo(-bw*.9,bh*.5,-bw*.2,bh*.55);ctx.lineTo(-bw*.5,-bh*.35);ctx.fill();
    ctx.fillStyle=pal.accent;ctx.beginPath();ctx.arc(0,-bh*.05,bw*.08,0,Math.PI*2);ctx.fill();
  }
  // Arms
  [[-1,la],[1,ra]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.52,-bh*.1);ctx.rotate(a);
    const ag=ctx.createLinearGradient(0,0,0,ah);
    ag.addColorStop(0,pal.body);ag.addColorStop(1,pal.skin);
    ctx.fillStyle=ag;roundRect(ctx,-aw/2,0,aw,ah,aw/2);ctx.fill();
    ctx.fillStyle=pal.skin;ctx.beginPath();ctx.arc(0,ah+aw*.15,aw*.5,0,Math.PI*2);ctx.fill();
    ctx.restore();
  });
  // Neck
  ctx.fillStyle=pal.skin;roundRect(ctx,-bw*.1,-bh*.52,bw*.2,bh*.12,4);ctx.fill();
  // Head
  ctx.fillStyle=pal.skin;ctx.beginPath();ctx.ellipse(0,-bh*.88,hr,hr*.88,0,0,Math.PI*2);ctx.fill();
  ctx.strokeStyle='rgba(0,0,0,.12)';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(0,-bh*.88,hr,hr*.88,0,0,Math.PI*2);ctx.stroke();
  // Hair
  ctx.fillStyle=pal.hair;
  ctx.beginPath();ctx.ellipse(0,-bh*.88,hr*1.02,hr*.88,0,-Math.PI,0);ctx.fill();
  roundRect(ctx,-hr*.95,-bh*.88-hr*.1,hr*.2,hr*.5,4);ctx.fill();
  roundRect(ctx,hr*.75,-bh*.88-hr*.1,hr*.2,hr*.5,4);ctx.fill();
  // Type head accessories
  if(type==='princess'){
    // Crown
    ctx.fillStyle='#FFD600';
    ctx.beginPath();ctx.moveTo(-hr*.5,-bh*.88-hr);ctx.lineTo(-hr*.5,-bh*.88-hr*1.35);ctx.lineTo(-hr*.25,-bh*.88-hr*1.18);ctx.lineTo(0,-bh*.88-hr*1.48);ctx.lineTo(hr*.25,-bh*.88-hr*1.18);ctx.lineTo(hr*.5,-bh*.88-hr*1.35);ctx.lineTo(hr*.5,-bh*.88-hr);ctx.closePath();ctx.fill();
    [-.25,0,.25].forEach(gx=>{ctx.fillStyle=pal.accent;ctx.beginPath();ctx.arc(gx*hr*2,-bh*.88-hr*1.05,hr*.07,0,Math.PI*2);ctx.fill();});
  } else if(type==='hero'){
    ctx.fillStyle=pal.body+'BB';roundRect(ctx,-hr,-bh*.88-hr*.17,hr*2,hr*.35,hr*.1);ctx.fill();
  } else if(type==='ninja'){
    ctx.fillStyle=pal.accent;roundRect(ctx,-hr,-bh*.88-hr*.25,hr*2,hr*.22,4);ctx.fill();
    ctx.fillStyle='#111';roundRect(ctx,-hr,-bh*.88+hr*.14,hr*2,hr*.5,4);ctx.fill();
  } else if(type==='wizard'){
    ctx.fillStyle=pal.body;
    ctx.beginPath();ctx.moveTo(-hr*.55,-bh*.88-hr*.8);ctx.lineTo(0,-bh*.88-hr*2.15);ctx.lineTo(hr*.55,-bh*.88-hr*.8);ctx.closePath();ctx.fill();
    ctx.fillStyle=pal.body+'88';roundRect(ctx,-hr*.7,-bh*.88-hr*.85,hr*1.4,hr*.22,hr*.08);ctx.fill();
    drawStarShape(ctx,0,-bh*.88-hr*1.55,hr*.12,pal.accent);
  } else if(type==='warrior'){
    ctx.fillStyle='#9E9E9E';
    ctx.beginPath();ctx.arc(0,-bh*.88+hr*.06,hr*1.08,-Math.PI*1.1,Math.PI*.1);ctx.fill();
  }
  // Eyes
  const hy=-bh*.88;
  [[-hr*.35,hy-hr*.05],[hr*.35,hy-hr*.05]].forEach(([ex,ey])=>{
    ctx.fillStyle='white';ctx.beginPath();ctx.ellipse(ex,ey,hr*.16,hr*.14,0,0,Math.PI*2);ctx.fill();
    ctx.fillStyle='#1565C0';ctx.beginPath();ctx.arc(ex,ey+hr*.02,hr*.1,0,Math.PI*2);ctx.fill();
    ctx.fillStyle='#111';ctx.beginPath();ctx.arc(ex,ey+hr*.02,hr*.055,0,Math.PI*2);ctx.fill();
    ctx.fillStyle='white';ctx.beginPath();ctx.arc(ex-hr*.04,ey-hr*.04,hr*.03,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='rgba(0,0,0,.25)';ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(ex,ey,hr*.16,hr*.14,0,0,Math.PI*2);ctx.stroke();
  });
  // Brows
  const bt=st==='angry'?.38:st==='sad'?-.28:0;
  [-1,1].forEach(s=>{
    ctx.save();ctx.translate(s*hr*.35,hy-hr*.22);ctx.rotate(s*bt);
    ctx.fillStyle=pal.hair;roundRect(ctx,-hr*.15,-hr*.035,hr*.3,hr*.07,3);ctx.fill();
    ctx.restore();
  });
  // Mouth
  const my2=hy+hr*.32;
  ctx.strokeStyle='#333';ctx.lineWidth=2;ctx.lineCap='round';
  if(st==='happy'||st==='victory'){
    ctx.beginPath();ctx.moveTo(-hr*.28,my2-hr*.04);ctx.quadraticCurveTo(0,my2+hr*.25,hr*.28,my2-hr*.04);ctx.stroke();
    ctx.fillStyle='white';roundRect(ctx,-hr*.18,my2-hr*.01,hr*.36,hr*.1,3);ctx.fill();
  } else if(st==='sad'){
    ctx.beginPath();ctx.moveTo(-hr*.24,my2+hr*.05);ctx.quadraticCurveTo(0,my2-hr*.12,hr*.24,my2+hr*.05);ctx.stroke();
  } else if(st==='angry'){
    ctx.beginPath();ctx.moveTo(-hr*.26,my2+hr*.02);ctx.lineTo(hr*.26,my2+hr*.02);ctx.stroke();
  } else if(st==='talk'){
    const oa=mo*hr*.15+hr*.04;
    ctx.fillStyle='#880E4F';ctx.beginPath();ctx.ellipse(0,my2,hr*.15,oa,0,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='#555';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(0,my2,hr*.15,oa,0,0,Math.PI*2);ctx.stroke();
    if(oa>hr*.05){ctx.fillStyle='rgba(255,255,255,.9)';roundRect(ctx,-hr*.12,my2-oa,hr*.24,hr*.06,2);ctx.fill();}
  } else {
    ctx.beginPath();ctx.moveTo(-hr*.18,my2);ctx.lineTo(hr*.18,my2);ctx.stroke();
  }
}

function drawRobotBody(ctx,pal,sz,st,ll,rl,la,ra,mo){
  const bw=sz*.4,bh=sz*.3,lw=sz*.13,lh=sz*.2,aw=sz*.11,ah=sz*.22,hw=sz*.42,hh=sz*.26;
  // Legs
  [[-1,ll],[1,rl]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.27,bh*.5);ctx.rotate(a);
    ctx.fillStyle=pal.body;roundRect(ctx,-lw/2,0,lw,lh,4);ctx.fill();
    ctx.fillStyle=pal.body+'BB';roundRect(ctx,-lw*.8,lh-lw*.4,lw*1.8,lw*.7,3);ctx.fill();
    ctx.restore();
  });
  // Body
  ctx.fillStyle=pal.body;roundRect(ctx,-bw/2,-bh/2,bw,bh,6);ctx.fill();
  ctx.fillStyle=pal.body+'88';roundRect(ctx,-bw*.3,-bh*.45,bw*.6,bh*.5,4);ctx.fill();
  ctx.fillStyle=pal.accent;ctx.shadowColor=pal.accent;ctx.shadowBlur=8;ctx.beginPath();ctx.arc(0,-bh*.08,bw*.08,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;
  [[-bw*.38,-bh*.3],[bw*.38,-bh*.3],[-bw*.38,bh*.25],[bw*.38,bh*.25]].forEach(([bx2,by2])=>{ctx.fillStyle=pal.accent+'99';ctx.beginPath();ctx.arc(bx2,by2,sz*.025,0,Math.PI*2);ctx.fill();});
  // Arms
  [[-1,la],[1,ra]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.55,-bh*.1);ctx.rotate(a);
    ctx.fillStyle=pal.body+'CC';roundRect(ctx,-aw/2,0,aw,ah,4);ctx.fill();
    ctx.fillStyle=pal.body;ctx.beginPath();ctx.arc(0,ah+aw*.2,aw*.5,0,Math.PI*2);ctx.fill();
    ctx.restore();
  });
  // Head
  ctx.fillStyle=pal.body;roundRect(ctx,-hw/2,-bh*.72-hh/2,hw,hh,8);ctx.fill();
  ctx.fillStyle=pal.accent+'44';roundRect(ctx,-hw*.375,-bh*.72-hh*.45,hw*.75,hh*.4,4);ctx.fill();
  const led=Math.abs(Math.sin(tick*Math.PI*4));
  [[-hw*.2,-bh*.72],[hw*.2,-bh*.72]].forEach(([ex,ey])=>{ctx.fillStyle=pal.accent+((0.6+led*.4)*255|0).toString(16).padStart(2,'0');ctx.shadowColor=pal.accent;ctx.shadowBlur=6;ctx.beginPath();ctx.ellipse(ex,ey,hw*.075,hh*.2,0,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;});
  ctx.fillStyle='#333';roundRect(ctx,-hw*.225,-bh*.72+hh*.18,hw*.45,hh*.15,3);ctx.fill();
  if(st==='talk'){
    for(let i=-2;i<=2;i++){ctx.fillStyle=pal.accent;roundRect(ctx,-hw*.225+i*hw*.09,-bh*.72+hh*.2,hw*.04,hh*.05+mo*hh*.05,1);ctx.fill();}
  }
  // Antenna
  ctx.strokeStyle=pal.body;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(0,-bh*.72-hh*.5);ctx.lineTo(0,-bh*.72-hh*.88);ctx.stroke();
  ctx.fillStyle=pal.accent;ctx.shadowColor=pal.accent;ctx.shadowBlur=5;ctx.beginPath();ctx.arc(0,-bh*.72-hh*.88,sz*.035,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;
}

function drawDragonBody(ctx,pal,sz,st,ll,rl,la,ra,mo){
  const bw=sz*.44,bh=sz*.3;
  // Tail
  ctx.fillStyle=pal.body+'CC';
  ctx.beginPath();ctx.moveTo(bw*.4,0);ctx.quadraticCurveTo(bw*1.2,bh*.3,bw*.9,bh*.7);ctx.quadraticCurveTo(bw*.6,bh*.5,bw*.4,bh*.5);ctx.fill();
  // Wings if flying
  if(st==='fly'){
    const wf=Math.sin(tick*Math.PI*4)*.3;
    [[-1,la],[1,ra]].forEach(([s,a])=>{
      ctx.save();ctx.translate(s*bw*.3,-bh*.1);ctx.rotate(s*(Math.PI/4+wf));
      ctx.fillStyle=pal.body+'AA';ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(s*bw*1.1,-bh*.6);ctx.lineTo(s*bw*.8,0);ctx.closePath();ctx.fill();
      ctx.restore();
    });
  }
  // Legs
  [[-1,ll],[1,rl]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.28,bh*.45);ctx.rotate(a);
    ctx.fillStyle=pal.body;roundRect(ctx,-sz*.07,0,sz*.14,sz*.18,5);ctx.fill();
    [-1,0,1].forEach(c=>{ctx.strokeStyle='#333';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(c*sz*.04,sz*.18);ctx.lineTo(c*sz*.06,sz*.22);ctx.stroke();});
    ctx.restore();
  });
  // Body
  ctx.fillStyle=pal.body;ctx.beginPath();ctx.ellipse(0,0,bw/2,bh/2,0,0,Math.PI*2);ctx.fill();
  ctx.fillStyle=pal.skin+'77';ctx.beginPath();ctx.ellipse(0,bh*.08,bw*.275,bh*.3,0,0,Math.PI*2);ctx.fill();
  // Arms
  [[-1,la],[1,ra]].forEach(([s,a])=>{
    ctx.save();ctx.translate(s*bw*.5,-bh*.15);ctx.rotate(a);
    ctx.fillStyle=pal.body;roundRect(ctx,-sz*.07,0,sz*.14,sz*.2,5);ctx.fill();
    ctx.restore();
  });
  // Neck
  ctx.fillStyle=pal.body;roundRect(ctx,-bw*.11,-bh*.55,bw*.22,bh*.28,8);ctx.fill();
  // Head
  ctx.fillStyle=pal.body;ctx.beginPath();ctx.ellipse(0,-bh*.88,bw*.275,bh*.2,0,0,Math.PI*2);ctx.fill();
  // Snout
  const so=mo*bh*.1+bh*.04;
  ctx.fillStyle=pal.body;roundRect(ctx,bw*.04,-bh*.88+so*.3,bw*.24,so,4);ctx.fill();
  ctx.fillStyle=pal.skin+'99';roundRect(ctx,bw*.05,-bh*.88+so,bw*.22,so*.7,4);ctx.fill();
  // Fire breath
  if(st==='attack'&&mo>.3){
    ctx.fillStyle='rgba(255,109,0,.85)';
    ctx.beginPath();ctx.moveTo(bw*.3,-bh*.85);ctx.quadraticCurveTo(bw*.8,-bh*.7,bw*1.1,-bh*.88);ctx.quadraticCurveTo(bw*.8,-bh*1.0,bw*.3,-bh*.88);ctx.fill();
    ctx.shadowColor='#FF6D00';ctx.shadowBlur=12;ctx.fill();ctx.shadowBlur=0;
  }
  // Eyes
  [[-bw*.08,bw*.22]].forEach(_=>0);
  [[-bw*.08,-bh*.95],[bw*.22,-bh*.95]].forEach(([ex,ey])=>{ctx.fillStyle='yellow';ctx.beginPath();ctx.ellipse(ex,ey,bw*.06,bh*.05,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#111';ctx.beginPath();ctx.arc(ex,ey,bw*.035,0,Math.PI*2);ctx.fill();});
  // Horns
  [[-bw*.16,bw*.16]].forEach(_=>0);
  [[-bw*.16,bw*.16]].forEach(hx=>{ctx.fillStyle='#4A148C';ctx.beginPath();ctx.moveTo(hx,-bh*1.06);ctx.lineTo(hx-bw*.04,-bh*1.25);ctx.lineTo(hx+bw*.04,-bh*1.06);ctx.closePath();ctx.fill();});
}

function roundRect(ctx,x,y,w,h,r){
  if(ctx.roundRect){ctx.beginPath();ctx.roundRect(x,y,w,h,r);}
  else{ctx.beginPath();ctx.moveTo(x+r,y);ctx.lineTo(x+w-r,y);ctx.quadraticCurveTo(x+w,y,x+w,y+r);ctx.lineTo(x+w,y+h-r);ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);ctx.lineTo(x+r,y+h);ctx.quadraticCurveTo(x,y+h,x,y+h-r);ctx.lineTo(x,y+r);ctx.quadraticCurveTo(x,y,x+r,y);ctx.closePath();}
}

function drawStarShape(ctx,cx,cy,r,color){
  ctx.fillStyle=color;ctx.beginPath();
  for(let i=0;i<10;i++){const a=i*Math.PI/5-Math.PI/2,rad=i%2===0?r:r*.42;i===0?ctx.moveTo(cx+Math.cos(a)*rad,cy+Math.sin(a)*rad):ctx.lineTo(cx+Math.cos(a)*rad,cy+Math.sin(a)*rad);}
  ctx.closePath();ctx.fill();
}

function drawBubble(text,bx,by,right){
  const mw=Math.min(W*.35,190);
  X.font='bold 12px sans-serif';
  const words=text.split(' ');const lines=[];let line='';
  words.forEach(w=>{
    const t2=line+w+' ';
    if(X.measureText(t2).width>mw-18&&line!==''){lines.push(line.trim());line=w+' ';}
    else line=t2;
  });
  lines.push(line.trim());
  const lh=17,pad=9,bw2=mw,bh2=lines.length*lh+pad*2;
  const ox=right?bx-bw2*.5-8:bx-bw2*.5+8,oy=by-bh2-18;
  X.fillStyle='rgba(255,255,255,.96)';
  X.beginPath();if(X.roundRect)X.roundRect(ox,oy,bw2,bh2,12);else X.rect(ox,oy,bw2,bh2);X.fill();
  X.fillStyle='rgba(240,240,240,.96)';X.beginPath();X.moveTo(bx-8,oy+bh2);X.lineTo(bx+8,oy+bh2);X.lineTo(bx,oy+bh2+12);X.fill();
  X.fillStyle='#111';X.font='bold 11px sans-serif';X.textAlign='left';
  lines.forEach((l,i)=>X.fillText(l,ox+10,oy+pad+13+i*lh));
  X.textAlign='center';
}

function drawSubs(sc){
  const t=(sc.characters||[]).find(c=>c.dialogue)?.dialogue||sc.narration||'';
  if(!t)return;
  const g=X.createLinearGradient(0,H*.82,0,H);
  g.addColorStop(0,'transparent');g.addColorStop(1,'rgba(0,0,0,.88)');
  X.fillStyle=g;X.fillRect(0,H*.82,W,H*.18);
  X.fillStyle='white';X.font='bold 14px sans-serif';X.textAlign='center';
  X.shadowColor='black';X.shadowBlur=5;
  X.fillText(t,W/2,H*.94);X.shadowBlur=0;
}

function drawVignette(){
  const g=X.createRadialGradient(W/2,H/2,H*.3,W/2,H/2,W*.72);
  g.addColorStop(0,'transparent');g.addColorStop(1,'rgba(0,0,0,.33)');
  X.fillStyle=g;X.fillRect(0,0,W,H);
}

// Controls
function togglePlay(){playing=!playing;document.getElementById('pb2').textContent=playing?'⏸':'▶';}
function next(){if(cur<SCENES.length-1){cur++;elapsed=0;}}
function prev(){if(cur>0){cur--;elapsed=0;}}
function toggleSub(){showSub=!showSub;document.getElementById('sb2').textContent=showSub?'💬':'🔇';}

// Touch swipe
let tx=0;
document.addEventListener('touchstart',e=>tx=e.touches[0].clientX);
document.addEventListener('touchend',e=>{const d=tx-e.changedTouches[0].clientX;if(Math.abs(d)>50){d>0?next():prev();}});

// Click effects
C.addEventListener('click',e=>{
  const sc=SCENES[cur];
  const type=(sc?.background==='volcano'||sc?.background==='battlefield')?'explosion':'magic';
  emitParticle(type,e.clientX,e.clientY,type==='explosion'?20:12);
  if(type==='explosion')emitParticle('sparks',e.clientX,e.clientY,8);
});
</script>
</body></html>''';
  }
}

class _ParticlePainter extends CustomPainter {
  final List<ParticleSystem> particles;
  const _ParticlePainter({required this.particles});
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.render(canvas);
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter old) => true;
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
  final _narCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scene = StoryScene.fromJson(widget.scene.toJson());
    _narCtrl.text = _scene.narration;
  }

  Map<String, dynamic> get _json => _scene.toJson();

  void _update(Map<String, dynamic> changes) {
    setState(() => _scene = StoryScene.fromJson({..._json, ...changes}));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          const Text('Edit Scene', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),

          _label('Background'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: BackgroundType.values.map((bg) => GestureDetector(
              onTap: () => _update({'background': bg.name}),
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
          _label('Time of Day'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: SceneTimeOfDay.values.map((t) => GestureDetector(
              onTap: () => _update({'timeOfDay': t.name}),
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
          _label('Camera Effect'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: CameraEffect.values.map((c) => GestureDetector(
              onTap: () => _update({'cameraEffect': c.name}),
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
          _label('Characters'),
          const SizedBox(height: 6),
          ..._scene.characters.asMap().entries.map((e) => _charEditor(e.key, e.value)),
          if (_scene.characters.length < 3)
            GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters);
                chars.add(SceneCharacter(characterId: 'villain', positionX: 0.7, facingRight: false));
                _update({'characters': chars.map((c) => c.toJson()).toList()});
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('+ Add Character',
                    style: TextStyle(color: Color(0xFF6C63FF)))),
              ),
            ),

          const SizedBox(height: 12),
          _label('Narration'),
          const SizedBox(height: 6),
          TextField(
            controller: _narCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            onChanged: (v) => _update({'narration': v}),
            decoration: InputDecoration(
              hintText: 'Scene narration...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true, fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 12),
          _label('Duration: ${_scene.durationSeconds}s'),
          Slider(
            value: _scene.durationSeconds.toDouble(),
            min: 1, max: 15, divisions: 14,
            activeColor: const Color(0xFF6C63FF),
            label: '${_scene.durationSeconds}s',
            onChanged: (v) => _update({'durationSeconds': v.toInt()}),
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
              child: const Center(child: Text('Save Scene',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _charEditor(int idx, SceneCharacter char) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Character ${idx + 1}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          if (_scene.characters.length > 1)
            GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters)..removeAt(idx);
                _update({'characters': chars.map((c) => c.toJson()).toList()});
              },
              child: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
            ),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4,
          children: CharacterRegistry.getAllIds().map((id) {
            final d = CharacterRegistry.get(id)!;
            return GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters);
                chars[idx] = SceneCharacter(characterId: id,
                    positionX: char.positionX, positionY: char.positionY,
                    facingRight: char.facingRight, dialogue: char.dialogue, scale: char.scale);
                _update({'characters': chars.map((c) => c.toJson()).toList()});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: char.characterId == id ? const Color(0xFF6C63FF) : const Color(0xFF0A0A14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${d.emoji} $id',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4,
          children: CharacterState.values.map((s) => GestureDetector(
            onTap: () {
              final chars = List<SceneCharacter>.from(_scene.characters);
              chars[idx] = SceneCharacter(characterId: char.characterId,
                  positionX: char.positionX, positionY: char.positionY,
                  facingRight: char.facingRight, dialogue: char.dialogue, state: s, scale: char.scale);
              _update({'characters': chars.map((c) => c.toJson()).toList()});
            },
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
            chars[idx] = SceneCharacter(characterId: char.characterId,
                positionX: char.positionX, positionY: char.positionY,
                facingRight: char.facingRight, dialogue: v, state: char.state, scale: char.scale);
            _update({'characters': chars.map((c) => c.toJson()).toList()});
          },
          decoration: InputDecoration(
            hintText: 'Dialogue...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
            filled: true, fillColor: const Color(0xFF0A0A14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));
}
