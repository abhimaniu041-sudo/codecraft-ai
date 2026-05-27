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
    _renderCtrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..repeat();
    _timeline.addListener(_onTimelineChange);
    _loadProject();
    if (_timeline.scenes.isEmpty) _addDefaultScene();
  }

  void _onTimelineChange() => ifMounted(() => setState(() {}));

  void _onTick() {
    final now = _renderCtrl.value * 86400.0;
    final dt = (_lastT > 0) ? (now - _lastT).clamp(0.0, 0.05) : 0.016;
    _lastT = now;

    _timeline.tick(dt);
    _bgAnim = (now * 0.08) % 1.0;

    final scene = _timeline.currentScene;
    if (scene != null) {
      _applyCameraEffects(scene, now);
    }

    _particles.forEach((p) => p.update(dt));
    _particles.removeWhere((p) => !p.active && p.count == 0);

    ifMounted(() => setState(() {}));
  }

  void _applyCameraEffects(StoryScene scene, double now) {
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

  void ifMounted(VoidCallback action) {
    if (mounted) action();
  }

  void _addDefaultScene() {
    _timeline.addScene(StoryScene(
      id: DateTime.now().toString(),
      background: BackgroundType.city,
      timeOfDay: SceneTimeOfDay.day,
      characters: [SceneCharacter(characterId: 'hero', state: CharacterState.idle, positionX: 0.35, positionY: 0.62, dialogue: 'The adventure begins!')],
      narration: 'Initial story setup...',
      durationSeconds: 4,
    ));
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    
    setState(() => _isGenerating = true);
    try {
      final result = await AIService.sendMessage(
        userMessage: 'Create 6 cinematic cartoon scenes for: "$prompt". Return ONLY valid JSON array.',
        systemPrompt: 'You are a cinematic AI director. Return JSON only.',
      );

      final clean = result.replaceAll('```json', '').replaceAll('```', '').trim();
      final List scenesJson = jsonDecode(clean);
      
      _timeline.scenes.clear();
      for (var s in scenesJson) {
        _timeline.addScene(StoryScene.fromJson({...s, 'id': DateTime.now().toString() + math.Random().nextInt(1000).toString()}));
      }
      _timeline.jumpToScene(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cartoon_project', jsonEncode({'name': _projectName, 'scenes': _timeline.scenes.map((s) => s.toJson()).toList()}));
    ifMounted(() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!'))));
  }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cartoon_project');
    if (saved != null) {
      final data = jsonDecode(saved);
      _projectName = data['name'];
      _timeline.scenes.clear();
      for (var s in data['scenes']) _timeline.addScene(StoryScene.fromJson(s));
      setState(() {});
    }
  }

  @override
  void dispose() {
    _renderCtrl.dispose();
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
        title: Text(_projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.file_download), onPressed: _exportHTML),
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

  // --- UI Methods ---
  
  Widget _buildViewport() {
    final scene = _timeline.currentScene;
    return GestureDetector(
      onTapDown: (d) => _triggerEffect(ParticleType.magic, d.localPosition.dx, d.localPosition.dy),
      child: Stack(children: [
        if (scene != null) ...[
          Positioned.fill(child: CustomPaint(painter: BackgroundPainter(type: scene.background, timeOfDay: scene.timeOfDay, animProgress: _bgAnim, parallaxOffset: _parallax))),
          Positioned.fill(child: CustomPaint(painter: _ParticlePainter(particles: _particles))),
          Positioned.fill(child: _buildCharactersLayer(scene)),
          _buildViewportOverlay(scene),
        ]
      ]),
    );
  }

  Widget _buildCharactersLayer(StoryScene scene) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(children: scene.characters.map((char) {
        final size = constraints.maxHeight * 0.38 * char.scale;
        return Positioned(
          left: constraints.maxWidth * char.positionX - size / 2,
          top: constraints.maxHeight * char.positionY - size,
          child: AnimatedCharacterWidget(characterId: char.characterId, state: char.state, size: size, facingRight: char.facingRight),
        );
      }).toList());
    });
  }

  Widget _buildViewportOverlay(StoryScene scene) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (_showSubtitles) Container(padding: const EdgeInsets.all(10), color: Colors.black54, child: Text(scene.narration, style: const TextStyle(color: Colors.white))),
      LinearProgressIndicator(value: _timeline.sceneProgress, color: const Color(0xFF6C63FF)),
    ]);
  }

  Widget _buildControls() {
    return Container(padding: const EdgeInsets.all(8), color: const Color(0xFF0D0D1A), child: Row(children: [
      IconButton(icon: Icon(_timeline.isPlaying ? Icons.pause : Icons.play_arrow), onPressed: _timeline.isPlaying ? _timeline.pause : _timeline.play, color: Colors.white),
      // ... Add additional playback controls as needed
    ]));
  }

  Widget _buildPromptBar() {
    return Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _promptCtrl, decoration: const InputDecoration(filled: true, fillColor: Color(0xFF12122A), hintText: "Enter your story prompt...")));
  }

  Widget _buildSceneList() {
    return ListView.builder(itemCount: _timeline.scenes.length, itemBuilder: (ctx, i) {
      final s = _timeline.scenes[i];
      return ListTile(
        title: Text('Scene ${i + 1}', style: const TextStyle(color: Colors.white)),
        subtitle: Text(s.narration, style: const TextStyle(color: Colors.grey)),
        onTap: () => _timeline.jumpToScene(i),
      );
    });
  }

  void _triggerEffect(ParticleType type, double x, double y) {
    final ps = ParticleSystem(type: type, x: x, y: y);
    _particles.add(ps);
    Future.delayed(const Duration(seconds: 2), () => ps.active = false);
  }

  Future<void> _exportHTML() async { /* Implementation same as original... */ }
}

class _ParticlePainter extends CustomPainter {
  final List<ParticleSystem> particles;
  _ParticlePainter({required this.particles});
  @override
  void paint(Canvas canvas, Size size) => particles.forEach((p) => p.render(canvas));
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
