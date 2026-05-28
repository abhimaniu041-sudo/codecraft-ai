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
// Existing imports ke saath add karo:
import '../video/ai/ai_manager.dart';
import '../video/ai/ai_config.dart';
import '../video/assets/asset_manager.dart';
import '../video/ai/scene_generator.dart';
import '../video/engine/export_engine.dart';

// initState mein add karo:
@override
void initState() {
  super.initState();

  // Initialize AI Manager with all providers
  AIManager().configure(
    groqKey: AIConfig.groqApiKey,
    geminiKey: AIConfig.geminiApiKey,
    openRouterKey: AIConfig.openRouterApiKey,
    huggingFaceKey: AIConfig.huggingFaceApiKey,
  );

  // Initialize Asset Manager
  AssetManager().init();

  // ... rest of existing initState code
}

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
    _renderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
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
          break;
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
        weather: WeatherType.none,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: 'idle',
            positionX: 0.35,
            positionY: 0.62,
            dialogue: 'Ready for adventure!',
          ),
        ],
        narration: 'The story begins...',
        durationSeconds: 4,
      ));
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story prompt daalo!')));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final result = await AIService.sendMessage(
        userMessage:
            '''Create 6 cinematic cartoon scenes for: "$prompt"

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

backgrounds: city,cyberpunk,forest,space,underwater,volcano,castle,battlefield,beach,snow,desert,jungle,fantasy,school,laboratory
timeOfDay: day,sunset,night
weather: none,rain,snow,storm,fog
characterIds: hero,villain,robot,wizard,ninja,princess,warrior,alien,zombie,dragon
states: idle,walk,run,attack,jump,fly,talk,angry,happy,sad,victory,death,cast,defend
cameraEffect: none,shake,zoomIn,zoomOut,pan
transitions: fade,flash,wipe,zoom,none''',
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
          final s = Map<String, dynamic>.from(scenesJson[i]);
          s['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
          _timeline.addScene(StoryScene.fromJson(s));
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
        final data = jsonDecode(saved) as Map<String, dynamic>;
        _projectName = (data['name'] ?? 'My Story') as String;
        _timeline.scenes.clear();
        for (final s in (data['scenes'] as List)) {
          _timeline.addScene(
              StoryScene.fromJson(Map<String, dynamic>.from(s)));
        }
        if (_timeline.scenes.isEmpty) _addDefaultScene();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _exportHTML() async {
    setState(() => _isExporting = true);
    try {
      final html = _buildExportHTML();
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
                const Text('Open in browser to watch.',
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

  // ─── BUILD ───────────────────────────────────────────────
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
                : const Icon(Icons.file_download,
                    color: Color(0xFFFFD700)),
            onPressed: _isExporting ? null : _exportHTML,
          ),
        ],
      ),
      body: Column(children: [
        Expanded(flex: 5, child: _buildViewport()),
        _buildControls(),
        _buildPromptBar(),
        Expanded(flex: 4, child: _buildSceneList()),
      ]),
    );
  }

  Widget _buildViewport() {
    final scene = _timeline.currentScene;
    return GestureDetector(
      onTapDown: (d) {
        final sc = _timeline.currentScene;
        final type = (sc?.background == BackgroundType.volcano ||
                sc?.background == BackgroundType.battlefield)
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
                      Positioned.fill(
                        child: CustomPaint(
                          painter:
                              _ParticlePainter(particles: _particles),
                        ),
                      ),
                      Positioned.fill(
                          child: _buildCharactersLayer(scene)),
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
          final charSize =
              constraints.maxHeight * 0.38 * char.scale;
          final x = constraints.maxWidth * char.positionX - charSize / 2;
          final y = constraints.maxHeight * char.positionY - charSize;
          final charState = _parseState(char.state);
          return Positioned(
            left: x,
            top: y,
            child: Column(
              children: [
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
                        bottomLeft:
                            Radius.circular(char.facingRight ? 14 : 2),
                        bottomRight:
                            Radius.circular(char.facingRight ? 2 : 14),
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
                AnimatedCharacterWidget(
                  characterId: char.characterId,
                  state: charState,
                  size: charSize,
                  facingRight: char.facingRight,
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  CharacterState _parseState(String s) {
    return CharacterState.values.firstWhere(
      (cs) => cs.name == s,
      orElse: () => CharacterState.idle,
    );
  }

  Widget _buildViewportOverlay(StoryScene scene) {
    return Stack(children: [
      Positioned(
        top: 8,
        left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            'Scene ${_timeline.currentSceneIndex + 1}/${_timeline.scenes.length} - ${scene.background.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
      Positioned(
        top: 8,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            '${(_timeline.sceneProgress * scene.durationSeconds).toStringAsFixed(1)}s / ${scene.durationSeconds}s',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
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
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
            ),
          ),
        ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: LinearProgressIndicator(
          value: _timeline.sceneProgress,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          minHeight: 2,
        ),
      ),
    ]);
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0D0D1A),
      child: Row(children: [
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
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Icon(
                _timeline.isPlaying ? Icons.pause : Icons.play_arrow,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'AI Director: "Dragon attacks city at night"',
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 11),
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
                weather: WeatherType.none,
                characters: [SceneCharacter(characterId: 'hero')],
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
                      style: TextStyle(color: Color(0xFF6C63FF))),
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
                        .take(2)
                        .map((c) => c.characterId[0].toUpperCase())
                        .join('/'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
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
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 9)),
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
      case BackgroundType.school:
        return [const Color(0xFF8BC34A), const Color(0xFFE53935)];
      case BackgroundType.laboratory:
        return [const Color(0xFF37474F), const Color(0xFF00E5FF)];
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

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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

  String _buildExportHTML() {
    final scenesJson =
        jsonEncode(_timeline.scenes.map((s) => s.toJson()).toList());
    return '''<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>$_projectName</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;overflow:hidden;width:100vw;height:100vh}
canvas{display:block}
#ui{position:fixed;bottom:0;left:0;right:0;padding:10px 16px;background:rgba(0,0,0,.85);display:none;align-items:center;gap:10px}
.btn{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.2);color:#fff;padding:9px 15px;border-radius:20px;cursor:pointer;font-size:15px}
.pbtn{background:linear-gradient(135deg,#6c63ff,#3ecfcf);border:none;padding:11px 28px;font-size:18px;border-radius:20px;cursor:pointer;color:#fff}
#pb{flex:1;height:3px;background:rgba(255,255,255,.2);border-radius:2px;overflow:hidden}
#pf{height:100%;background:linear-gradient(90deg,#6c63ff,#3ecfcf);width:0%}
#ts{position:fixed;inset:0;background:linear-gradient(135deg,#0a0a14,#1a1a2e);display:flex;flex-direction:column;align-items:center;justify-content:center;color:#fff;z-index:10}
#ts h1{font-size:clamp(22px,6vw,46px);background:linear-gradient(135deg,#6c63ff,#3ecfcf);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:8px;text-align:center}
#sb{margin-top:28px;padding:14px 38px;border-radius:30px;border:none;font-size:17px;font-weight:bold;cursor:pointer;background:linear-gradient(135deg,#6c63ff,#3ecfcf);color:#fff}
</style>
</head><body>
<div id="ts">
<div style="font-size:60px;margin-bottom:12px">&#127916;</div>
<h1>$_projectName</h1>
<p style="color:#888">${_timeline.scenes.length} scenes</p>
<button id="sb" onclick="startMovie()">Play Movie</button>
</div>
<canvas id="c"></canvas>
<div id="ui">
<button class="btn" onclick="prev()">&#9198;</button>
<button class="pbtn" id="pb2" onclick="togglePlay()">&#9646;&#9646;</button>
<button class="btn" onclick="next()">&#9197;</button>
<div id="pb"><div id="pf"></div></div>
<button class="btn" id="sb2" onclick="toggleSub()">CC</button>
</div>
<script>
const SCENES=$scenesJson;
const CV=document.getElementById('c');
const CX=CV.getContext('2d');
let W,H,cur=0,playing=true,showSub=true,elapsed=0,anim=0,last=0;
const parts=[];

function resize(){W=CV.width=window.innerWidth;H=CV.height=window.innerHeight-52;}
window.addEventListener('resize',resize);

function startMovie(){
document.getElementById('ts').style.display='none';
document.getElementById('ui').style.display='flex';
resize();requestAnimationFrame(loop);
}

function loop(ts){
requestAnimationFrame(loop);
const dt=Math.min((ts-last)/1000,.05);last=ts;
if(playing){elapsed+=dt;anim+=dt;}
const sc=SCENES[cur];
if(sc&&elapsed>=sc.durationSeconds){elapsed=0;if(cur<SCENES.length-1)cur++;else{playing=false;document.getElementById('pb2').innerHTML='&#9654;';}}
render(dt);
document.getElementById('pf').style.width=((cur/SCENES.length)*100)+'%';
}

function render(dt){
CX.clearRect(0,0,W,H);
const sc=SCENES[cur];if(!sc)return;
drawBg(sc);updateParts(dt);drawParts();drawChars(sc);
if(showSub)drawSubs(sc);drawVig();
}

function drawBg(sc){
const tod=sc.timeOfDay,bg=sc.background;
drawSky(tod);
if(bg==='city'||bg==='cyberpunk')drawCity(bg==='cyberpunk');
else if(bg==='forest'||bg==='jungle')drawForest();
else if(bg==='space')drawSpace();
else if(bg==='underwater')drawUnder();
else if(bg==='volcano')drawVolcano();
else if(bg==='castle')drawCastle();
else if(bg==='battlefield')drawBattle();
else if(bg==='beach')drawBeach();
else if(bg==='snow')drawSnow();
else if(bg==='desert')drawDesert();
else if(bg==='fantasy')drawFantasy();
else drawCity(false);
if(tod==='night')drawStars();
if(tod!=='night')drawClouds();
}

function drawSky(tod){
const skies={day:['#4FC3F7','#0288D1'],sunset:['#FF7043','#880E4F'],night:['#0A0A2E','#1A1A4E']};
const c=skies[tod]||skies.day;
const g=CX.createLinearGradient(0,0,0,H*.65);
g.addColorStop(0,c[0]);g.addColorStop(1,c[1]);
CX.fillStyle=g;CX.fillRect(0,0,W,H*.65);
if(tod!=='night'){CX.fillStyle=tod==='sunset'?'#FF7043':'#FFEB3B';CX.beginPath();CX.arc(W*.14,H*.12,22,0,Math.PI*2);CX.fill();}
else{CX.fillStyle='#FFF9C4';CX.beginPath();CX.arc(W*.8,H*.13,22,0,Math.PI*2);CX.fill();CX.fillStyle='#0A0A2E';CX.beginPath();CX.arc(W*.83,H*.12,19,0,Math.PI*2);CX.fill();}
}

function drawStars(){
const pts=[[.05,.04],[.15,.1],[.25,.03],[.38,.08],[.5,.02],[.62,.09],[.74,.05],[.85,.11],[.93,.04],[.1,.18],[.3,.16],[.55,.19],[.78,.15]];
pts.forEach(([px,py])=>{const tw=Math.sin(anim*4+px*10)>.3;CX.fillStyle='rgba(255,255,255,'+(tw?.9:.5)+')';CX.beginPath();CX.arc(px*W,py*H,tw?2.5:1.5,0,Math.PI*2);CX.fill();});
}
function drawClouds(){
CX.fillStyle='rgba(255,255,255,.82)';
[[.1,.08,80,32],[.45,.11,100,38],[.75,.07,70,28]].forEach(([cx,cy,cw,ch])=>{CX.beginPath();CX.ellipse(cx*W,cy*H,cw/2,ch/2,0,0,Math.PI*2);CX.fill();CX.beginPath();CX.ellipse(cx*W-22,cy*H+6,cw*.3,ch*.33,0,0,Math.PI*2);CX.fill();CX.beginPath();CX.ellipse(cx*W+26,cy*H+6,cw*.35,ch*.35,0,0,Math.PI*2);CX.fill();});
}

function drawCity(cyber){
CX.fillStyle=cyber?'#0D0020':'#3D3D3D';CX.fillRect(0,H*.63,W,H*.37);
CX.fillStyle=cyber?'#1A0033':'#2A2A2A';CX.fillRect(0,H*.77,W,H*.23);
[[0,.38,.11],[.12,.26,.09],[.23,.42,.10],[.35,.2,.10],[.47,.35,.11],[.6,.28,.09],[.71,.44,.10],[.83,.22,.11],[.91,.33,.10]].forEach(([bx,bh,bw])=>{
const px=bx*W,pw=bw*W,ph=bh*H,py=H*.63-ph;
CX.fillStyle=cyber?'hsl('+(270+bx*30)+',50%,'+(8+bx*5)+'%)':'hsl('+(220+bx*20)+',10%,'+(20+bx*8)+'%)';
CX.fillRect(px,py,pw,ph);
for(let r=0;r<7;r++)for(let c=0;c<3;c++){if((r+c+Math.floor(bx*10))%3!==0){CX.fillStyle=cyber?'hsla('+(bx*360|0)+',100%,60%,.7)':'rgba(255,230,100,.7)';CX.fillRect(px+pw*.12+c*pw*.28,py+ph*.07+r*ph*.12,pw*.15,ph*.07);}}
if(cyber){CX.strokeStyle='rgba(0,255,255,.5)';CX.lineWidth=1.5;CX.beginPath();CX.moveTo(px,py);CX.lineTo(px+pw,py);CX.stroke();}
});
}
function drawForest(){
CX.fillStyle='#2E5D27';CX.fillRect(0,H*.63,W,H*.37);
CX.fillStyle='#4CAF50';CX.fillRect(0,H*.63,W,H*.04);
for(let x=-80;x<W+80;x+=65)drawTree(x,H*.65,28,75,'#1B5E20','#2E7D32');
for(let x=-50;x<W+50;x+=85)drawTree(x+32,H*.67,38,95,'#388E3C','#43A047');
}
function drawTree(x,y,tw,th,dk,lt){
CX.fillStyle='#5D4037';CX.fillRect(x-tw*.11,y-th*.28,tw*.22,th*.28);
CX.fillStyle=dk;CX.beginPath();CX.moveTo(x,y-th);CX.lineTo(x+tw*.6,y-th*.44);CX.lineTo(x-tw*.6,y-th*.44);CX.fill();
CX.fillStyle=lt;CX.beginPath();CX.moveTo(x,y-th*.65);CX.lineTo(x+tw*.72,y-th*.22);CX.lineTo(x-tw*.72,y-th*.22);CX.fill();
}
function drawSpace(){
CX.fillStyle='#000011';CX.fillRect(0,0,W,H);
CX.fillStyle='#1A1A3E';CX.fillRect(0,H*.7,W,H*.3);
const gn=CX.createRadialGradient(W*.3,H*.3,10,W*.3,H*.3,W*.4);
gn.addColorStop(0,'rgba(74,0,224,.12)');gn.addColorStop(1,'transparent');
CX.fillStyle=gn;CX.fillRect(0,0,W,H);
}
function drawUnder(){
const g=CX.createLinearGradient(0,0,0,H);g.addColorStop(0,'#006994');g.addColorStop(1,'#001F3F');
CX.fillStyle=g;CX.fillRect(0,0,W,H);
CX.fillStyle='#C2A35A';CX.fillRect(0,H*.75,W,H*.25);
}
function drawVolcano(){
CX.fillStyle='#3D0000';CX.fillRect(0,H*.63,W,H*.37);
CX.fillStyle='#4A0000';CX.beginPath();CX.moveTo(W*.35,H*.63);CX.lineTo(W*.5,H*.22);CX.lineTo(W*.65,H*.63);CX.fill();
CX.fillStyle='rgba(255,69,0,.8)';CX.beginPath();CX.arc(W*.5,H*.25,20,0,Math.PI*2);CX.fill();
CX.fillStyle='rgba(255,109,0,.85)';CX.fillRect(W*.46,H*.28,W*.08,H*.35);
}
function drawCastle(){
CX.fillStyle='#3A3A3A';CX.fillRect(0,H*.63,W,H*.37);
CX.fillStyle='#585858';CX.fillRect(W*.28,H*.2,W*.44,H*.43);
CX.fillStyle='#4A4A4A';CX.fillRect(W*.13,H*.33,W*.16,H*.3);CX.fillRect(W*.71,H*.33,W*.16,H*.3);
for(let bx=W*.28;bx<W*.72;bx+=W*.06){CX.fillStyle='#585858';CX.fillRect(bx,H*.15,W*.04,H*.06);}
CX.fillStyle='#1A1A1A';CX.beginPath();CX.arc(W*.5,H*.535,W*.08,Math.PI,0);CX.fill();
}
function drawBattle(){
CX.fillStyle='#2D2D1A';CX.fillRect(0,H*.63,W,H*.37);
for(let i=0;i<4;i++){CX.fillStyle='#1A1A0D';CX.beginPath();CX.arc(W*(.15+i*.22),H*.7,18,0,Math.PI*2);CX.fill();}
}
function drawBeach(){
const g=CX.createLinearGradient(0,H*.45,0,H*.72);g.addColorStop(0,'#0099CC');g.addColorStop(1,'#006994');
CX.fillStyle=g;CX.fillRect(0,H*.45,W,H*.3);
CX.fillStyle='#F5DEB3';CX.fillRect(0,H*.72,W,H*.28);
}
function drawSnow(){
CX.fillStyle='#fff';CX.fillRect(0,H*.63,W,H*.37);
CX.fillStyle='#E3F2FD';CX.beginPath();CX.ellipse(W*.2,H*.58,W*.28,H*.1,0,0,Math.PI*2);CX.fill();
CX.beginPath();CX.ellipse(W*.8,H*.57,W*.3,H*.1,0,0,Math.PI*2);CX.fill();
}
function drawDesert(){
const g=CX.createLinearGradient(0,H*.5,0,H);g.addColorStop(0,'#D2691E');g.addColorStop(1,'#C19A6B');
CX.fillStyle=g;CX.fillRect(0,H*.5,W,H*.5);
}
function drawFantasy(){
const g=CX.createLinearGradient(0,0,0,H*.65);g.addColorStop(0,'#4A0080');g.addColorStop(1,'#1A0050');
CX.fillStyle=g;CX.fillRect(0,0,W,H*.65);
CX.fillStyle='#0D0025';CX.fillRect(0,H*.63,W,H*.37);
}

// ── PARTICLES ──
function emitPart(type,px,py,count=1){
for(let i=0;i<count;i++){
const p={type,x:px,y:py,vx:0,vy:0,life:1,ml:1,sz:8,col:'#FF4500'};
const R=()=>Math.random();
if(type==='fire'){p.vx=(R()-.5)*40;p.vy=-(R()*60+40);p.life=p.ml=R()*.8+.3;p.sz=R()*16+8;p.col=['#FF6D00','#FF3D00','#FFD600','#FF1744'][0|R()*4];}
else if(type==='explosion'){const a=R()*Math.PI*2,s=R()*200+100;p.vx=Math.cos(a)*s;p.vy=Math.sin(a)*s-100;p.life=p.ml=R()*.6+.2;p.sz=R()*14+4;p.col=['#FF6D00','#FFD600','#FF1744','#FFF'][0|R()*4];}
else if(type==='magic'){p.vx=(R()-.5)*30;p.vy=-(R()*50+20);p.life=p.ml=R()+.4;p.sz=R()*8+3;p.col=['#AA00FF','#E040FB','#7C4DFF','#00E5FF'][0|R()*4];}
parts.push(p);
}
}
function updateParts(dt){
for(let i=parts.length-1;i>=0;i--){
const p=parts[i];p.life-=dt;if(p.life<=0||p.sz<.5){parts.splice(i,1);continue;}
p.x+=p.vx*dt;p.y+=p.vy*dt;
if(p.type==='fire'){p.vy-=80*dt;p.sz*=(1-dt*.8);}
if(p.type==='explosion')p.vy+=150*dt;
if(p.type==='magic')p.vy-=40*dt;
}
}
function drawParts(){
parts.forEach(p=>{
CX.save();CX.globalAlpha=(p.life/p.ml);
if(p.type!=='explosion'){CX.shadowColor=p.col;CX.shadowBlur=p.sz*.8;}
CX.fillStyle=p.col;CX.beginPath();CX.arc(p.x,p.y,p.sz/2,0,Math.PI*2);CX.fill();
CX.restore();
});
}

// ── CHARACTERS ──
const PAL={
hero:{body:'#1565C0',skin:'#FFCC80',hair:'#4E342E',acc:'#FFD600'},
villain:{body:'#4A0000',skin:'#B0BEC5',hair:'#212121',acc:'#FF1744'},
robot:{body:'#37474F',skin:'#607D8B',hair:'#263238',acc:'#00E5FF'},
wizard:{body:'#4A148C',skin:'#FFDBAC',hair:'#E0E0E0',acc:'#AA00FF'},
ninja:{body:'#212121',skin:'#FFCC80',hair:'#212121',acc:'#FF1744'},
princess:{body:'#AD1457',skin:'#FFDBAC',hair:'#FFD600',acc:'#FF80AB'},
warrior:{body:'#4E342E',skin:'#FFCC80',hair:'#4E342E',acc:'#FFD600'},
alien:{body:'#1B5E20',skin:'#69F0AE',hair:'#004D40',acc:'#00E5FF'},
zombie:{body:'#33691E',skin:'#8D9A4A',hair:'#212121',acc:'#76FF03'},
dragon:{body:'#7B1FA2',skin:'#9C27B0',hair:'#4A148C',acc:'#FF6D00'}
};

function drawChars(sc){(sc.characters||[]).forEach(ch=>drawChar(ch));}

function drawChar(ch){
const pal=PAL[ch.characterId]||PAL.hero;
const cx=ch.positionX*W,cy=ch.positionY*H;
const sz=H*.32*(ch.scale||1);
const st=ch.state||'idle';
CX.save();CX.translate(cx,cy);
if(!ch.facingRight)CX.scale(-1,1);
CX.fillStyle='rgba(0,0,0,.2)';CX.beginPath();CX.ellipse(0,sz*.18,sz*.22,sz*.055,0,0,Math.PI*2);CX.fill();
let dy=0,sx2=1,sy2=1,rot=0,ll=0,rl=0,la=0,ra=0,mo=0;
const S=Math.sin,pi=Math.PI;
switch(st){
case'idle':dy=S(anim*pi*2)*sz*.015;break;
case'walk':dy=Math.abs(S(anim*pi*4))*sz*.01;rot=S(anim*pi*2)*.04;ll=S(anim*pi*2)*.5;rl=-S(anim*pi*2)*.5;la=-S(anim*pi*2)*.4;ra=S(anim*pi*2)*.4;break;
case'run':dy=Math.abs(S(anim*pi*6))*sz*.02;rot=S(anim*pi*4)*.07;ll=S(anim*pi*4)*.8;rl=-S(anim*pi*4)*.8;la=-S(anim*pi*4)*.7;ra=S(anim*pi*4)*.7;sx2=1+Math.abs(S(anim*pi*4))*.06;break;
case'attack':rot=S(anim*pi*3)*.18;ra=-pi/2+S(anim*pi*3)*.8;la=.3;CX.shadowColor=pal.acc;CX.shadowBlur=22;break;
case'jump':dy=-Math.abs(S(anim*pi))*sz*.22;sx2=1+S(anim*pi)*.08;sy2=1-S(anim*pi)*.08;ll=-.4;rl=-.4;la=-.5;ra=.5;break;
case'fly':dy=S(anim*pi*2)*sz*.03;rot=-.12;la=-pi/4+S(anim*pi*2)*.2;ra=pi/4-S(anim*pi*2)*.2;CX.shadowColor=pal.acc;CX.shadowBlur=16;break;
case'talk':dy=S(anim*pi*3)*sz*.008;mo=Math.abs(S(anim*pi*6));la=S(anim*pi*2)*.2;break;
case'angry':rot=S(anim*pi*8)*.04;la=-.3;ra=.3;CX.shadowColor='#FF1744';CX.shadowBlur=16;break;
case'happy':dy=-Math.abs(S(anim*pi*2))*sz*.04;sx2=1+Math.abs(S(anim*pi*2))*.06;la=-.7;ra=.7;break;
case'sad':dy=sz*.02;rot=.04;la=.2;ra=-.2;break;
case'victory':dy=-Math.abs(S(anim*pi*2))*sz*.06;la=-pi/2;ra=pi/2;CX.shadowColor='#FFD700';CX.shadowBlur=28;break;
case'death':rot=Math.min(anim*.8,1)*pi*.5;dy=Math.min(anim*.8,1)*sz*.35;sy2=Math.max(.4,1-anim*.4);break;
case'cast':rot=S(anim*pi*2)*.1;ra=-pi/2+S(anim*pi*3)*.3;la=.2;CX.shadowColor='#AA00FF';CX.shadowBlur=32;break;
case'defend':sx2=.88;la=-.1;ra=-pi/2;CX.shadowColor='#4488FF';CX.shadowBlur=22;break;
}
CX.translate(0,dy);CX.rotate(rot);CX.scale(sx2,sy2);
if(ch.characterId==='robot')drawRobotB(pal,sz,st,ll,rl,la,ra,mo);
else if(ch.characterId==='dragon')drawDragonB(pal,sz,st,ll,rl,la,ra,mo);
else drawHumanB(pal,sz,st,ch.characterId,ll,rl,la,ra,mo);
CX.shadowBlur=0;
CX.restore();
if(ch.dialogue&&showSub)drawBubble(ch.dialogue,cx,cy-sz*.95,ch.facingRight);
}

function rr(x,y,w,h,r){CX.beginPath();if(CX.roundRect)CX.roundRect(x,y,w,h,r);else{CX.moveTo(x+r,y);CX.lineTo(x+w-r,y);CX.quadraticCurveTo(x+w,y,x+w,y+r);CX.lineTo(x+w,y+h-r);CX.quadraticCurveTo(x+w,y+h,x+w-r,y+h);CX.lineTo(x+r,y+h);CX.quadraticCurveTo(x,y+h,x,y+h-r);CX.lineTo(x,y+r);CX.quadraticCurveTo(x,y,x+r,y);CX.closePath();}}

function hex2rgb(hex){return[parseInt(hex.slice(1,3),16),parseInt(hex.slice(3,5),16),parseInt(hex.slice(5,7),16)];}

function lighter(hex,a){const[r,g,b]=hex2rgb(hex);return'rgb('+Math.min(255,r+a)+','+Math.min(255,g+a)+','+Math.min(255,b+a)+')';}

function drawHumanB(pal,sz,st,type,ll,rl,la,ra,mo){
const bw=sz*.38,bh=sz*.32,lw=sz*.11,lh=sz*.22,aw=sz*.10,ah=sz*.24,hr=sz*.22;
[[-1,ll],[1,rl]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.28,bh*.5);CX.rotate(a);
const lg=CX.createLinearGradient(0,0,0,lh);lg.addColorStop(0,pal.body);lg.addColorStop(1,pal.body+'BB');
CX.fillStyle=lg;rr(-lw/2,0,lw,lh,lw/2);CX.fill();
CX.fillStyle='#222';rr(-lw*.8,lh-lw*.4,lw*1.8,lw*.7,lw*.4);CX.fill();
CX.restore();
});
const bg=CX.createLinearGradient(-bw*.5,-bh*.5,bw*.5,bh*.5);
bg.addColorStop(0,lighter(pal.body,40));bg.addColorStop(1,pal.body);
CX.fillStyle=bg;rr(-bw/2,-bh/2,bw,bh,bw*.22);CX.fill();
CX.strokeStyle='rgba(0,0,0,.15)';CX.lineWidth=1.5;rr(-bw/2,-bh/2,bw,bh,bw*.22);CX.stroke();
if(type==='hero'){
CX.fillStyle=pal.acc+'CC';CX.beginPath();CX.moveTo(-bw*.44,-bh*.3);CX.quadraticCurveTo(-bw*.85,bh*.4,-bw*.3,bh*.55);CX.lineTo(-bw*.44,-bh*.3);CX.fill();
drawStar5(0,-bh*.05,bw*.1,pal.acc);
}else if(type==='villain'){
CX.fillStyle='#1A0000CC';CX.beginPath();CX.moveTo(-bw*.5,-bh*.35);CX.quadraticCurveTo(-bw*.95,bh*.5,-bw*.2,bh*.55);CX.lineTo(-bw*.5,-bh*.35);CX.fill();
CX.fillStyle=pal.acc;CX.beginPath();CX.arc(0,-bh*.05,bw*.08,0,Math.PI*2);CX.fill();
}else if(type==='wizard'){
CX.fillStyle=pal.acc+'88';rr(-bw/2,-bh*.02,bw,bh*.12,4);CX.fill();
}else if(type==='warrior'){
CX.fillStyle='#9E9E9E';rr(-bw*.35,-bh*.45,bw*.7,bh*.7,6);CX.fill();
CX.strokeStyle='rgba(0,0,0,.2)';CX.lineWidth=1.5;rr(-bw*.35,-bh*.45,bw*.7,bh*.7,6);CX.stroke();
}else if(type==='ninja'){
CX.fillStyle=pal.acc;rr(-bw/2,-bh*.02,bw,bh*.1,4);CX.fill();
}
[[-1,la],[1,ra]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.52,-bh*.1);CX.rotate(a);
const ag=CX.createLinearGradient(0,0,0,ah);ag.addColorStop(0,pal.body);ag.addColorStop(1,pal.skin);
CX.fillStyle=ag;rr(-aw/2,0,aw,ah,aw/2);CX.fill();
CX.fillStyle=pal.skin;CX.beginPath();CX.arc(0,ah+aw*.15,aw*.48,0,Math.PI*2);CX.fill();
CX.restore();
});
CX.fillStyle=pal.skin;rr(-bw*.1,-bh*.52,bw*.2,bh*.12,4);CX.fill();
const hy=-bh*.88;
CX.fillStyle=pal.skin;CX.beginPath();CX.ellipse(0,hy,hr,hr*.88,0,0,Math.PI*2);CX.fill();
CX.strokeStyle='rgba(0,0,0,.12)';CX.lineWidth=1.5;CX.beginPath();CX.ellipse(0,hy,hr,hr*.88,0,0,Math.PI*2);CX.stroke();
CX.fillStyle=pal.hair;CX.beginPath();CX.ellipse(0,hy,hr*1.02,hr*.88,0,-Math.PI,0);CX.fill();
rr(-hr*.95,hy-hr*.08,hr*.2,hr*.48,4);CX.fill();rr(hr*.75,hy-hr*.08,hr*.2,hr*.48,4);CX.fill();
if(type==='princess'){
CX.fillStyle='#FFD600';CX.beginPath();CX.moveTo(-hr*.5,hy-hr);CX.lineTo(-hr*.5,hy-hr*1.38);CX.lineTo(-hr*.25,hy-hr*1.2);CX.lineTo(0,hy-hr*1.48);CX.lineTo(hr*.25,hy-hr*1.2);CX.lineTo(hr*.5,hy-hr*1.38);CX.lineTo(hr*.5,hy-hr);CX.closePath();CX.fill();
[-.25,0,.25].forEach(gx=>{CX.fillStyle=pal.acc;CX.beginPath();CX.arc(gx*hr*2,hy-hr*1.05,hr*.07,0,Math.PI*2);CX.fill();});
}else if(type==='hero'){
CX.fillStyle=pal.body+'BB';rr(-hr,hy-hr*.18,hr*2,hr*.34,hr*.1);CX.fill();
}else if(type==='wizard'){
CX.fillStyle=pal.body;CX.beginPath();CX.moveTo(-hr*.55,hy-hr*.82);CX.lineTo(0,hy-hr*2.15);CX.lineTo(hr*.55,hy-hr*.82);CX.closePath();CX.fill();
rr(-hr*.7,hy-hr*.85,hr*1.4,hr*.22,hr*.08);CX.fill();
drawStar5(0,hy-hr*1.55,hr*.12,pal.acc);
}else if(type==='ninja'){
rr(-hr,hy-hr*.27,hr*2,hr*.22,4);CX.fill();
CX.fillStyle='#111';rr(-hr,hy+hr*.12,hr*2,hr*.5,4);CX.fill();
}else if(type==='warrior'){
CX.fillStyle='#9E9E9E';CX.beginPath();CX.arc(0,hy-hr*.08,hr*1.08,-Math.PI*1.1,Math.PI*.1);CX.fill();
}
[[-hr*.35,hy-hr*.05],[hr*.35,hy-hr*.05]].forEach(([ex,ey])=>{
CX.fillStyle='white';CX.beginPath();CX.ellipse(ex,ey,hr*.16,hr*.14,0,0,Math.PI*2);CX.fill();
CX.fillStyle='#1565C0';CX.beginPath();CX.arc(ex,ey+hr*.02,hr*.1,0,Math.PI*2);CX.fill();
CX.fillStyle='#111';CX.beginPath();CX.arc(ex,ey+hr*.02,hr*.055,0,Math.PI*2);CX.fill();
CX.fillStyle='white';CX.beginPath();CX.arc(ex-hr*.04,ey-hr*.04,hr*.025,0,Math.PI*2);CX.fill();
CX.strokeStyle='rgba(0,0,0,.25)';CX.lineWidth=1;CX.beginPath();CX.ellipse(ex,ey,hr*.16,hr*.14,0,0,Math.PI*2);CX.stroke();
});
const bt=st==='angry'?.38:st==='sad'?-.28:0;
[-1,1].forEach(s2=>{
CX.save();CX.translate(s2*hr*.35,hy-hr*.22);CX.rotate(s2*bt);
CX.fillStyle=pal.hair;rr(-hr*.14,-hr*.035,hr*.28,hr*.07,3);CX.fill();
CX.restore();
});
const my=hy+hr*.32;
CX.strokeStyle='#333';CX.lineWidth=2;CX.lineCap='round';
if(st==='happy'||st==='victory'){
CX.beginPath();CX.moveTo(-hr*.28,my-hr*.04);CX.quadraticCurveTo(0,my+hr*.24,hr*.28,my-hr*.04);CX.stroke();
CX.fillStyle='white';rr(-hr*.18,my-hr*.01,hr*.36,hr*.1,3);CX.fill();
}else if(st==='sad'){
CX.beginPath();CX.moveTo(-hr*.24,my+hr*.06);CX.quadraticCurveTo(0,my-hr*.12,hr*.24,my+hr*.06);CX.stroke();
}else if(st==='angry'){
CX.beginPath();CX.moveTo(-hr*.26,my+hr*.02);CX.lineTo(hr*.26,my+hr*.02);CX.stroke();
}else if(st==='talk'){
const oa=mo*hr*.15+hr*.04;
CX.fillStyle='#880E4F';CX.beginPath();CX.ellipse(0,my,hr*.15,oa,0,0,Math.PI*2);CX.fill();
CX.strokeStyle='#555';CX.lineWidth=1.5;CX.beginPath();CX.ellipse(0,my,hr*.15,oa,0,0,Math.PI*2);CX.stroke();
if(oa>hr*.05){CX.fillStyle='rgba(255,255,255,.9)';rr(-hr*.12,my-oa,hr*.24,hr*.06,2);CX.fill();}
}else{
CX.beginPath();CX.moveTo(-hr*.18,my);CX.lineTo(hr*.18,my);CX.stroke();
}
}

function drawRobotB(pal,sz,st,ll,rl,la,ra,mo){
const bw=sz*.40,bh=sz*.30,lw=sz*.13,lh=sz*.20,aw=sz*.11,ah=sz*.22,hw=sz*.42,hh=sz*.25;
[[-1,ll],[1,rl]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.27,bh*.5);CX.rotate(a);
CX.fillStyle=pal.body;rr(-lw/2,0,lw,lh,4);CX.fill();
CX.fillStyle=pal.body+'BB';rr(-lw*.8,lh-lw*.4,lw*1.7,lw*.65,3);CX.fill();
CX.restore();
});
CX.fillStyle=pal.body;rr(-bw/2,-bh/2,bw,bh,6);CX.fill();
CX.fillStyle=pal.body+'88';rr(-bw*.3,-bh*.45,bw*.6,bh*.5,4);CX.fill();
CX.fillStyle=pal.acc;CX.shadowColor=pal.acc;CX.shadowBlur=8;CX.beginPath();CX.arc(0,-bh*.08,bw*.08,0,Math.PI*2);CX.fill();CX.shadowBlur=0;
[[-bw*.38,-bh*.3],[bw*.38,-bh*.3],[-bw*.38,bh*.25],[bw*.38,bh*.25]].forEach(([bx2,by2])=>{CX.fillStyle=pal.acc+'99';CX.beginPath();CX.arc(bx2,by2,sz*.025,0,Math.PI*2);CX.fill();});
[[-1,la],[1,ra]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.55,-bh*.1);CX.rotate(a);
CX.fillStyle=pal.body+'CC';rr(-aw/2,0,aw,ah,4);CX.fill();
CX.fillStyle=pal.body;CX.beginPath();CX.arc(0,ah+aw*.2,aw*.5,0,Math.PI*2);CX.fill();
CX.restore();
});
CX.fillStyle=pal.body;rr(-hw/2,-bh*.72-hh/2,hw,hh,8);CX.fill();
CX.fillStyle=pal.acc+'44';rr(-hw*.375,-bh*.72-hh*.45,hw*.75,hh*.4,4);CX.fill();
const led=Math.abs(Math.sin(anim*Math.PI*4));
[[-hw*.2,-bh*.72],[hw*.2,-bh*.72]].forEach(([ex,ey])=>{
CX.fillStyle=pal.acc;CX.globalAlpha=.6+led*.4;CX.shadowColor=pal.acc;CX.shadowBlur=6;
CX.beginPath();CX.ellipse(ex,ey,hw*.075,hh*.2,0,0,Math.PI*2);CX.fill();
CX.globalAlpha=1;CX.shadowBlur=0;
});
CX.fillStyle='#333';rr(-hw*.225,-bh*.72+hh*.18,hw*.45,hh*.15,3);CX.fill();
if(st==='talk'){for(let i=-2;i<=2;i++){CX.fillStyle=pal.acc;rr(-hw*.225+i*hw*.09,-bh*.72+hh*.2,hw*.04,hh*.05+mo*hh*.05,1);CX.fill();}}
CX.strokeStyle=pal.body;CX.lineWidth=2;CX.beginPath();CX.moveTo(0,-bh*.72-hh*.5);CX.lineTo(0,-bh*.72-hh*.88);CX.stroke();
CX.fillStyle=pal.acc;CX.shadowColor=pal.acc;CX.shadowBlur=5;CX.beginPath();CX.arc(0,-bh*.72-hh*.88,sz*.035,0,Math.PI*2);CX.fill();CX.shadowBlur=0;
}

function drawDragonB(pal,sz,st,ll,rl,la,ra,mo){
const bw=sz*.44,bh=sz*.30;
CX.fillStyle=pal.body+'CC';CX.beginPath();CX.moveTo(bw*.4,0);CX.quadraticCurveTo(bw*1.2,bh*.3,bw*.9,bh*.7);CX.quadraticCurveTo(bw*.6,bh*.5,bw*.4,bh*.5);CX.fill();
if(st==='fly'||st==='attack'){
const wf=Math.sin(anim*Math.PI*4)*.3;
[[-1,la],[1,ra]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.3,-bh*.1);CX.rotate(s*(Math.PI/4+wf));
CX.fillStyle=pal.body+'AA';CX.beginPath();CX.moveTo(0,0);CX.lineTo(s*bw*1.1,-bh*.6);CX.lineTo(s*bw*.8,0);CX.closePath();CX.fill();
CX.restore();
});
}
[[-1,ll],[1,rl]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.28,bh*.45);CX.rotate(a);
CX.fillStyle=pal.body;rr(-sz*.07,0,sz*.14,sz*.18,5);CX.fill();
[-1,0,1].forEach(c=>{CX.strokeStyle='#333';CX.lineWidth=2;CX.beginPath();CX.moveTo(c*sz*.04,sz*.18);CX.lineTo(c*sz*.06,sz*.22);CX.stroke();});
CX.restore();
});
CX.fillStyle=pal.body;CX.beginPath();CX.ellipse(0,0,bw/2,bh/2,0,0,Math.PI*2);CX.fill();
CX.fillStyle=pal.skin+'77';CX.beginPath();CX.ellipse(0,bh*.08,bw*.275,bh*.3,0,0,Math.PI*2);CX.fill();
[[-1,la],[1,ra]].forEach(([s,a])=>{
CX.save();CX.translate(s*bw*.5,-bh*.15);CX.rotate(a);
CX.fillStyle=pal.body;rr(-sz*.07,0,sz*.14,sz*.2,5);CX.fill();
CX.restore();
});
CX.fillStyle=pal.body;rr(-bw*.11,-bh*.55,bw*.22,bh*.28,8);CX.fill();
CX.fillStyle=pal.body;CX.beginPath();CX.ellipse(0,-bh*.88,bw*.275,bh*.2,0,0,Math.PI*2);CX.fill();
const so=mo*bh*.1+bh*.04;
CX.fillStyle=pal.body;rr(bw*.04,-bh*.88+so*.3,bw*.24,so,4);CX.fill();
CX.fillStyle=pal.skin+'99';rr(bw*.05,-bh*.88+so,bw*.22,so*.7,4);CX.fill();
if(st==='attack'&&mo>.3){
CX.fillStyle='rgba(255,109,0,.85)';CX.beginPath();CX.moveTo(bw*.3,-bh*.85);CX.quadraticCurveTo(bw*.8,-bh*.7,bw*1.1,-bh*.88);CX.quadraticCurveTo(bw*.8,-bh*1.0,bw*.3,-bh*.88);CX.fill();
CX.shadowColor='#FF6D00';CX.shadowBlur=14;CX.fill();CX.shadowBlur=0;
}
[[-bw*.08,-bh*.95],[bw*.22,-bh*.95]].forEach(([ex,ey])=>{
CX.fillStyle='yellow';CX.beginPath();CX.ellipse(ex,ey,bw*.06,bh*.05,0,0,Math.PI*2);CX.fill();
CX.fillStyle='#111';CX.beginPath();CX.arc(ex,ey,bw*.035,0,Math.PI*2);CX.fill();
});
[[-bw*.16,bw*.16]].forEach(_=>0);
[-bw*.16,bw*.16].forEach(hx=>{
CX.fillStyle='#4A148C';CX.beginPath();CX.moveTo(hx,-bh*1.06);CX.lineTo(hx-bw*.04,-bh*1.25);CX.lineTo(hx+bw*.04,-bh*1.06);CX.closePath();CX.fill();
});
}

function drawStar5(cx,cy,r,color){
CX.fillStyle=color;CX.beginPath();
for(let i=0;i<10;i++){const a=i*Math.PI/5-Math.PI/2,rad=i%2===0?r:r*.42;i===0?CX.moveTo(cx+Math.cos(a)*rad,cy+Math.sin(a)*rad):CX.lineTo(cx+Math.cos(a)*rad,cy+Math.sin(a)*rad);}
CX.closePath();CX.fill();
}

function drawBubble(text,bx,by,right){
const mw=Math.min(W*.35,190);
CX.font='bold 12px sans-serif';
const words=text.split(' ');const lines=[];let line='';
words.forEach(wd=>{const t2=line+wd+' ';if(CX.measureText(t2).width>mw-18&&line!==''){lines.push(line.trim());line=wd+' ';}else line=t2;});
lines.push(line.trim());
const lh=17,pad=9,bw2=mw,bh2=lines.length*lh+pad*2;
const ox=right?bx-bw2*.5-8:bx-bw2*.5+8,oy=by-bh2-18;
CX.fillStyle='rgba(255,255,255,.96)';CX.beginPath();if(CX.roundRect)CX.roundRect(ox,oy,bw2,bh2,12);else CX.rect(ox,oy,bw2,bh2);CX.fill();
CX.fillStyle='rgba(230,230,230,.96)';CX.beginPath();CX.moveTo(bx-8,oy+bh2);CX.lineTo(bx+8,oy+bh2);CX.lineTo(bx,oy+bh2+12);CX.fill();
CX.fillStyle='#111';CX.font='bold 11px sans-serif';CX.textAlign='left';
lines.forEach((l,i)=>CX.fillText(l,ox+10,oy+pad+13+i*lh));
CX.textAlign='center';
}

function drawSubs(sc){
const t=(sc.characters||[]).find(c=>c.dialogue)?.dialogue||sc.narration||'';
if(!t)return;
const g=CX.createLinearGradient(0,H*.82,0,H);g.addColorStop(0,'transparent');g.addColorStop(1,'rgba(0,0,0,.88)');
CX.fillStyle=g;CX.fillRect(0,H*.82,W,H*.18);
CX.fillStyle='white';CX.font='bold 14px sans-serif';CX.textAlign='center';
CX.shadowColor='black';CX.shadowBlur=5;CX.fillText(t,W/2,H*.94);CX.shadowBlur=0;
}

function drawVig(){
const g=CX.createRadialGradient(W/2,H/2,H*.3,W/2,H/2,W*.72);
g.addColorStop(0,'transparent');g.addColorStop(1,'rgba(0,0,0,.33)');
CX.fillStyle=g;CX.fillRect(0,0,W,H);
}

function togglePlay(){playing=!playing;document.getElementById('pb2').innerHTML=playing?'&#9646;&#9646;':'&#9654;';}
function next(){if(cur<SCENES.length-1){cur++;elapsed=0;}}
function prev(){if(cur>0){cur--;elapsed=0;}}
function toggleSub(){showSub=!showSub;}

let tx=0;
document.addEventListener('touchstart',e=>tx=e.touches[0].clientX);
document.addEventListener('touchend',e=>{const d=tx-e.changedTouches[0].clientX;if(Math.abs(d)>50){d>0?next():prev();}});
CV.addEventListener('click',e=>{
const sc=SCENES[cur];
const type=(sc?.background==='volcano'||sc?.background==='battlefield')?'explosion':'magic';
emitPart(type,e.clientX,e.clientY,type==='explosion'?20:12);
});
</script></body></html>''';
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

  void _update(Map<String, dynamic> changes) {
    setState(() {
      _scene = StoryScene.fromJson({..._scene.toJson(), ...changes});
    });
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            const Text('Edit Scene',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 16),
            _label('Background'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BackgroundType.values.map((bg) {
                return GestureDetector(
                  onTap: () => _update({'background': bg.name}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _scene.background == bg
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(bg.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _label('Time of Day'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SceneTimeOfDay.values.map((t) {
                return GestureDetector(
                  onTap: () => _update({'timeOfDay': t.name}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _scene.timeOfDay == t
                          ? const Color(0xFFFF922B)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(t.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _label('Camera Effect'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: CameraEffect.values.map((c) {
                return GestureDetector(
                  onTap: () => _update({'cameraEffect': c.name}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _scene.cameraEffect == c
                          ? const Color(0xFF20C997)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(c.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _label('Characters'),
            const SizedBox(height: 6),
            ..._scene.characters
                .asMap()
                .entries
                .map((e) => _charEditor(e.key, e.value)),
            if (_scene.characters.length < 3)
              GestureDetector(
                onTap: () {
                  final chars = List<SceneCharacter>.from(_scene.characters);
                  chars.add(SceneCharacter(
                      characterId: 'villain',
                      positionX: 0.7,
                      facingRight: false));
                  _update({
                    'characters': chars.map((c) => c.toJson()).toList()
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                      child: Text('+ Add Character',
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
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            _label('Duration: ${_scene.durationSeconds}s'),
            Slider(
              value: _scene.durationSeconds.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
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
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('Save Scene',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _charEditor(int idx, SceneCharacter char) {
    final allStates = [
      'idle', 'walk', 'run', 'attack', 'jump', 'fly', 'talk',
      'angry', 'happy', 'sad', 'victory', 'death', 'cast', 'defend'
    ];
    final allChars = CharacterRegistry.getAllIds();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Character ${idx + 1}',
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const Spacer(),
          if (_scene.characters.length > 1)
            GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters)
                  ..removeAt(idx);
                _update({'characters': chars.map((c) => c.toJson()).toList()});
              },
              child:
                  const Icon(Icons.remove_circle, color: Colors.red, size: 18),
            ),
        ]),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allChars.map((id) {
            return GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters);
                chars[idx] = SceneCharacter(
                    characterId: id,
                    positionX: char.positionX,
                    positionY: char.positionY,
                    facingRight: char.facingRight,
                    dialogue: char.dialogue,
                    scale: char.scale);
                _update(
                    {'characters': chars.map((c) => c.toJson()).toList()});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: char.characterId == id
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF0A0A14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(id,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allStates.map((s) {
            return GestureDetector(
              onTap: () {
                final chars = List<SceneCharacter>.from(_scene.characters);
                chars[idx] = SceneCharacter(
                    characterId: char.characterId,
                    state: s,
                    positionX: char.positionX,
                    positionY: char.positionY,
                    facingRight: char.facingRight,
                    dialogue: char.dialogue,
                    scale: char.scale);
                _update(
                    {'characters': chars.map((c) => c.toJson()).toList()});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: char.state == s
                      ? const Color(0xFFCC5DE8)
                      : const Color(0xFF0A0A14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: char.dialogue),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          onChanged: (v) {
            final chars = List<SceneCharacter>.from(_scene.characters);
            chars[idx] = SceneCharacter(
                characterId: char.characterId,
                state: char.state,
                positionX: char.positionX,
                positionY: char.positionY,
                facingRight: char.facingRight,
                dialogue: v,
                scale: char.scale);
            _update({'characters': chars.map((c) => c.toJson()).toList()});
          },
          decoration: InputDecoration(
            hintText: 'Dialogue...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
            filled: true,
            fillColor: const Color(0xFF0A0A14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13));
}
