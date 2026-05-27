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

function drawChar(ch){
  const data=CHARS[ch.characterId]||CHARS.hero;
  const cx=ch.positionX*W, cy=ch.positionY*H;
  const sz=H*.32*(ch.scale||1);
  const st=ch.state||'idle';

  X.save();
  X.translate(cx,cy);
  if(!ch.facingRight)X.scale(-1,1);

  // Shadow
  X.fillStyle='rgba(0,0,0,.28)';
  X.beginPath();X.ellipse(0,8,sz*.24,sz*.055,0,0,Math.PI*2);X.fill();

  // State transforms
  let dy=0,sx=1,sy=1,rot=0;
  switch(st){
    case'idle':dy=Math.sin(tick*2)*4;break;
    case'walk':dy=Math.sin(tick*6)*3;rot=Math.sin(tick*6)*.06;break;
    case'run':dy=Math.sin(tick*10)*5;rot=Math.sin(tick*10)*.1;sx=1+Math.abs(Math.sin(tick*10))*.05;break;
    case'jump':dy=-Math.abs(Math.sin(tick*3))*sz*.4;sx=1+Math.sin(tick*3)*.08;sy=1-Math.sin(tick*3)*.08;break;
    case'attack':rot=Math.sin(tick*8)*.3;X.shadowColor=data.color;X.shadowBlur=22;break;
    case'fly':dy=Math.sin(tick*3)*8;rot=-.15;X.shadowColor=data.color;X.shadowBlur=16;break;
    case'talk':dy=Math.sin(tick*5)*2;break;
    case'angry':rot=Math.sin(tick*12)*.05;X.shadowColor='#FF1744';X.shadowBlur=16;break;
    case'happy':dy=-Math.abs(Math.sin(tick*4))*10;sx=1+Math.sin(tick*4)*.06;break;
    case'sad':dy=3;rot=.05;break;
    case'victory':dy=-Math.abs(Math.sin(tick*3))*22;X.shadowColor='#FFD700';X.shadowBlur=28;break;
    case'death':rot=Math.min(tick,.8)*Math.PI*.5;dy=Math.min(tick,.8)*sz*.35;break;
    case'cast':rot=Math.sin(tick*4)*.12;X.shadowColor='#AA00FF';X.shadowBlur=32;
      if(Math.random()<.25)emitParticle('magic',cx+Math.sin(tick*5)*30,cy-sz*.5);break;
    case'defend':sx=.88;dy=-5;X.shadowColor='#4488FF';X.shadowBlur=22;break;
  }

  X.translate(0,dy);X.rotate(rot);X.scale(sx,sy);
  drawBody(data.color,sz,st);
  X.restore();

  if(ch.dialogue&&showSub)drawBubble(ch.dialogue,cx,cy-sz*.95,ch.facingRight);
}

function drawBody(color,sz,st){
  const bw=sz*.42,bh=sz*.5;
  const hr=parseInt(color.slice(1,3),16),
        hg=parseInt(color.slice(3,5),16),
        hb=parseInt(color.slice(5,7),16);
  const lighter=`rgb(${Math.min(255,hr+50)},${Math.min(255,hg+50)},${Math.min(255,hb+50)})`;

  // Legs
  const ls=Math.sin(tick*6)*(st==='run'?20:st==='walk'?12:0)*Math.PI/180;
  [-1,1].forEach(s=>{
    X.save();X.translate(s*bw*.18,bh*.52);X.rotate(s*ls);
    X.fillStyle=color;X.fillRect(-bw*.13,0,bw*.26,bh*.36);
    X.fillStyle='#111';X.fillRect(-bw*.18,bh*.33,bw*.35,bh*.1);
    X.restore();
  });

  // Body
  const bg=X.createLinearGradient(-bw*.5,-bh*.35,bw*.5,bh*.35);
  bg.addColorStop(0,lighter);bg.addColorStop(1,color);
  X.fillStyle=bg;X.beginPath();
  if(X.roundRect)X.roundRect(-bw*.5,-bh*.35,bw,bh*.7,10);
  else X.rect(-bw*.5,-bh*.35,bw,bh*.7);
  X.fill();

  // Star emblem
  X.fillStyle='rgba(255,255,255,.9)';
  X.beginPath();
  for(let i=0;i<10;i++){
    const a=i*Math.PI/5-Math.PI/2,r=i%2===0?bw*.1:bw*.04;
    i===0?X.moveTo(Math.cos(a)*r,Math.sin(a)*r-bh*.05):X.lineTo(Math.cos(a)*r,Math.sin(a)*r-bh*.05);
  }
  X.closePath();X.fill();

  // Arms
  const as=Math.sin(tick*6)*(st==='run'?25:st==='walk'?15:0)*Math.PI/180;
  [-1,1].forEach(s=>{
    X.save();X.translate(s*bw*.5,-bh*.05);
    const ar=st==='attack'&&s===1?-Math.PI/3+Math.sin(tick*8)*.5:s*as;
    X.rotate(ar);
    X.fillStyle=color;X.fillRect(-bw*.11,0,bw*.22,bh*.34);
    X.fillStyle='#FFDBA0';X.beginPath();X.arc(0,bh*.36,bw*.12,0,Math.PI*2);X.fill();
    X.restore();
  });

  // Neck
  X.fillStyle='#FFDBA0';X.fillRect(-bw*.1,-bh*.36,bw*.2,bh*.1);

  // Head
  X.fillStyle='#FFDBA0';X.beginPath();X.ellipse(0,-bh*.55,bw*.28,bh*.22,0,0,Math.PI*2);X.fill();

  // Hair
  X.fillStyle='#3E2723';X.beginPath();X.ellipse(0,-bh*.68,bw*.27,bh*.12,0,-Math.PI,0);X.fill();

  // Eyes
  const mopen=st==='talk'?Math.abs(Math.sin(tick*8))*bh*.06:0;
  [-1,1].forEach(s=>{
    X.fillStyle='white';X.beginPath();X.ellipse(s*bw*.12,-bh*.56,bw*.07,bh*.055,0,0,Math.PI*2);X.fill();
    X.fillStyle='#111';X.beginPath();X.arc(s*bw*.12,-bh*.555,bw*.035,0,Math.PI*2);X.fill();
    X.fillStyle='white';X.beginPath();X.arc(s*bw*.1,-bh*.565,bw*.02,0,Math.PI*2);X.fill();
  });

  // Brows
  const bt=st==='angry'?.4:st==='sad'?-.25:0;
  X.strokeStyle='#3E2723';X.lineWidth=2.5;X.lineCap='round';
  [-1,1].forEach(s=>{
    X.save();X.translate(s*bw*.12,-bh*.63);X.rotate(s*bt);
    X.beginPath();X.moveTo(-bw*.09,0);X.lineTo(bw*.09,0);X.stroke();
    X.restore();
  });

  // Mouth
  const my=-bh*.475;
  X.strokeStyle='#111';X.lineWidth=2;X.lineCap='round';
  if(st==='happy'||st==='victory'){
    X.beginPath();X.moveTo(-bw*.1,my);X.quadraticCurveTo(0,my+bh*.07,bw*.1,my);X.stroke();
  } else if(st==='sad'||st==='death'){
    X.beginPath();X.moveTo(-bw*.1,my+bh*.04);X.quadraticCurveTo(0,my-bh*.02,bw*.1,my+bh*.04);X.stroke();
  } else if(st==='angry'){
    X.beginPath();X.moveTo(-bw*.1,my+bh*.02);X.lineTo(bw*.1,my+bh*.02);X.stroke();
  } else {
    X.beginPath();X.moveTo(-bw*.08,my);X.lineTo(bw*.08,my);X.stroke();
    if(mopen>2){X.fillStyle='#B71C1C';X.beginPath();X.ellipse(0,my+mopen*.5,bw*.08,mopen*.5,0,0,Math.PI*2);X.fill();}
  }
}

function drawBubble(text,bx,by,right){
  const mw=Math.min(W*.35,190);
  X.font='bold 12px sans-serif';
  const words=text.split(' ');const lines=[];let line='';
  words.forEach(w=>{
    const t=line+w+' ';
    if(X.measureText(t).width>mw-18&&line!==''){lines.push(line.trim());line=w+' ';}
    else line=t;
  });
  lines.push(line.trim());
  const lh=17,pad=9,bw2=mw,bh2=lines.length*lh+pad*2;
  const ox=right?bx-bw2/2-8:bx-bw2/2+8,oy=by-bh2-18;
  X.fillStyle='rgba(255,255,255,.96)';
  X.beginPath();
  if(X.roundRect)X.roundRect(ox,oy,bw2,bh2,12);else X.rect(ox,oy,bw2,bh2);
  X.fill();
  X.fillStyle='rgba(240,240,240,.96)';X.beginPath();
  X.moveTo(bx-8,oy+bh2);X.lineTo(bx+8,oy+bh2);X.lineTo(bx,oy+bh2+12);X.fill();
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
