import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../services/ai_service.dart';

class Scene {
  String id;
  String background;
  String character1;
  String character2;
  String character3;
  String dialogue1;
  String dialogue2;
  String action1;
  String action2;
  String music;
  String transition;
  int duration;

  Scene({
    required this.id,
    this.background = 'city',
    this.character1 = 'hero',
    this.character2 = 'none',
    this.character3 = 'none',
    this.dialogue1 = '',
    this.dialogue2 = '',
    this.action1 = 'idle',
    this.action2 = 'idle',
    this.music = 'none',
    this.transition = 'fade',
    this.duration = 3,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'background': background,
    'character1': character1, 'character2': character2, 'character3': character3,
    'dialogue1': dialogue1, 'dialogue2': dialogue2,
    'action1': action1, 'action2': action2,
    'music': music, 'transition': transition, 'duration': duration,
  };

  factory Scene.fromJson(Map<String, dynamic> j) => Scene(
    id: j['id'] ?? DateTime.now().toString(),
    background: j['background'] ?? 'city',
    character1: j['character1'] ?? 'hero',
    character2: j['character2'] ?? 'none',
    character3: j['character3'] ?? 'none',
    dialogue1: j['dialogue1'] ?? '',
    dialogue2: j['dialogue2'] ?? '',
    action1: j['action1'] ?? 'idle',
    action2: j['action2'] ?? 'idle',
    music: j['music'] ?? 'none',
    transition: j['transition'] ?? 'fade',
    duration: j['duration'] ?? 3,
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
  bool _isExporting = false;
  bool _showSubtitles = true;
  late AnimationController _charController;
  late AnimationController _bgController;
  late AnimationController _transController;
  late Animation<double> _charAnim;
  late Animation<double> _transAnim;
  final TextEditingController _promptCtrl = TextEditingController();
  String _projectName = 'My Story';

  final Map<String, List<Color>> _backgrounds = {
    'city': [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
    'forest': [const Color(0xFF0D2818), const Color(0xFF1A4731)],
    'space': [const Color(0xFF000011), const Color(0xFF0A0A2E)],
    'desert': [const Color(0xFF3D2B1F), const Color(0xFF5C3D2E)],
    'ocean': [const Color(0xFF001F3F), const Color(0xFF003366)],
    'snow': [const Color(0xFF2C3E50), const Color(0xFF3D5A6B)],
    'fire': [const Color(0xFF2D0A00), const Color(0xFF4A1500)],
    'castle': [const Color(0xFF1C1C1C), const Color(0xFF2D2D2D)],
    'volcano': [const Color(0xFF3D0000), const Color(0xFF5C1A00)],
    'sky': [const Color(0xFF1A6B9A), const Color(0xFF2E86C1)],
  };

  final Map<String, String> _bgEmojis = {
    'city': '🌆', 'forest': '🌲', 'space': '🌌', 'desert': '🏜️',
    'ocean': '🌊', 'snow': '❄️', 'fire': '🔥', 'castle': '🏰',
    'volcano': '🌋', 'sky': '☁️',
  };

  final Map<String, String> _characters = {
    'none': '➖', 'hero': '🦸', 'villain': '🦹', 'wizard': '🧙',
    'robot': '🤖', 'ninja': '🥷', 'princess': '👸', 'warrior': '⚔️',
    'alien': '👽', 'dragon': '🐲', 'knight': '🛡️', 'archer': '🏹',
  };

  final Map<String, String> _actions = {
    'idle': '😐', 'talking': '🗣️', 'fighting': '👊', 'running': '🏃',
    'jumping': '⬆️', 'sad': '😢', 'happy': '😄', 'angry': '😠',
    'casting': '✨', 'defending': '🛡️',
  };

  final Map<String, String> _transitions = {
    'fade': '🌫️ Fade', 'slide': '➡️ Slide', 'zoom': '🔍 Zoom',
    'flash': '⚡ Flash', 'none': '▶️ None',
  };

  final Map<String, String> _musicOptions = {
    'none': '🔇 None', 'epic': '⚔️ Epic Battle', 'peaceful': '🕊️ Peaceful',
    'mystery': '🔮 Mystery', 'horror': '👻 Horror', 'happy': '😊 Happy',
    'sad': '😢 Sad', 'action': '💥 Action',
  };

  @override
  void initState() {
    super.initState();
    _charController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _transController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _charAnim = Tween<double>(begin: 0, end: -20).animate(CurvedAnimation(parent: _charController, curve: Curves.easeInOut));
    _transAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _transController, curve: Curves.easeInOut));
    _addScene();
    _loadProject();
  }

  @override
  void dispose() {
    _charController.dispose();
    _bgController.dispose();
    _transController.dispose();
    super.dispose();
  }

  void _addScene() {
    setState(() {
      _scenes.add(Scene(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  Future<void> _saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('video_project', jsonEncode({
      'name': _projectName,
      'scenes': _scenes.map((s) => s.toJson()).toList(),
    }));
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
        userMessage: '''Create 6 scenes for: "$prompt"
Return ONLY JSON array:
[{"background":"city","character1":"hero","character2":"villain","character3":"none","dialogue1":"Hero speaks","dialogue2":"Villain speaks","action1":"talking","action2":"angry","music":"epic","transition":"fade","duration":4}]
Backgrounds: city,forest,space,desert,ocean,snow,fire,castle,volcano,sky
Characters: none,hero,villain,wizard,robot,ninja,princess,warrior,alien,dragon,knight,archer
Actions: idle,talking,fighting,running,jumping,sad,happy,angry,casting,defending
Music: none,epic,peaceful,mystery,horror,happy,sad,action
Transitions: fade,slide,zoom,flash,none''',
        systemPrompt: 'Return ONLY valid JSON array. No other text.',
        maxTokens: 2048,
      );
      String clean = result.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final List scenes = jsonDecode(clean.substring(start, end + 1));
        setState(() {
          _scenes = scenes.asMap().entries.map((e) => Scene.fromJson({
            ...e.value,
            'id': '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
          })).toList();
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
    if (_scenes.isEmpty || _isPlaying) return;
    setState(() { _isPlaying = true; _currentScene = 0; });
    for (int i = 0; i < _scenes.length; i++) {
      if (!_isPlaying) break;
      _transController.forward(from: 0);
      setState(() => _currentScene = i);
      await Future.delayed(Duration(seconds: _scenes[i].duration));
    }
    setState(() => _isPlaying = false);
  }

  Future<void> _exportHTML() async {
    setState(() => _isExporting = true);
    try {
      final html = _generateHTML();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${_projectName.replaceAll(' ', '_')}_story.html';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(html);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12122A),
            title: const Text('✅ Story Exported!', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie, color: Color(0xFF6C63FF), size: 48),
                const SizedBox(height: 12),
                const Text('HTML story ready hai!\nBrowser mein open karo ya share karo.',
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

  String _generateHTML() {
    final scenesJson = jsonEncode(_scenes.map((s) => s.toJson()).toList());

    final Map<String, String> bgCss = {
      'city': 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)',
      'forest': 'linear-gradient(135deg, #0d2818 0%, #1a4731 50%, #2d6a4f 100%)',
      'space': 'linear-gradient(135deg, #000011 0%, #0a0a2e 50%, #1a1a4e 100%)',
      'desert': 'linear-gradient(135deg, #3d2b1f 0%, #5c3d2e 50%, #8b6347 100%)',
      'ocean': 'linear-gradient(135deg, #001f3f 0%, #003366 50%, #0066cc 100%)',
      'snow': 'linear-gradient(135deg, #2c3e50 0%, #3d5a6b 50%, #6b8fa1 100%)',
      'fire': 'linear-gradient(135deg, #2d0a00 0%, #7a1500 50%, #cc3300 100%)',
      'castle': 'linear-gradient(135deg, #1c1c1c 0%, #2d2d2d 50%, #4a4a4a 100%)',
      'volcano': 'linear-gradient(135deg, #3d0000 0%, #7a1a00 50%, #cc4400 100%)',
      'sky': 'linear-gradient(135deg, #1a6b9a 0%, #2e86c1 50%, #85c1e9 100%)',
    };

    final Map<String, String> charEmoji = {
      'none': '', 'hero': '🦸', 'villain': '🦹', 'wizard': '🧙',
      'robot': '🤖', 'ninja': '🥷', 'princess': '👸', 'warrior': '⚔️',
      'alien': '👽', 'dragon': '🐲', 'knight': '🛡️', 'archer': '🏹',
    };

    final Map<String, String> actionEmoji = {
      'idle': '', 'talking': '💬', 'fighting': '💥', 'running': '💨',
      'jumping': '⬆️', 'sad': '😢', 'happy': '🎉', 'angry': '💢',
      'casting': '✨', 'defending': '🛡️',
    };

    final Map<String, String> musicFreqs = {
      'none': '0', 'epic': '200', 'peaceful': '440', 'mystery': '300',
      'horror': '100', 'happy': '523', 'sad': '220', 'action': '350',
    };

    String scenesHtml = '';
    for (int i = 0; i < _scenes.length; i++) {
      final s = _scenes[i];
      final bg = bgCss[s.background] ?? bgCss['city']!;
      final c1 = charEmoji[s.character1] ?? '';
      final c2 = charEmoji[s.character2] ?? '';
      final c3 = charEmoji[s.character3] ?? '';
      final a1 = actionEmoji[s.action1] ?? '';
      final a2 = actionEmoji[s.action2] ?? '';
      final freq = musicFreqs[s.music] ?? '0';

      scenesHtml += '''
<div class="scene" id="scene$i" data-duration="${s.duration}" data-music="$freq" data-transition="${s.transition}">
  <div class="scene-bg" style="background: $bg;"></div>
  
  <!-- 3D Environment -->
  <div class="env-3d">
    <div class="floor"></div>
    <div class="wall-left"></div>
    <div class="wall-right"></div>
    ${s.background == 'space' ? '<div class="stars"></div>' : ''}
    ${s.background == 'fire' || s.background == 'volcano' ? '<div class="flames"></div>' : ''}
    ${s.background == 'snow' ? '<div class="snowflakes"></div>' : ''}
  </div>

  <!-- Scene Number -->
  <div class="scene-num">Scene ${i + 1}/${_scenes.length}</div>

  <!-- Background label -->
  <div class="bg-label">${_bgEmojis[s.background] ?? ''} ${s.background}</div>

  <!-- Characters -->
  <div class="characters-area">
    ${c1.isNotEmpty ? '''
    <div class="character char-left animate-${s.action1}">
      <div class="char-shadow"></div>
      <div class="char-body">$c1</div>
      ${a1.isNotEmpty ? '<div class="char-action">$a1</div>' : ''}
      ${s.dialogue1.isNotEmpty ? '<div class="speech-bubble left">${s.dialogue1}</div>' : ''}
    </div>''' : ''}
    
    ${c2.isNotEmpty && c2 != '' ? '''
    <div class="character char-right animate-${s.action2}">
      <div class="char-shadow"></div>
      <div class="char-body">$c2</div>
      ${a2.isNotEmpty ? '<div class="char-action">$a2</div>' : ''}
      ${s.dialogue2.isNotEmpty ? '<div class="speech-bubble right">${s.dialogue2}</div>' : ''}
    </div>''' : ''}

    ${c3.isNotEmpty && c3 != '' ? '''
    <div class="character char-center">
      <div class="char-shadow"></div>
      <div class="char-body">$c3</div>
    </div>''' : ''}
  </div>

  <!-- Subtitle -->
  <div class="subtitle">
    ${s.dialogue1.isNotEmpty ? s.dialogue1 : (s.dialogue2.isNotEmpty ? s.dialogue2 : '')}
  </div>
</div>''';
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>${_projectName}</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#000; font-family: 'Segoe UI', sans-serif; overflow:hidden; width:100vw; height:100vh; }

.scene {
  position:absolute; width:100%; height:100%;
  display:none; overflow:hidden;
}
.scene.active { display:block; }
.scene-bg {
  position:absolute; inset:0;
  animation: bgPulse 4s ease-in-out infinite alternate;
}
@keyframes bgPulse { from { filter: brightness(0.9); } to { filter: brightness(1.1); } }

/* 3D Environment */
.env-3d {
  position:absolute; inset:0;
  perspective: 800px;
  transform-style: preserve-3d;
}
.floor {
  position:absolute; bottom:0; left:-20%; right:-20%;
  height:35%; background: rgba(0,0,0,0.4);
  transform: rotateX(60deg) translateZ(-50px);
  border-top: 2px solid rgba(255,255,255,0.1);
}
.wall-left {
  position:absolute; left:0; top:0; bottom:0;
  width:15%; background: rgba(0,0,0,0.3);
  transform: rotateY(30deg);
}
.wall-right {
  position:absolute; right:0; top:0; bottom:0;
  width:15%; background: rgba(0,0,0,0.3);
  transform: rotateY(-30deg);
}

/* Stars */
.stars {
  position:absolute; inset:0;
  background-image:
    radial-gradient(2px 2px at 10% 20%, white, transparent),
    radial-gradient(2px 2px at 30% 10%, white, transparent),
    radial-gradient(1px 1px at 50% 30%, white, transparent),
    radial-gradient(2px 2px at 70% 15%, white, transparent),
    radial-gradient(1px 1px at 90% 25%, white, transparent),
    radial-gradient(2px 2px at 20% 40%, white, transparent),
    radial-gradient(1px 1px at 80% 35%, white, transparent),
    radial-gradient(2px 2px at 45% 5%, white, transparent);
  animation: twinkle 3s ease-in-out infinite alternate;
}
@keyframes twinkle { from { opacity:0.6; } to { opacity:1; } }

/* Flames */
.flames {
  position:absolute; bottom:0; left:0; right:0; height:40%;
  background: linear-gradient(to top, #ff4500, #ff8c00, transparent);
  animation: flicker 0.3s ease-in-out infinite alternate;
  clip-path: polygon(0 100%, 10% 60%, 20% 80%, 30% 40%, 40% 70%, 50% 30%, 60% 65%, 70% 35%, 80% 75%, 90% 50%, 100% 100%);
}
@keyframes flicker { from { transform: scaleX(1); } to { transform: scaleX(1.05); } }

/* Snow */
.snowflakes::before {
  content: "❄️ ❄️ ❄️ ❄️ ❄️";
  position:absolute; top:5%; left:0; right:0;
  font-size:20px; text-align:center;
  animation: snow 3s linear infinite;
}
@keyframes snow { from { transform: translateY(-20px); opacity:1; } to { transform: translateY(100vh); opacity:0; } }

/* Characters */
.characters-area {
  position:absolute; bottom:25%; left:0; right:0;
  display:flex; justify-content:space-around; align-items:flex-end;
  padding: 0 10%;
}
.character {
  position:relative; display:flex; flex-direction:column;
  align-items:center; animation: float 2s ease-in-out infinite alternate;
}
@keyframes float { from { transform: translateY(0px); } to { transform: translateY(-15px); } }

.char-body {
  font-size: clamp(50px, 12vw, 90px);
  filter: drop-shadow(0 10px 20px rgba(0,0,0,0.8));
  transition: transform 0.3s;
}
.char-shadow {
  position:absolute; bottom:-10px;
  width:60%; height:12px;
  background: rgba(0,0,0,0.5);
  border-radius:50%;
  filter: blur(4px);
}
.char-action {
  font-size:24px; margin-top:4px;
  animation: actionPop 0.5s ease-in-out infinite alternate;
}
@keyframes actionPop { from { transform: scale(1); } to { transform: scale(1.3); } }

/* Animations per action */
.animate-fighting .char-body { animation: fight 0.3s ease-in-out infinite alternate; }
@keyframes fight { from { transform: rotate(-10deg); } to { transform: rotate(10deg); } }
.animate-running .char-body { animation: run 0.4s ease-in-out infinite alternate; }
@keyframes run { from { transform: translateX(-5px) rotate(-5deg); } to { transform: translateX(5px) rotate(5deg); } }
.animate-jumping .char-body { animation: jump 0.6s ease-in-out infinite; }
@keyframes jump { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-30px); } }
.animate-casting .char-body { animation: cast 1s ease-in-out infinite; }
@keyframes cast { 0%,100% { filter: drop-shadow(0 0 5px gold); } 50% { filter: drop-shadow(0 0 25px gold) brightness(1.3); } }

/* Speech Bubbles */
.speech-bubble {
  position:absolute;
  background: rgba(255,255,255,0.95);
  color: #111;
  padding: 8px 12px;
  border-radius: 16px;
  font-size: clamp(10px, 2.5vw, 14px);
  font-weight:600;
  max-width: 150px;
  text-align:center;
  white-space: normal;
  word-break: break-word;
  z-index:10;
  animation: bubblePop 0.3s ease-out;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
}
@keyframes bubblePop { from { transform: scale(0); opacity:0; } to { transform: scale(1); opacity:1; } }
.speech-bubble.left {
  bottom: 110%;
  left: -20px;
}
.speech-bubble.left::after {
  content:''; position:absolute; bottom:-10px; left:20px;
  border:10px solid transparent; border-top-color: rgba(255,255,255,0.95);
  border-bottom:0;
}
.speech-bubble.right {
  bottom: 110%;
  right: -20px;
}
.speech-bubble.right::after {
  content:''; position:absolute; bottom:-10px; right:20px;
  border:10px solid transparent; border-top-color: rgba(255,255,255,0.95);
  border-bottom:0;
}

/* Subtitle */
.subtitle {
  position:absolute; bottom:0; left:0; right:0;
  padding: 12px 20px 16px;
  background: linear-gradient(transparent, rgba(0,0,0,0.85));
  color:white; text-align:center;
  font-size: clamp(13px, 3vw, 18px);
  font-weight:500;
  text-shadow: 0 2px 4px rgba(0,0,0,0.8);
  letter-spacing: 0.3px;
  min-height: 60px;
  display:flex; align-items:center; justify-content:center;
}

/* Scene info */
.scene-num {
  position:absolute; top:12px; left:12px;
  background: rgba(0,0,0,0.6);
  color:white; padding: 5px 12px;
  border-radius:20px; font-size:12px;
  backdrop-filter: blur(4px);
}
.bg-label {
  position:absolute; top:12px; right:12px;
  background: rgba(0,0,0,0.6);
  color:white; padding: 5px 12px;
  border-radius:20px; font-size:12px;
  backdrop-filter: blur(4px);
}

/* Controls */
#controls {
  position:fixed; bottom:0; left:0; right:0;
  height: 70px;
  background: rgba(0,0,0,0.9);
  display:flex; align-items:center; justify-content:center;
  gap:16px; z-index:100;
  border-top: 1px solid rgba(255,255,255,0.1);
  backdrop-filter: blur(10px);
}
.ctrl-btn {
  background: rgba(255,255,255,0.1);
  border: 1px solid rgba(255,255,255,0.2);
  color:white; padding: 10px 20px;
  border-radius:25px; font-size:16px;
  cursor:pointer; transition: all 0.2s;
}
.ctrl-btn:active { transform: scale(0.95); }
.ctrl-btn.primary {
  background: linear-gradient(135deg, #6c63ff, #3ecfcf);
  border:none; padding: 12px 32px; font-size:18px;
}

/* Progress bar */
#progress-bar {
  position:fixed; top:0; left:0; height:3px;
  background: linear-gradient(90deg, #6c63ff, #3ecfcf);
  transition: width 0.1s linear; z-index:200;
}

/* Transition overlay */
#trans-overlay {
  position:fixed; inset:0;
  background:black; opacity:0;
  pointer-events:none; z-index:150;
  transition: opacity 0.3s;
}

/* Title screen */
#title-screen {
  position:fixed; inset:0;
  background: linear-gradient(135deg, #0a0a14, #1a1a2e);
  display:flex; flex-direction:column;
  align-items:center; justify-content:center;
  z-index:300; color:white;
}
#title-screen h1 {
  font-size: clamp(28px, 8vw, 48px);
  background: linear-gradient(135deg, #6c63ff, #3ecfcf);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  margin-bottom:8px;
}
#title-screen p { color:#888; margin-bottom:40px; font-size:14px; }
#start-btn {
  background: linear-gradient(135deg, #6c63ff, #3ecfcf);
  border:none; color:white; padding: 16px 40px;
  border-radius:30px; font-size:18px; font-weight:bold;
  cursor:pointer; animation: pulse 2s ease-in-out infinite;
}
@keyframes pulse { 0%,100% { box-shadow: 0 0 0 0 rgba(108,99,255,0.4); } 50% { box-shadow: 0 0 0 20px rgba(108,99,255,0); } }

/* Particles */
.particle {
  position:absolute; border-radius:50%;
  animation: particleFloat linear infinite;
  pointer-events:none;
}
@keyframes particleFloat {
  0% { transform: translateY(100vh) scale(0); opacity:1; }
  100% { transform: translateY(-100px) scale(1); opacity:0; }
}
</style>
</head>
<body>

<div id="progress-bar" style="width:0%"></div>
<div id="trans-overlay"></div>

<!-- Title Screen -->
<div id="title-screen">
  <div style="font-size:60px; margin-bottom:16px;">🎬</div>
  <h1>${_projectName}</h1>
  <p>${_scenes.length} scenes • Animated Story</p>
  <button id="start-btn" onclick="startStory()">▶ Play Story</button>
</div>

$scenesHtml

<!-- Controls -->
<div id="controls" style="display:none;">
  <button class="ctrl-btn" onclick="prevScene()">⏮</button>
  <button class="ctrl-btn primary" id="play-btn" onclick="togglePlay()">⏸</button>
  <button class="ctrl-btn" onclick="nextScene()">⏭</button>
  <button class="ctrl-btn" onclick="toggleSubtitles()" id="sub-btn">💬</button>
  <button class="ctrl-btn" onclick="toggleSound()" id="sound-btn">🔊</button>
</div>

<script>
const scenes = ${scenesJson};
let current = 0;
let playing = true;
let timer = null;
let soundEnabled = true;
let subtitlesEnabled = true;
let audioCtx = null;

function getAudioCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  return audioCtx;
}

function playTone(freq, duration, type = 'sine', volume = 0.3) {
  if (!soundEnabled || freq == 0) return;
  try {
    const ctx = getAudioCtx();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.type = type;
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    gain.gain.setValueAtTime(volume, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
    osc.start();
    osc.stop(ctx.currentTime + duration);
  } catch(e) {}
}

function playSceneSound(scene) {
  const musicMap = {
    'epic': [[200,0.8,'sawtooth',0.2],[300,0.6,'square',0.15],[400,0.4,'sine',0.1]],
    'peaceful': [[440,1.5,'sine',0.15],[550,1.2,'sine',0.1]],
    'mystery': [[150,2,'sine',0.1],[200,1.5,'triangle',0.08]],
    'horror': [[80,2,'sawtooth',0.2],[120,1.5,'square',0.15]],
    'happy': [[523,0.3,'sine',0.2],[659,0.3,'sine',0.2],[784,0.3,'sine',0.2]],
    'sad': [[220,1,'sine',0.15],[196,1.5,'sine',0.12]],
    'action': [[350,0.2,'square',0.2],[400,0.2,'square',0.2],[450,0.3,'sawtooth',0.15]],
  };
  const tones = musicMap[scene.music];
  if (tones) {
    let delay = 0;
    tones.forEach(([f,d,t,v]) => {
      setTimeout(() => playTone(f, d, t, v), delay * 1000);
      delay += d * 0.7;
    });
  }
}

function showScene(index) {
  document.querySelectorAll('.scene').forEach(s => s.classList.remove('active'));
  const el = document.getElementById('scene' + index);
  if (!el) return;

  const scene = scenes[index];
  const overlay = document.getElementById('trans-overlay');

  if (scene.transition === 'fade') {
    overlay.style.opacity = '1';
    setTimeout(() => {
      el.classList.add('active');
      overlay.style.opacity = '0';
    }, 300);
  } else if (scene.transition === 'flash') {
    overlay.style.opacity = '1';
    overlay.style.background = 'white';
    el.classList.add('active');
    setTimeout(() => {
      overlay.style.opacity = '0';
      overlay.style.background = 'black';
    }, 100);
  } else {
    el.classList.add('active');
  }

  // Subtitles
  const sub = el.querySelector('.subtitle');
  if (sub) sub.style.display = subtitlesEnabled ? 'flex' : 'none';

  // Progress
  const progress = ((index + 1) / scenes.length) * 100;
  document.getElementById('progress-bar').style.width = progress + '%';

  // Sound
  playSceneSound(scene);

  // Particles for special scenes
  if (scene.background === 'fire' || scene.background === 'volcano') {
    addParticles(el, '#ff4500', '#ff8c00');
  } else if (scene.background === 'space') {
    addParticles(el, '#ffffff', '#a0a0ff');
  }
}

function addParticles(container, color1, color2) {
  for (let i = 0; i < 5; i++) {
    setTimeout(() => {
      const p = document.createElement('div');
      p.className = 'particle';
      p.style.cssText = \`
        left: \${Math.random() * 100}%;
        width: \${Math.random() * 8 + 3}px;
        height: \${Math.random() * 8 + 3}px;
        background: \${Math.random() > 0.5 ? color1 : color2};
        animation-duration: \${Math.random() * 3 + 2}s;
        animation-delay: \${Math.random() * 2}s;
        opacity: \${Math.random() * 0.7 + 0.3};
      \`;
      container.appendChild(p);
      setTimeout(() => p.remove(), 6000);
    }, i * 200);
  }
}

function startStory() {
  document.getElementById('title-screen').style.display = 'none';
  document.getElementById('controls').style.display = 'flex';
  showScene(0);
  scheduleNext();
}

function scheduleNext() {
  if (timer) clearTimeout(timer);
  if (!playing) return;
  const duration = (scenes[current]?.duration || 3) * 1000;
  timer = setTimeout(() => {
    if (current < scenes.length - 1) {
      current++;
      showScene(current);
      scheduleNext();
    } else {
      playing = false;
      document.getElementById('play-btn').textContent = '▶';
    }
  }, duration);
}

function togglePlay() {
  playing = !playing;
  document.getElementById('play-btn').textContent = playing ? '⏸' : '▶';
  if (playing) {
    if (current >= scenes.length - 1) { current = 0; showScene(0); }
    scheduleNext();
  } else {
    clearTimeout(timer);
  }
}

function nextScene() {
  clearTimeout(timer);
  if (current < scenes.length - 1) { current++; showScene(current); }
  if (playing) scheduleNext();
}

function prevScene() {
  clearTimeout(timer);
  if (current > 0) { current--; showScene(current); }
  if (playing) scheduleNext();
}

function toggleSubtitles() {
  subtitlesEnabled = !subtitlesEnabled;
  document.getElementById('sub-btn').textContent = subtitlesEnabled ? '💬' : '🔇';
  document.querySelectorAll('.subtitle').forEach(s => {
    s.style.display = subtitlesEnabled ? 'flex' : 'none';
  });
}

function toggleSound() {
  soundEnabled = !soundEnabled;
  document.getElementById('sound-btn').textContent = soundEnabled ? '🔊' : '🔇';
}

// Touch swipe
let touchX = 0;
document.addEventListener('touchstart', e => touchX = e.touches[0].clientX);
document.addEventListener('touchend', e => {
  const diff = touchX - e.changedTouches[0].clientX;
  if (Math.abs(diff) > 50) {
    if (diff > 0) nextScene(); else prevScene();
  }
});
</script>
</body>
</html>''';
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
            Expanded(
              child: GestureDetector(
                onTap: () => _renameProject(),
                child: Text(_projectName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
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
          // Preview
          if (scene != null)
            Container(
              height: 200,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _backgrounds[scene.background] ?? [Colors.black, Colors.black87],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // BG decoration
                    if (scene.background == 'space')
                      ...List.generate(10, (i) => Positioned(
                        left: (i * 63.0) % 300, top: (i * 37.0) % 120,
                        child: const Text('⭐', style: TextStyle(fontSize: 10)),
                      )),
                    if (scene.background == 'fire' || scene.background == 'volcano')
                      Positioned(bottom: 0, left: 0, right: 0,
                        child: Container(height: 50,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: [Color(0xFFFF4500), Colors.transparent],
                            ),
                          ),
                        ),
                      ),

                    // Characters
                    AnimatedBuilder(
                      animation: _charAnim,
                      builder: (ctx, _) => Positioned(
                        bottom: 50, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_characters[scene.character1] != '➖' && scene.character1 != 'none')
                              Transform.translate(
                                offset: Offset(0, _charAnim.value),
                                child: Column(
                                  children: [
                                    if (scene.dialogue1.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                        child: Text(scene.dialogue1,
                                            style: const TextStyle(color: Colors.black, fontSize: 9),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ),
                                    Text(_characters[scene.character1] ?? '', style: const TextStyle(fontSize: 48)),
                                    Text(_actions[scene.action1] ?? '', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            if (_characters[scene.character2] != '➖' && scene.character2 != 'none')
                              Transform.translate(
                                offset: Offset(0, -_charAnim.value),
                                child: Column(
                                  children: [
                                    if (scene.dialogue2.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                        child: Text(scene.dialogue2,
                                            style: const TextStyle(color: Colors.black, fontSize: 9),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ),
                                    Text(_characters[scene.character2] ?? '', style: const TextStyle(fontSize: 48)),
                                    Text(_actions[scene.action2] ?? '', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            if (_characters[scene.character3] != '➖' && scene.character3 != 'none')
                              Text(_characters[scene.character3] ?? '', style: const TextStyle(fontSize: 38)),
                          ],
                        ),
                      ),
                    ),

                    // Scene info
                    Positioned(top: 8, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                        child: Text('Scene ${_currentScene + 1}/${_scenes.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ),

                    // Subtitle
                    if (_showSubtitles && scene.dialogue1.isNotEmpty)
                      Positioned(bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(scene.dialogue1, textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _ctrlBtn(Icons.skip_previous, () => setState(() { if (_currentScene > 0) _currentScene--; })),
                const SizedBox(width: 6),
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
                const SizedBox(width: 6),
                _ctrlBtn(Icons.skip_next, () => setState(() { if (_currentScene < _scenes.length - 1) _currentScene++; })),
                const SizedBox(width: 6),
                _ctrlBtn(_showSubtitles ? Icons.subtitles : Icons.subtitles_off,
                    () => setState(() => _showSubtitles = !_showSubtitles)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // AI Prompt
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '🤖 AI se story generate karo...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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
          ),

          const SizedBox(height: 8),

          // Scene List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _scenes.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _scenes.length) {
                  return GestureDetector(
                    onTap: _addScene,
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
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _backgrounds[s.background] ?? [Colors.black, Colors.black87]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${_characters[s.character1] ?? ''}${s.character2 != 'none' ? _characters[s.character2] ?? '' : ''}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scene ${i + 1} • ${_bgEmojis[s.background]} ${s.background}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                s.dialogue1.isNotEmpty ? s.dialogue1 : (s.dialogue2.isNotEmpty ? s.dialogue2 : 'No dialogue'),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _editScene(i),
                              child: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 18),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => setState(() {
                                _scenes.removeAt(i);
                                if (_currentScene >= _scenes.length) _currentScene = _scenes.length - 1;
                              }),
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

  void _renameProject() {
    final ctrl = TextEditingController(text: _projectName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        title: const Text('Project Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            filled: true, fillColor: Color(0xFF1A1A2E),
            border: OutlineInputBorder(),
            hintText: 'Project naam...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { setState(() => _projectName = ctrl.text.trim()); Navigator.pop(ctx); },
              child: const Text('Save', style: TextStyle(color: Color(0xFF6C63FF)))),
        ],
      ),
    );
  }

  void _editScene(int index) {
    final s = _scenes[index];
    final d1Ctrl = TextEditingController(text: s.dialogue1);
    final d2Ctrl = TextEditingController(text: s.dialogue2);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16, right: 16, top: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text('Edit Scene ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),

                _editLabel('🌍 Background'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
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
                _editLabel('🦸 Character 1'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: _characters.keys.map((c) => GestureDetector(
                    onTap: () { setModal(() => s.character1 = c); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.character1 == c ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${_characters[c]} $c', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 8),
                _editLabel('💬 Dialogue 1'),
                const SizedBox(height: 6),
                TextField(
                  controller: d1Ctrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) { s.dialogue1 = v; setState(() {}); },
                  decoration: _inputDec('Character 1 kya bolega...'),
                ),

                const SizedBox(height: 12),
                _editLabel('🦹 Character 2'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: _characters.keys.map((c) => GestureDetector(
                    onTap: () { setModal(() => s.character2 = c); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.character2 == c ? const Color(0xFFCC5DE8) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${_characters[c]} $c', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 8),
                _editLabel('💬 Dialogue 2'),
                const SizedBox(height: 6),
                TextField(
                  controller: d2Ctrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) { s.dialogue2 = v; setState(() {}); },
                  decoration: _inputDec('Character 2 kya bolega...'),
                ),

                const SizedBox(height: 12),
                _editLabel('🎵 Music/Sound'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: _musicOptions.keys.map((m) => GestureDetector(
                    onTap: () { setModal(() => s.music = m); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.music == m ? const Color(0xFF20C997) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(_musicOptions[m]!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                _editLabel('🎬 Transition'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: _transitions.keys.map((t) => GestureDetector(
                    onTap: () { setModal(() => s.transition = t); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.transition == t ? const Color(0xFFFF922B) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(_transitions[t]!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                _editLabel('⏱️ Duration: ${s.duration}s'),
                Slider(
                  value: s.duration.toDouble(),
                  min: 1, max: 15,
                  divisions: 14,
                  activeColor: const Color(0xFF6C63FF),
                  label: '${s.duration}s',
                  onChanged: (v) { setModal(() => s.duration = v.toInt()); setState(() {}); },
                ),

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('Done ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editLabel(String text) => Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    filled: true, fillColor: const Color(0xFF1A1A2E),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  );

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
}
