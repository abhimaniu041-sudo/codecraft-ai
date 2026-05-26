import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/ai_service.dart';

class Scene {
  String id;
  String background;
  String character;
  String dialogue;
  String action;
  String music;
  int duration;

  Scene({
    required this.id,
    this.background = 'city',
    this.character = 'hero',
    this.dialogue = '',
    this.action = 'idle',
    this.music = 'none',
    this.duration = 3,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'background': background, 'character': character,
    'dialogue': dialogue, 'action': action, 'music': music, 'duration': duration,
  };

  factory Scene.fromJson(Map<String, dynamic> j) => Scene(
    id: j['id'], background: j['background'], character: j['character'],
    dialogue: j['dialogue'], action: j['action'], music: j['music'], duration: j['duration'],
  );
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with TickerProviderStateMixin {
  List<Scene> _scenes = [];
  int _currentScene = 0;
  bool _isPlaying = false;
  bool _isGenerating = false;
  late AnimationController _charController;
  late AnimationController _bgController;
  late Animation<double> _charAnim;
  late Animation<Offset> _bgAnim;
  final TextEditingController _promptCtrl = TextEditingController();
  String _projectName = 'My Story';
  bool _showSubtitles = true;

  final Map<String, Color> _backgrounds = {
    'city': const Color(0xFF1A1A2E),
    'forest': const Color(0xFF0D2818),
    'space': const Color(0xFF000011),
    'desert': const Color(0xFF3D2B1F),
    'ocean': const Color(0xFF001F3F),
    'snow': const Color(0xFF2C3E50),
    'fire': const Color(0xFF2D0A00),
    'castle': const Color(0xFF1C1C1C),
  };

  final Map<String, String> _bgEmojis = {
    'city': '🌆', 'forest': '🌲', 'space': '🌌',
    'desert': '🏜️', 'ocean': '🌊', 'snow': '❄️',
    'fire': '🔥', 'castle': '🏰',
  };

  final Map<String, String> _characters = {
    'hero': '🦸', 'villain': '🦹', 'wizard': '🧙',
    'robot': '🤖', 'ninja': '🥷', 'princess': '👸',
    'warrior': '⚔️', 'alien': '👽',
  };

  final Map<String, String> _actions = {
    'idle': '😐', 'talking': '🗣️', 'fighting': '👊',
    'running': '🏃', 'jumping': '⬆️', 'sad': '😢',
    'happy': '😄', 'angry': '😠',
  };

  @override
  void initState() {
    super.initState();
    _charController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _charAnim = Tween<double>(begin: 0, end: -15).animate(CurvedAnimation(parent: _charController, curve: Curves.easeInOut));
    _bgAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.05, 0)).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _addScene();
    _loadProject();
  }

  @override
  void dispose() {
    _charController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _addScene() {
    setState(() {
      _scenes.add(Scene(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        background: 'city',
        character: 'hero',
        dialogue: 'Scene ${_scenes.length + 1}',
      ));
    });
  }

  Future<void> _saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': _projectName,
      'scenes': _scenes.map((s) => s.toJson()).toList(),
    };
    await prefs.setString('video_project', jsonEncode(data));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Project saved!'), backgroundColor: Color(0xFF6C63FF)));
  }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('video_project');
    if (saved != null) {
      final data = jsonDecode(saved);
      setState(() {
        _projectName = data['name'] ?? 'My Story';
        _scenes = (data['scenes'] as List).map((s) => Scene.fromJson(s)).toList();
        if (_scenes.isEmpty) _addScene();
      });
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story prompt likho!')));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await AIService.sendMessage(
        userMessage: 'Create a 5-scene animated story for: "$prompt"\n\nReturn ONLY JSON array:\n[{"background":"city","character":"hero","dialogue":"text","action":"talking","music":"none","duration":3}]\n\nBackgrounds: city,forest,space,desert,ocean,snow,fire,castle\nCharacters: hero,villain,wizard,robot,ninja,princess,warrior,alien\nActions: idle,talking,fighting,running,jumping,sad,happy,angry\nMusic: none,upbeat,dramatic,peaceful,suspense',
        systemPrompt: 'You are a story generator. Return ONLY valid JSON array, no other text.',
        maxTokens: 1024,
      );

      String clean = result.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1) {
        clean = clean.substring(start, end + 1);
        final List scenes = jsonDecode(clean);
        setState(() {
          _scenes = scenes.asMap().entries.map((e) => Scene(
            id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
            background: e.value['background'] ?? 'city',
            character: e.value['character'] ?? 'hero',
            dialogue: e.value['dialogue'] ?? '',
            action: e.value['action'] ?? 'idle',
            music: e.value['music'] ?? 'none',
            duration: e.value['duration'] ?? 3,
          )).toList();
          _currentScene = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Story generate ho gayi!'), backgroundColor: Color(0xFF6C63FF)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }

    setState(() => _isGenerating = false);
  }

  void _playStory() async {
    if (_scenes.isEmpty) return;
    setState(() { _isPlaying = true; _currentScene = 0; });

    for (int i = 0; i < _scenes.length; i++) {
      if (!_isPlaying) break;
      setState(() => _currentScene = i);
      await Future.delayed(Duration(seconds: _scenes[i].duration));
    }
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes.isNotEmpty ? _scenes[_currentScene] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Row(
          children: [
            const Icon(Icons.movie, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(_projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: Color(0xFF3ECFCF)), onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.folder_open, color: Colors.grey), onPressed: _loadProject),
        ],
      ),
      body: Column(
        children: [
          // Preview
          if (scene != null)
            Container(
              height: 220,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backgrounds[scene.background] ?? const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Animated BG
                    SlideTransition(
                      position: _bgAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              (_backgrounds[scene.background] ?? Colors.black).withOpacity(0.3),
                              _backgrounds[scene.background] ?? Colors.black,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // BG emoji decoration
                    Positioned(right: 16, top: 16,
                      child: Text(_bgEmojis[scene.background] ?? '🌆',
                          style: const TextStyle(fontSize: 40, opacity: 0.3))),

                    // Stars for space
                    if (scene.background == 'space')
                      ...List.generate(8, (i) => Positioned(
                        left: (i * 80.0) % 300,
                        top: (i * 30.0) % 100,
                        child: const Text('⭐', style: TextStyle(fontSize: 12)),
                      )),

                    // Character
                    Center(
                      child: AnimatedBuilder(
                        animation: _charAnim,
                        builder: (ctx, child) => Transform.translate(
                          offset: Offset(0, _charAnim.value),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _characters[scene.character] ?? '🦸',
                                style: const TextStyle(fontSize: 72),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _actions[scene.action] ?? '😐',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Scene number
                    Positioned(top: 8, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Scene ${_currentScene + 1}/${_scenes.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),

                    // Subtitles
                    if (_showSubtitles && scene.dialogue.isNotEmpty)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(
                            scene.dialogue,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _ctrl(Icons.skip_previous, () => setState(() { if (_currentScene > 0) _currentScene--; })),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _isPlaying ? () => setState(() => _isPlaying = false) : _playStory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ctrl(Icons.skip_next, () => setState(() { if (_currentScene < _scenes.length - 1) _currentScene++; })),
                const SizedBox(width: 8),
                _ctrl(_showSubtitles ? Icons.subtitles : Icons.subtitles_off,
                    () => setState(() => _showSubtitles = !_showSubtitles)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // AI Prompt
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '🤖 Story prompt likho (e.g. hero saves city)',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF12122A),
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
          ),

          const SizedBox(height: 8),

          // Scene list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _scenes.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _scenes.length) {
                  return GestureDetector(
                    onTap: _addScene,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4), style: BorderStyle.solid),
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

                final s = _scenes[i];
                final isSelected = i == _currentScene;

                return GestureDetector(
                  onTap: () => setState(() => _currentScene = i),
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
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _backgrounds[s.background]?.withOpacity(0.6) ?? Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text(_characters[s.character] ?? '🦸', style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scene ${i + 1} • ${_bgEmojis[s.background]} ${s.background}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(s.dialogue.isEmpty ? 'No dialogue' : s.dialogue,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _editScene(i),
                              child: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 18),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => setState(() { _scenes.removeAt(i); if (_currentScene >= _scenes.length) _currentScene = _scenes.length - 1; }),
                              child: const Icon(Icons.delete, color: Colors.red, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editScene(int index) {
    final s = _scenes[index];
    final dialogCtrl = TextEditingController(text: s.dialogue);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit Scene ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                const Text('Background:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _backgrounds.keys.map((bg) => GestureDetector(
                    onTap: () { setModal(() => s.background = bg); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.background == bg ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${_bgEmojis[bg]} $bg', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                const Text('Character:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _characters.keys.map((c) => GestureDetector(
                    onTap: () { setModal(() => s.character = c); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.character == c ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${_characters[c]} $c', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                const Text('Action:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _actions.keys.map((a) => GestureDetector(
                    onTap: () { setModal(() => s.action = a); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.action == a ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${_actions[a]} $a', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                const Text('Dialogue / Subtitle:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: dialogCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  onChanged: (v) { s.dialogue = v; setState(() {}); },
                  decoration: InputDecoration(
                    hintText: 'Character kya bolega...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 12),
                const Text('Duration (seconds):', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Slider(
                  value: s.duration.toDouble(),
                  min: 1, max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF6C63FF),
                  label: '${s.duration}s',
                  onChanged: (v) { setModal(() => s.duration = v.toInt()); setState(() {}); },
                ),

                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('Done ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ctrl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
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
  }
}
