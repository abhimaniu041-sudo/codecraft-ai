import 'package:flutter/material.dart';
import 'character_engine.dart';
import 'particle_engine.dart';

enum BackgroundType {
  city, cyberpunk, forest, space, underwater, volcano,
  castle, battlefield, school, laboratory, beach, snow, desert, jungle, fantasy
}

enum WeatherType { none, rain, snow, storm, fog }

// RENAMED to avoid conflict with Flutter's TimeOfDay
enum SceneTimeOfDay { day, sunset, night }

enum CameraEffect { none, shake, zoomIn, zoomOut, pan }
enum TransitionType { fade, flash, wipe, zoom, none }

class SceneCharacter {
  String characterId;
  CharacterState state;
  double positionX;
  double positionY;
  bool facingRight;
  String dialogue;
  double scale;

  SceneCharacter({
    required this.characterId,
    this.state = CharacterState.idle,
    this.positionX = 0.3,
    this.positionY = 0.62,
    this.facingRight = true,
    this.dialogue = '',
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'state': state.name,
    'positionX': positionX,
    'positionY': positionY,
    'facingRight': facingRight,
    'dialogue': dialogue,
    'scale': scale,
  };

  factory SceneCharacter.fromJson(Map<String, dynamic> j) => SceneCharacter(
    characterId: j['characterId'] ?? 'hero',
    state: CharacterState.values.firstWhere(
      (s) => s.name == j['state'],
      orElse: () => CharacterState.idle,
    ),
    positionX: (j['positionX'] ?? 0.3).toDouble(),
    positionY: (j['positionY'] ?? 0.62).toDouble(),
    facingRight: j['facingRight'] ?? true,
    dialogue: j['dialogue'] ?? '',
    scale: (j['scale'] ?? 1.0).toDouble(),
  );
}

class StoryScene {
  String id;
  BackgroundType background;
  SceneTimeOfDay timeOfDay;
  WeatherType weather;
  List<SceneCharacter> characters;
  String narration;
  int durationSeconds;
  TransitionType transition;
  CameraEffect cameraEffect;
  String music;
  String ambience;

  StoryScene({
    required this.id,
    this.background = BackgroundType.city,
    this.timeOfDay = SceneTimeOfDay.day,
    this.weather = WeatherType.none,
    this.characters = const [],
    this.narration = '',
    this.durationSeconds = 4,
    this.transition = TransitionType.fade,
    this.cameraEffect = CameraEffect.none,
    this.music = 'epic',
    this.ambience = 'city',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'background': background.name,
    'timeOfDay': timeOfDay.name,
    'weather': weather.name,
    'characters': characters.map((c) => c.toJson()).toList(),
    'narration': narration,
    'durationSeconds': durationSeconds,
    'transition': transition.name,
    'cameraEffect': cameraEffect.name,
    'music': music,
    'ambience': ambience,
  };

  factory StoryScene.fromJson(Map<String, dynamic> j) => StoryScene(
    id: j['id'] ?? DateTime.now().toString(),
    background: BackgroundType.values.firstWhere(
      (b) => b.name == j['background'],
      orElse: () => BackgroundType.city,
    ),
    timeOfDay: SceneTimeOfDay.values.firstWhere(
      (t) => t.name == j['timeOfDay'],
      orElse: () => SceneTimeOfDay.day,
    ),
    weather: WeatherType.values.firstWhere(
      (w) => w.name == j['weather'],
      orElse: () => WeatherType.none,
    ),
    characters: (j['characters'] as List? ?? [])
        .map((c) => SceneCharacter.fromJson(c))
        .toList(),
    narration: j['narration'] ?? '',
    durationSeconds: j['durationSeconds'] ?? 4,
    transition: TransitionType.values.firstWhere(
      (t) => t.name == j['transition'],
      orElse: () => TransitionType.fade,
    ),
    cameraEffect: CameraEffect.values.firstWhere(
      (c) => c.name == j['cameraEffect'],
      orElse: () => CameraEffect.none,
    ),
    music: j['music'] ?? 'none',
    ambience: j['ambience'] ?? 'none',
  );
}

class BackgroundPainter extends CustomPainter {
  final BackgroundType type;
  final SceneTimeOfDay timeOfDay;
  final WeatherType weather;
  final double animProgress;
  final double parallaxOffset;

  BackgroundPainter({
    required this.type,
    required this.timeOfDay,
    required this.weather,
    required this.animProgress,
    this.parallaxOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawSceneBg(canvas, size);
    _drawWeather(canvas, size);
    _drawTimeOverlay(canvas, size);
    _drawVignette(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    late List<Color> colors;
    switch (timeOfDay) {
      case SceneTimeOfDay.day:
        colors = [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
        break;
      case SceneTimeOfDay.sunset:
        colors = [const Color(0xFFFF7043), const Color(0xFF880E4F)];
        break;
      case SceneTimeOfDay.night:
        colors = [const Color(0xFF0A0A2E), const Color(0xFF1A1A4E)];
        break;
    }
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topCenter,
        end: Alignment.center,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.65), paint);

    if (timeOfDay == SceneTimeOfDay.night) {
      _drawStars(canvas, size);
      _drawMoon(canvas, size);
    } else {
      _drawSun(canvas, size);
      _drawClouds(canvas, size);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final positions = [
      [0.05, 0.04], [0.15, 0.1], [0.25, 0.03], [0.38, 0.08],
      [0.5, 0.02], [0.62, 0.09], [0.74, 0.05], [0.85, 0.11],
      [0.93, 0.04], [0.1, 0.18], [0.3, 0.16], [0.55, 0.19],
      [0.78, 0.15], [0.45, 0.06], [0.68, 0.14],
    ];
    for (final p in positions) {
      final twinkle = (animProgress * 5 + p[0] * 10) % 1 > 0.5;
      paint.color = Colors.white.withOpacity(twinkle ? 1.0 : 0.5);
      canvas.drawCircle(
        Offset(p[0] * size.width, p[1] * size.height),
        twinkle ? 2.5 : 1.5,
        paint,
      );
    }
  }

  void _drawMoon(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.14), 24, moonPaint);
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.13),
      21,
      Paint()..color = const Color(0xFF0A0A2E),
    );
  }

  void _drawSun(Canvas canvas, Size size) {
    final color = timeOfDay == SceneTimeOfDay.sunset
        ? const Color(0xFFFF7043)
        : const Color(0xFFFFEB3B);
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.13), 35, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.13), 22, Paint()..color = color);
  }

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final clouds = [
      [0.1, 0.08, 80.0, 32.0],
      [0.45, 0.11, 100.0, 38.0],
      [0.75, 0.07, 70.0, 28.0],
    ];
    for (final c in clouds) {
      final cx = c[0] * size.width + parallaxOffset * 0.08;
      final cy = c[1] * size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: c[2], height: c[3]), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 22, cy + 6), width: c[2] * 0.6, height: c[3] * 0.65), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 26, cy + 6), width: c[2] * 0.7, height: c[3] * 0.7), paint);
    }
  }

  void _drawSceneBg(Canvas canvas, Size size) {
    switch (type) {
      case BackgroundType.city:
      case BackgroundType.cyberpunk:
        _drawCity(canvas, size, type == BackgroundType.cyberpunk);
        break;
      case BackgroundType.forest:
      case BackgroundType.jungle:
        _drawForest(canvas, size);
        break;
      case BackgroundType.space:
        _drawSpace(canvas, size);
        break;
      case BackgroundType.underwater:
        _drawUnderwater(canvas, size);
        break;
      case BackgroundType.volcano:
        _drawVolcano(canvas, size);
        break;
      case BackgroundType.castle:
        _drawCastle(canvas, size);
        break;
      case BackgroundType.beach:
        _drawBeach(canvas, size);
        break;
      case BackgroundType.snow:
        _drawSnow(canvas, size);
        break;
      case BackgroundType.desert:
        _drawDesert(canvas, size);
        break;
      case BackgroundType.battlefield:
        _drawBattlefield(canvas, size);
        break;
      case BackgroundType.fantasy:
        _drawFantasy(canvas, size);
        break;
      default:
        _drawCity(canvas, size, false);
    }
  }

  void _drawCity(Canvas canvas, Size size, bool cyber) {
    final w = size.width;
    final h = size.height;

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.63, w, h * 0.37),
      Paint()..color = cyber ? const Color(0xFF0D0020) : const Color(0xFF3D3D3D),
    );

    // Road
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.77, w, h * 0.23),
      Paint()..color = cyber ? const Color(0xFF1A0033) : const Color(0xFF2A2A2A),
    );

    // Road lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.5;
    for (double x = parallaxOffset % 60 - 60; x < w + 60; x += 60) {
      canvas.drawLine(Offset(x, h * 0.885), Offset(x + 38, h * 0.885), linePaint);
    }

    // Buildings
    final buildings = [
      [0.0, 0.38, 0.11], [0.12, 0.26, 0.09], [0.23, 0.42, 0.1],
      [0.35, 0.2, 0.1], [0.47, 0.35, 0.11], [0.6, 0.28, 0.09],
      [0.71, 0.44, 0.1], [0.83, 0.22, 0.11], [0.91, 0.33, 0.1],
    ];

    for (final b in buildings) {
      final bx = b[0] * w + parallaxOffset * 0.25;
      final bw = b[2] * w;
      final bh = b[1] * h;
      final by = h * 0.63 - bh;

      final color = cyber
          ? Color.fromARGB(255, 15 + (b[0] * 20).toInt(), 0, 40 + (b[0] * 35).toInt())
          : Color.fromARGB(255, 55 + (b[0] * 25).toInt(), 55 + (b[0] * 20).toInt(), 65 + (b[0] * 20).toInt());

      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), Paint()..color = color);

      // Windows
      final windowColor = cyber
          ? [const Color(0xFFFF00FF), const Color(0xFF00FFFF), const Color(0xFFFFFF00)][(bx ~/ 30) % 3].withOpacity(0.75)
          : Colors.yellow.withOpacity(0.7);
      final ww = bw * 0.15;
      final wh = bh * 0.07;
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 3; c++) {
          if ((r + c + bx.toInt()) % 3 != 0) {
            canvas.drawRect(
              Rect.fromLTWH(bx + bw * 0.12 + c * bw * 0.28, by + bh * 0.07 + r * bh * 0.12, ww, wh),
              Paint()..color = windowColor,
            );
          }
        }
      }

      // Cyber neon glow
      if (cyber) {
        canvas.drawLine(
          Offset(bx, by), Offset(bx + bw, by),
          Paint()..color = const Color(0xFF00FFFF).withOpacity(0.5)..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawForest(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.63, w, h * 0.37),
      Paint()..color = const Color(0xFF2E5D27),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.63, w, h * 0.04),
      Paint()..color = const Color(0xFF4CAF50),
    );
    // Back trees
    for (double x = parallaxOffset * 0.2 - 80; x < w + 80; x += 65) {
      _drawTree(canvas, x, h * 0.65, 28, 75, const Color(0xFF1B5E20), const Color(0xFF2E7D32));
    }
    // Front trees
    for (double x = parallaxOffset * 0.4 - 50; x < w + 50; x += 85) {
      _drawTree(canvas, x + 32, h * 0.67, 38, 95, const Color(0xFF388E3C), const Color(0xFF43A047));
    }
  }

  void _drawTree(Canvas canvas, double x, double y, double w, double h, Color dark, Color light) {
    canvas.drawRect(
      Rect.fromLTWH(x - w * 0.11, y - h * 0.28, w * 0.22, h * 0.28),
      Paint()..color = const Color(0xFF5D4037),
    );
    final p1 = Path()
      ..moveTo(x, y - h)
      ..lineTo(x + w * 0.6, y - h * 0.44)
      ..lineTo(x - w * 0.6, y - h * 0.44)
      ..close();
    canvas.drawPath(p1, Paint()..color = dark);
    final p2 = Path()
      ..moveTo(x, y - h * 0.65)
      ..lineTo(x + w * 0.72, y - h * 0.22)
      ..lineTo(x - w * 0.72, y - h * 0.22)
      ..close();
    canvas.drawPath(p2, Paint()..color = light);
  }

  void _drawSpace(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF000011));

    // Nebula
    final nebula = Paint()
      ..color = const Color(0xFF4A00E0).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.3), width: w * 0.8, height: h * 0.4), nebula);

    // Planet surface
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFF1A1A3E));
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.1, h * 0.64, w * 1.2, h * 0.14),
      Paint()..color = const Color(0xFF2A2A5E),
    );
  }

  void _drawUnderwater(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF006994), const Color(0xFF001F3F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), grad);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), Paint()..color = const Color(0xFFC2A35A));

    // Corals
    for (double x = parallaxOffset * 0.3 - 40; x < w + 40; x += 80) {
      final cp = Paint()..color = [
        const Color(0xFFFF6B6B), const Color(0xFFFF8E53), const Color(0xFFFF006E)
      ][(x.toInt() ~/ 40) % 3];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, h * 0.76 - h * 0.15, 8, h * 0.15), const Radius.circular(4)), cp);
      canvas.drawCircle(Offset(x, h * 0.76 - h * 0.15), 10, cp);
      canvas.drawCircle(Offset(x - 9, h * 0.76 - h * 0.1), 7, cp);
      canvas.drawCircle(Offset(x + 9, h * 0.76 - h * 0.09), 8, cp);
    }

    // Bubbles
    final bp = Paint()..color = Colors.white.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(w * (i / 8.0) + parallaxOffset * 0.1 % 30, h * (0.3 + (i * 0.07) % 0.4)),
        3.5 + (i % 3) * 2.0, bp,
      );
    }
  }

  void _drawVolcano(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.37), Paint()..color = const Color(0xFF3D0000));
    final vp = Paint()..color = const Color(0xFF4A0000);
    final vPath = Path()
      ..moveTo(w * 0.35, h * 0.63)
      ..lineTo(w * 0.5, h * 0.22)
      ..lineTo(w * 0.65, h * 0.63)
      ..close();
    canvas.drawPath(vPath, vp);
    final lavaGlow = Paint()
      ..color = const Color(0xFFFF4500).withOpacity(0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(w * 0.5, h * 0.25), 22, lavaGlow);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.46, h * 0.28, w * 0.08, h * 0.35),
      Paint()..color = const Color(0xFFFF6D00).withOpacity(0.85),
    );
  }

  void _drawCastle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.37), Paint()..color = const Color(0xFF3A3A3A));
    final sp = Paint()..color = const Color(0xFF585858);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.2, w * 0.44, h * 0.43), sp);
    canvas.drawRect(Rect.fromLTWH(w * 0.13, h * 0.33, w * 0.16, h * 0.3), Paint()..color = const Color(0xFF4A4A4A));
    canvas.drawRect(Rect.fromLTWH(w * 0.71, h * 0.33, w * 0.16, h * 0.3), Paint()..color = const Color(0xFF4A4A4A));
    for (double bx = w * 0.28; bx < w * 0.72; bx += w * 0.06) {
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.15, w * 0.04, h * 0.06), sp);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.47, w * 0.16, h * 0.17), const Radius.circular(30)),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.08), Paint()..color = Colors.grey..strokeWidth = 2);
    final fp = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.63, h * 0.12)
      ..lineTo(w * 0.5, h * 0.17)
      ..close();
    canvas.drawPath(fp, Paint()..color = Colors.red);
  }

  void _drawBeach(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seaGrad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF0099CC), const Color(0xFF006994)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.45, w, h * 0.3));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w, h * 0.3), seaGrad);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.72, w, h * 0.28), Paint()..color = const Color(0xFFF5DEB3));
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final wy = h * (0.57 + i * 0.04);
      path.moveTo(0, wy);
      for (double x = 0; x < w; x += 35) {
        path.quadraticBezierTo(x + 17 + parallaxOffset * 0.2, wy - 5, x + 35 + parallaxOffset * 0.2, wy);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.37), Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromLTWH(-w * 0.1, h * 0.5, w * 0.5, h * 0.2), Paint()..color = const Color(0xFFE3F2FD));
    canvas.drawOval(Rect.fromLTWH(w * 0.62, h * 0.5, w * 0.58, h * 0.2), Paint()..color = const Color(0xFFE3F2FD));
    for (double x = parallaxOffset * 0.3 - 50; x < w + 50; x += 95) {
      final tp = Paint()..color = const Color(0xFF5D4037);
      canvas.drawRect(Rect.fromLTWH(x - 4, h * 0.65 - 20, 8, 20), tp);
      final p1 = Path()..moveTo(x, h * 0.65 - 85)..lineTo(x + 32, h * 0.65 - 20)..lineTo(x - 32, h * 0.65 - 20)..close();
      canvas.drawPath(p1, Paint()..color = const Color(0xFF1B5E20));
      final p2 = Path()..moveTo(x, h * 0.65 - 85)..lineTo(x + 20, h * 0.65 - 50)..lineTo(x - 20, h * 0.65 - 50)..close();
      canvas.drawPath(p2, Paint()..color = Colors.white.withOpacity(0.85));
    }
  }

  void _drawDesert(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFD2691E), const Color(0xFFC19A6B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.5), grad);
    for (double x = parallaxOffset * 0.2 - 100; x < w + 100; x += 200) {
      canvas.drawOval(Rect.fromLTWH(x - 100, h * 0.6, 200, 70), Paint()..color = const Color(0xFFDEB887));
    }
    for (final cx in [w * 0.2 + parallaxOffset * 0.1, w * 0.75 + parallaxOffset * 0.1]) {
      final cp = Paint()..color = const Color(0xFF228B22);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 6, h * 0.65 - 62, 12, 62), const Radius.circular(6)), cp);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 22, h * 0.65 - 42, 15, 8), const Radius.circular(4)), cp);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 22, h * 0.65 - 52, 8, 22), const Radius.circular(4)), cp);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8, h * 0.65 - 36, 15, 8), const Radius.circular(4)), cp);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 14, h * 0.65 - 49, 8, 22), const Radius.circular(4)), cp);
      canvas.drawCircle(Offset(cx, h * 0.65 - 62), 10, cp);
    }
  }

  void _drawBattlefield(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.37), Paint()..color = const Color(0xFF2D2D1A));
    // Craters
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * (0.15 + i * 0.22), h * 0.7),
        18.0,
        Paint()..color = const Color(0xFF1A1A0D),
      );
    }
    // Barricades
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.2 + i * 0.28), h * 0.65, w * 0.08, h * 0.05),
        Paint()..color = const Color(0xFF4A3728),
      );
    }
    // Smoke in bg
    final sp = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(w * 0.3, h * 0.4), 50, sp);
    canvas.drawCircle(Offset(w * 0.7, h * 0.35), 40, sp);
  }

  void _drawFantasy(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF4A0080), const Color(0xFF1A0050)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), grad);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.37), Paint()..color = const Color(0xFF0D0025));
    // Magic particles
    final mp = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final magicColors = [const Color(0xFFAA00FF), const Color(0xFF00E5FF), const Color(0xFFFFD700)];
    for (int i = 0; i < 12; i++) {
      mp.color = magicColors[i % 3].withOpacity(0.4);
      canvas.drawCircle(
        Offset(w * ((i * 0.087 + parallaxOffset * 0.01) % 1), h * (0.1 + (i * 0.065) % 0.5)),
        4.0 + (i % 3) * 2.5,
        mp,
      );
    }
    // Fantasy ground glow
    final glow = Paint()
      ..color = const Color(0xFF7B00FF).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.1), glow);
  }

  void _drawWeather(Canvas canvas, Size size) {
    if (weather == WeatherType.fog) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
  }

  void _drawTimeOverlay(Canvas canvas, Size size) {
    Color? overlayColor;
    if (timeOfDay == SceneTimeOfDay.night) {
      overlayColor = const Color(0xFF0A0A2E).withOpacity(0.38);
    } else if (timeOfDay == SceneTimeOfDay.sunset) {
      overlayColor = const Color(0xFFFF6B35).withOpacity(0.18);
    }
    if (overlayColor != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = overlayColor);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.32)],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  @override
  bool shouldRepaint(BackgroundPainter old) =>
      old.animProgress != animProgress ||
      old.parallaxOffset != parallaxOffset ||
      old.type != type ||
      old.timeOfDay != timeOfDay ||
      old.weather != weather;
}
