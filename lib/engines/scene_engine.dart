import 'package:flutter/material.dart';
import 'character_engine.dart';
import 'particle_engine.dart';

enum BackgroundType {
  city, cyberpunk, forest, space, underwater, volcano,
  castle, battlefield, school, laboratory, beach, snow, desert, jungle
}

enum WeatherType { none, rain, snow, storm, fog }
enum TimeOfDay { day, sunset, night }
enum CameraEffect { none, shake, zoomIn, zoomOut, pan }
enum TransitionType { fade, flash, wipe, zoom, none }

class SceneCharacter {
  String characterId;
  CharacterState state;
  double positionX; // 0.0 to 1.0
  double positionY; // 0.0 to 1.0
  bool facingRight;
  String dialogue;
  bool hasDialogue;
  double scale;

  SceneCharacter({
    required this.characterId,
    this.state = CharacterState.idle,
    this.positionX = 0.3,
    this.positionY = 0.6,
    this.facingRight = true,
    this.dialogue = '',
    this.hasDialogue = false,
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
    state: CharacterState.values.firstWhere((s) => s.name == j['state'], orElse: () => CharacterState.idle),
    positionX: (j['positionX'] ?? 0.3).toDouble(),
    positionY: (j['positionY'] ?? 0.6).toDouble(),
    facingRight: j['facingRight'] ?? true,
    dialogue: j['dialogue'] ?? '',
    scale: (j['scale'] ?? 1.0).toDouble(),
  );
}

class SceneEffect {
  final ParticleType particleType;
  final double x, y;
  final bool continuous;

  const SceneEffect({
    required this.particleType,
    required this.x,
    required this.y,
    this.continuous = false,
  });
}

class StoryScene {
  String id;
  BackgroundType background;
  TimeOfDay timeOfDay;
  WeatherType weather;
  List<SceneCharacter> characters;
  List<SceneEffect> effects;
  String narration;
  int durationSeconds;
  TransitionType transition;
  CameraEffect cameraEffect;
  String music;
  String ambience;

  StoryScene({
    required this.id,
    this.background = BackgroundType.city,
    this.timeOfDay = TimeOfDay.day,
    this.weather = WeatherType.none,
    this.characters = const [],
    this.effects = const [],
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
    background: BackgroundType.values.firstWhere((b) => b.name == j['background'], orElse: () => BackgroundType.city),
    timeOfDay: TimeOfDay.values.firstWhere((t) => t.name == j['timeOfDay'], orElse: () => TimeOfDay.day),
    weather: WeatherType.values.firstWhere((w) => w.name == j['weather'], orElse: () => WeatherType.none),
    characters: (j['characters'] as List? ?? []).map((c) => SceneCharacter.fromJson(c)).toList(),
    narration: j['narration'] ?? '',
    durationSeconds: j['durationSeconds'] ?? 4,
    transition: TransitionType.values.firstWhere((t) => t.name == j['transition'], orElse: () => TransitionType.fade),
    cameraEffect: CameraEffect.values.firstWhere((c) => c.name == j['cameraEffect'], orElse: () => CameraEffect.none),
    music: j['music'] ?? 'none',
    ambience: j['ambience'] ?? 'none',
  );
}

class BackgroundPainter extends CustomPainter {
  final BackgroundType type;
  final TimeOfDay timeOfDay;
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
    _drawBackground(canvas, size);
    _drawMiddleground(canvas, size);
    _drawForeground(canvas, size);
    _drawWeather(canvas, size);
    _drawTimeOverlay(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    late List<Color> skyColors;
    switch (timeOfDay) {
      case TimeOfDay.day:
        skyColors = [const Color(0xFF87CEEB), const Color(0xFF1E90FF)];
        break;
      case TimeOfDay.sunset:
        skyColors = [const Color(0xFFFF6B35), const Color(0xFF9B2335)];
        break;
      case TimeOfDay.night:
        skyColors = [const Color(0xFF0A0A2E), const Color(0xFF1A1A4E)];
        break;
    }

    final skyGrad = Paint()
      ..shader = LinearGradient(
        colors: skyColors,
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), skyGrad);

    // Clouds
    if (timeOfDay != TimeOfDay.night) {
      _drawClouds(canvas, size);
    }

    // Stars at night
    if (timeOfDay == TimeOfDay.night) {
      _drawStars(canvas, size);
    }

    // Moon
    if (timeOfDay == TimeOfDay.night) {
      final moonPaint = Paint()..color = const Color(0xFFFFFDE7);
      canvas.drawCircle(Offset(w * 0.8, h * 0.15), 25, moonPaint);
      canvas.drawCircle(Offset(w * 0.83, h * 0.14), 22, Paint()..color = skyColors[0]);
    }

    // Sun
    if (timeOfDay == TimeOfDay.day || timeOfDay == TimeOfDay.sunset) {
      final sunGlow = Paint()
        ..color = (timeOfDay == TimeOfDay.sunset ? const Color(0xFFFFD700) : Colors.yellow).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(w * 0.15, h * 0.12), 35, sunGlow);
      canvas.drawCircle(Offset(w * 0.15, h * 0.12), 22,
          Paint()..color = (timeOfDay == TimeOfDay.sunset ? const Color(0xFFFF6B35) : Colors.yellow));
    }

    _drawSceneSpecificBg(canvas, size);
  }

  void _drawSceneSpecificBg(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final offset = parallaxOffset * 0.3;

    switch (type) {
      case BackgroundType.city:
      case BackgroundType.cyberpunk:
        _drawCityBuildings(canvas, size, offset);
        break;
      case BackgroundType.forest:
      case BackgroundType.jungle:
        _drawForest(canvas, size, offset);
        break;
      case BackgroundType.space:
        _drawSpace(canvas, size);
        break;
      case BackgroundType.underwater:
        _drawUnderwater(canvas, size, offset);
        break;
      case BackgroundType.volcano:
        _drawVolcano(canvas, size, offset);
        break;
      case BackgroundType.castle:
        _drawCastle(canvas, size, offset);
        break;
      case BackgroundType.beach:
        _drawBeach(canvas, size, offset);
        break;
      case BackgroundType.snow:
        _drawSnowScene(canvas, size, offset);
        break;
      case BackgroundType.desert:
        _drawDesert(canvas, size, offset);
        break;
      default:
        _drawDefault(canvas, size, offset);
    }
  }

  void _drawCityBuildings(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;
    final isCyberpunk = type == BackgroundType.cyberpunk;

    // Ground
    final groundPaint = Paint()
      ..color = isCyberpunk ? const Color(0xFF1A0033) : const Color(0xFF4A4A4A);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), groundPaint);

    // Road
    final roadPaint = Paint()..color = isCyberpunk ? const Color(0xFF2D004D) : const Color(0xFF333333);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), roadPaint);

    // Road lines
    final linePaint = Paint()..color = Colors.white.withOpacity(0.6)..strokeWidth = 3;
    for (double x = offset % 60 - 60; x < w + 60; x += 60) {
      canvas.drawLine(Offset(x, h * 0.875), Offset(x + 35, h * 0.875), linePaint);
    }

    // Buildings (far)
    final buildings = [
      [0.0, 0.25, 0.12, 0.4], [0.1, 0.18, 0.08, 0.45], [0.2, 0.28, 0.1, 0.37],
      [0.32, 0.15, 0.09, 0.48], [0.43, 0.22, 0.11, 0.42], [0.56, 0.3, 0.08, 0.35],
      [0.66, 0.17, 0.1, 0.46], [0.78, 0.25, 0.09, 0.38], [0.89, 0.2, 0.12, 0.43],
    ];

    for (final b in buildings) {
      final bx = b[0] * w + offset * 0.3;
      final bw = b[2] * w;
      final bh = b[3] * h;
      final by = h * 0.63 - bh;

      Color buildingColor = isCyberpunk
          ? Color.fromRGBO(20 + (b[0] * 30).toInt(), 0, 50 + (b[0] * 40).toInt(), 1)
          : Color.fromRGBO(60 + (b[0] * 30).toInt(), 60 + (b[0] * 20).toInt(), 70 + (b[0] * 25).toInt(), 1);

      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), Paint()..color = buildingColor);

      // Windows
      _drawBuildingWindows(canvas, bx, by, bw, bh, isCyberpunk);
    }
  }

  void _drawBuildingWindows(Canvas canvas, double bx, double by, double bw, double bh, bool isCyberpunk) {
    final windowPaint = Paint()..color = isCyberpunk
        ? [const Color(0xFFFF00FF), const Color(0xFF00FFFF), const Color(0xFFFFFF00)][bx.toInt() % 3].withOpacity(0.7)
        : Colors.yellow.withOpacity(0.7);
    final windowW = bw * 0.15;
    final windowH = bh * 0.07;
    final cols = 3;
    final rows = (bh / (windowH * 3)).floor();

    for (int r = 0; r < rows && r < 8; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c + bx.toInt()) % 3 != 0) {
          canvas.drawRect(
            Rect.fromLTWH(bx + bw * 0.15 + c * bw * 0.27, by + bh * 0.08 + r * bh * 0.11, windowW, windowH),
            windowPaint,
          );
        }
      }
    }
  }

  void _drawForest(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    // Ground
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
        Paint()..color = const Color(0xFF2D5A27));

    // Grass
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.05),
        Paint()..color = const Color(0xFF4CAF50));

    // Trees back
    for (double x = offset * 0.2 - 80; x < w + 80; x += 70) {
      _drawTree(canvas, x, h * 0.65, 30, 70, const Color(0xFF1B5E20), const Color(0xFF33691E));
    }
    // Trees front
    for (double x = offset * 0.4 - 50; x < w + 50; x += 90) {
      _drawTree(canvas, x + 35, h * 0.67, 40, 90, const Color(0xFF388E3C), const Color(0xFF43A047));
    }
  }

  void _drawTree(Canvas canvas, double x, double y, double w, double h, Color dark, Color light) {
    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(x - w * 0.12, y - h * 0.3, w * 0.24, h * 0.3), trunkPaint);

    final leafPath = Path()
      ..moveTo(x, y - h)
      ..lineTo(x + w * 0.6, y - h * 0.45)
      ..lineTo(x - w * 0.6, y - h * 0.45)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = dark);

    final leafPath2 = Path()
      ..moveTo(x, y - h * 0.7)
      ..lineTo(x + w * 0.7, y - h * 0.25)
      ..lineTo(x - w * 0.7, y - h * 0.25)
      ..close();
    canvas.drawPath(leafPath2, Paint()..color = light);
  }

  void _drawSpace(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF000011));

    // Nebula
    final nebulaPaint = Paint()
      ..color = const Color(0xFF1A0033).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.3), width: w * 0.8, height: h * 0.4), nebulaPaint);

    // Ground / planet surface
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
        Paint()..color = const Color(0xFF1A1A3E));
    canvas.drawOval(Rect.fromLTWH(-w * 0.1, h * 0.65, w * 1.2, h * 0.15),
        Paint()..color = const Color(0xFF2A2A5E));
  }

  void _drawUnderwater(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    final waterGrad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF006994), const Color(0xFF001F3F)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), waterGrad);

    // Sand
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), Paint()..color = const Color(0xFFC2A35A));

    // Corals
    for (double x = offset * 0.3 - 40; x < w + 40; x += 80) {
      _drawCoral(canvas, x, h * 0.76, h * 0.15);
    }

    // Bubbles
    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(w * (i / 8.0) + offset * 0.1 % 30, h * (0.3 + (i * 0.07) % 0.4)),
        4 + (i % 3) * 2.0, bubblePaint,
      );
    }
  }

  void _drawCoral(Canvas canvas, double x, double y, double h) {
    final colors = [const Color(0xFFFF6B6B), const Color(0xFFFF8E53), const Color(0xFFFF006E)];
    final paint = Paint()..color = colors[(x.toInt()) % colors.length];
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, y - h, 8, h), const Radius.circular(4)), paint);
    canvas.drawCircle(Offset(x, y - h), 10, paint);
    canvas.drawCircle(Offset(x - 8, y - h * 0.7), 7, paint);
    canvas.drawCircle(Offset(x + 8, y - h * 0.6), 8, paint);
  }

  void _drawVolcano(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), Paint()..color = const Color(0xFF3D0000));

    final volcanoPaint = Paint()..color = const Color(0xFF4A0000);
    final volcPath = Path()
      ..moveTo(w * 0.35, h * 0.62)
      ..lineTo(w * 0.5, h * 0.25)
      ..lineTo(w * 0.65, h * 0.62)
      ..close();
    canvas.drawPath(volcPath, volcanoPaint);

    // Lava glow
    final lavaPaint = Paint()
      ..color = const Color(0xFFFF4500).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(w * 0.5, h * 0.27), 20, lavaPaint);

    // Lava flow
    canvas.drawRect(Rect.fromLTWH(w * 0.47, h * 0.3, w * 0.06, h * 0.32),
        Paint()..color = const Color(0xFFFF6D00).withOpacity(0.8));
  }

  void _drawCastle(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), Paint()..color = const Color(0xFF3D3D3D));

    final stonePaint = Paint()..color = const Color(0xFF5A5A5A);
    // Main tower
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.25, w * 0.4, h * 0.38), stonePaint);
    // Side towers
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.15, h * 0.28), Paint()..color = const Color(0xFF4A4A4A));
    canvas.drawRect(Rect.fromLTWH(w * 0.7, h * 0.35, w * 0.15, h * 0.28), Paint()..color = const Color(0xFF4A4A4A));

    // Battlements
    for (double bx = w * 0.3; bx < w * 0.7; bx += w * 0.06) {
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.2, w * 0.04, h * 0.06), stonePaint);
    }

    // Gate
    final gatePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.43, h * 0.48, w * 0.14, h * 0.15), const Radius.circular(30)), gatePaint);

    // Flag
    canvas.drawLine(Offset(w * 0.5, h * 0.25), Offset(w * 0.5, h * 0.12), Paint()..color = Colors.grey..strokeWidth = 2);
    final flagPath = Path()..moveTo(w * 0.5, h * 0.12)..lineTo(w * 0.62, h * 0.15)..lineTo(w * 0.5, h * 0.18)..close();
    canvas.drawPath(flagPath, Paint()..color = Colors.red);
  }

  void _drawBeach(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    // Sea
    final seaGrad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF006994), const Color(0xFF0099CC)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.45, w, h * 0.3));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w, h * 0.3), seaGrad);

    // Waves
    final wavePaint = Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final waveY = h * (0.55 + i * 0.04);
      final path = Path();
      path.moveTo(0, waveY);
      for (double wx = 0; wx < w; wx += 30) {
        path.quadraticBezierTo(wx + 15 + offset * 0.2, waveY - 5, wx + 30 + offset * 0.2, waveY);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Sand
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFFF5DEB3));
  }

  void _drawSnowScene(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), Paint()..color = Colors.white);

    // Snow hills
    final hillPaint = Paint()..color = const Color(0xFFE3F2FD);
    canvas.drawOval(Rect.fromLTWH(-w * 0.1, h * 0.5, w * 0.5, h * 0.2), hillPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.6, h * 0.5, w * 0.6, h * 0.2), hillPaint);

    // Pine trees
    for (double x = offset * 0.3; x < w; x += 100) {
      _drawPineTree(canvas, x, h * 0.65);
    }
  }

  void _drawPineTree(Canvas canvas, double x, double y) {
    canvas.drawRect(Rect.fromLTWH(x - 4, y - 20, 8, 20), Paint()..color = const Color(0xFF5D4037));
    final path = Path()..moveTo(x, y - 80)..lineTo(x + 30, y - 20)..lineTo(x - 30, y - 20)..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1B5E20));
    // Snow on tree
    final snowPath = Path()..moveTo(x, y - 80)..lineTo(x + 20, y - 45)..lineTo(x - 20, y - 45)..close();
    canvas.drawPath(snowPath, Paint()..color = Colors.white.withOpacity(0.8));
  }

  void _drawDesert(Canvas canvas, Size size, double offset) {
    final w = size.width;
    final h = size.height;

    final sandGrad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFD2691E), const Color(0xFFC19A6B)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.5), sandGrad);

    // Dunes
    final dunePaint = Paint()..color = const Color(0xFFDEB887);
    for (double x = offset * 0.2 - 100; x < w + 100; x += 200) {
      canvas.drawOval(Rect.fromLTWH(x - 100, h * 0.58, 200, 80), dunePaint);
    }

    // Cactus
    _drawCactus(canvas, w * 0.2 + offset * 0.1, h * 0.65);
    _drawCactus(canvas, w * 0.75 + offset * 0.1, h * 0.68);
  }

  void _drawCactus(Canvas canvas, double x, double y) {
    final cPaint = Paint()..color = const Color(0xFF228B22);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 6, y - 60, 12, 60), const Radius.circular(6)), cPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y - 40, 14, 8), const Radius.circular(4)), cPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y - 50, 8, 20), const Radius.circular(4)), cPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, y - 35, 14, 8), const Radius.circular(4)), cPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 14, y - 48, 8, 22), const Radius.circular(4)), cPaint);
  }

  void _drawDefault(Canvas canvas, Size size, double offset) {
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
        Paint()..color = const Color(0xFF4A7A4A));
  }

  void _drawMiddleground(Canvas canvas, Size size) {}

  void _drawForeground(Canvas canvas, Size size) {
    // Subtle vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  void _drawWeather(Canvas canvas, Size size) {
    if (weather == WeatherType.none) return;
    final w = size.width;
    final h = size.height;

    if (weather == WeatherType.fog) {
      final fogPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fogPaint);
    }
  }

  void _drawTimeOverlay(Canvas canvas, Size size) {
    if (timeOfDay == TimeOfDay.night) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0A0A2E).withOpacity(0.4),
      );
    } else if (timeOfDay == TimeOfDay.sunset) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFFF6B35).withOpacity(0.2),
      );
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final positions = [
      [0.1, 0.08, 70.0, 30.0], [0.45, 0.12, 90.0, 35.0], [0.75, 0.06, 60.0, 25.0],
    ];
    for (final p in positions) {
      final cx = p[0] * size.width + parallaxOffset * 0.1;
      final cy = p[1] * size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: p[2], height: p[3]), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 20, cy + 5), width: p[2] * 0.6, height: p[3] * 0.7), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 25, cy + 5), width: p[2] * 0.7, height: p[3] * 0.7), cloudPaint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white;
    final stars = [
      [0.05, 0.05], [0.15, 0.12], [0.25, 0.04], [0.35, 0.09], [0.45, 0.03],
      [0.55, 0.11], [0.65, 0.06], [0.75, 0.13], [0.85, 0.04], [0.95, 0.08],
      [0.12, 0.2], [0.32, 0.18], [0.52, 0.22], [0.72, 0.17], [0.92, 0.21],
    ];
    for (final s in stars) {
      final glowing = (animProgress * 5 + s[0] * 10) % 1 > 0.5;
      starPaint.color = Colors.white.withOpacity(glowing ? 1.0 : 0.6);
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), glowing ? 2.5 : 1.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter old) =>
      old.animProgress != animProgress || old.parallaxOffset != parallaxOffset ||
      old.type != type || old.timeOfDay != timeOfDay || old.weather != weather;
}
