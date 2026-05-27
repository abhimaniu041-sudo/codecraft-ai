import 'package:flutter/material.dart';
import 'dart:math';

enum CharacterState {
  idle, walk, run, attack, jump, fly, talk, angry, happy, sad, victory, death, cast, defend
}

class CharacterData {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Map<CharacterState, StateConfig> states;
  final double scale;

  const CharacterData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.states,
    this.scale = 1.0,
  });
}

class StateConfig {
  final int frames;
  final int fps;
  final bool loop;
  const StateConfig({required this.frames, required this.fps, this.loop = true});
}

class CharacterRegistry {
  static final Map<String, CharacterData> _characters = {
    'hero': CharacterData(
      id: 'hero', name: 'Super Hero', emoji: '🦸', color: const Color(0xFF6C63FF),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 8),
        CharacterState.walk: const StateConfig(frames: 6, fps: 12),
        CharacterState.run: const StateConfig(frames: 6, fps: 16),
        CharacterState.attack: const StateConfig(frames: 5, fps: 14, loop: false),
        CharacterState.jump: const StateConfig(frames: 4, fps: 12, loop: false),
        CharacterState.fly: const StateConfig(frames: 4, fps: 10),
        CharacterState.talk: const StateConfig(frames: 3, fps: 8),
        CharacterState.victory: const StateConfig(frames: 5, fps: 10, loop: false),
        CharacterState.death: const StateConfig(frames: 6, fps: 8, loop: false),
      },
    ),
    'villain': CharacterData(
      id: 'villain', name: 'Dark Villain', emoji: '🦹', color: const Color(0xFFFF1744),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 8),
        CharacterState.walk: const StateConfig(frames: 6, fps: 12),
        CharacterState.attack: const StateConfig(frames: 5, fps: 14, loop: false),
        CharacterState.angry: const StateConfig(frames: 4, fps: 10),
        CharacterState.talk: const StateConfig(frames: 3, fps: 8),
        CharacterState.death: const StateConfig(frames: 6, fps: 8, loop: false),
      },
    ),
    'robot': CharacterData(
      id: 'robot', name: 'Battle Robot', emoji: '🤖', color: const Color(0xFF00E676),
      states: {
        CharacterState.idle: const StateConfig(frames: 3, fps: 6),
        CharacterState.walk: const StateConfig(frames: 6, fps: 10),
        CharacterState.attack: const StateConfig(frames: 4, fps: 12, loop: false),
        CharacterState.fly: const StateConfig(frames: 3, fps: 8),
        CharacterState.death: const StateConfig(frames: 5, fps: 8, loop: false),
      },
    ),
    'wizard': CharacterData(
      id: 'wizard', name: 'Wizard', emoji: '🧙', color: const Color(0xFFCC5DE8),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 7),
        CharacterState.cast: const StateConfig(frames: 6, fps: 12),
        CharacterState.talk: const StateConfig(frames: 3, fps: 8),
        CharacterState.walk: const StateConfig(frames: 5, fps: 10),
        CharacterState.death: const StateConfig(frames: 5, fps: 8, loop: false),
      },
    ),
    'ninja': CharacterData(
      id: 'ninja', name: 'Ninja', emoji: '🥷', color: const Color(0xFF212121),
      states: {
        CharacterState.idle: const StateConfig(frames: 3, fps: 6),
        CharacterState.run: const StateConfig(frames: 8, fps: 20),
        CharacterState.attack: const StateConfig(frames: 6, fps: 18, loop: false),
        CharacterState.jump: const StateConfig(frames: 4, fps: 14, loop: false),
        CharacterState.death: const StateConfig(frames: 5, fps: 10, loop: false),
      },
    ),
    'dragon': CharacterData(
      id: 'dragon', name: 'Dragon', emoji: '🐲', color: const Color(0xFFFF6D00),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 6),
        CharacterState.fly: const StateConfig(frames: 6, fps: 10),
        CharacterState.attack: const StateConfig(frames: 5, fps: 12, loop: false),
        CharacterState.death: const StateConfig(frames: 7, fps: 8, loop: false),
      },
    ),
    'princess': CharacterData(
      id: 'princess', name: 'Princess', emoji: '👸', color: const Color(0xFFFF80AB),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 7),
        CharacterState.walk: const StateConfig(frames: 5, fps: 10),
        CharacterState.talk: const StateConfig(frames: 3, fps: 8),
        CharacterState.happy: const StateConfig(frames: 4, fps: 10),
        CharacterState.sad: const StateConfig(frames: 4, fps: 6),
      },
    ),
    'warrior': CharacterData(
      id: 'warrior', name: 'Warrior', emoji: '⚔️', color: const Color(0xFFBDB76B),
      states: {
        CharacterState.idle: const StateConfig(frames: 3, fps: 6),
        CharacterState.walk: const StateConfig(frames: 6, fps: 12),
        CharacterState.attack: const StateConfig(frames: 7, fps: 16, loop: false),
        CharacterState.defend: const StateConfig(frames: 3, fps: 8),
        CharacterState.death: const StateConfig(frames: 6, fps: 10, loop: false),
      },
    ),
    'alien': CharacterData(
      id: 'alien', name: 'Alien', emoji: '👽', color: const Color(0xFF69F0AE),
      states: {
        CharacterState.idle: const StateConfig(frames: 5, fps: 6),
        CharacterState.walk: const StateConfig(frames: 6, fps: 8),
        CharacterState.attack: const StateConfig(frames: 4, fps: 12, loop: false),
        CharacterState.fly: const StateConfig(frames: 4, fps: 10),
        CharacterState.talk: const StateConfig(frames: 3, fps: 7),
      },
    ),
    'zombie': CharacterData(
      id: 'zombie', name: 'Zombie', emoji: '🧟', color: const Color(0xFF558B2F),
      states: {
        CharacterState.idle: const StateConfig(frames: 4, fps: 5),
        CharacterState.walk: const StateConfig(frames: 6, fps: 6),
        CharacterState.attack: const StateConfig(frames: 4, fps: 8, loop: false),
        CharacterState.death: const StateConfig(frames: 6, fps: 7, loop: false),
      },
    ),
  };

  static CharacterData? get(String id) => _characters[id];
  static List<CharacterData> getAll() => _characters.values.toList();
  static List<String> getAllIds() => _characters.keys.toList();
}

class AnimatedCharacterWidget extends StatefulWidget {
  final String characterId;
  final CharacterState state;
  final double size;
  final bool facingRight;
  final VoidCallback? onAnimationComplete;

  const AnimatedCharacterWidget({
    super.key,
    required this.characterId,
    this.state = CharacterState.idle,
    this.size = 100,
    this.facingRight = true,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedCharacterWidget> createState() => _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentFrame = 0;
  CharacterData? _data;
  StateConfig? _stateConfig;

  @override
  void initState() {
    super.initState();
    _data = CharacterRegistry.get(widget.characterId);
    _initAnimation();
  }

  void _initAnimation() {
    _stateConfig = _data?.states[widget.state];
    if (_stateConfig == null) {
      _stateConfig = _data?.states[CharacterState.idle];
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_stateConfig!.frames * 1000 / _stateConfig!.fps).round()),
    );

    _controller.addListener(() {
      final frame = (_controller.value * _stateConfig!.frames).floor();
      if (frame != _currentFrame && mounted) {
        setState(() => _currentFrame = frame.clamp(0, _stateConfig!.frames - 1));
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_stateConfig!.loop) {
          _controller.reset();
          _controller.forward();
        } else {
          widget.onAnimationComplete?.call();
        }
      }
    });

    if (_stateConfig!.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCharacterWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.characterId != widget.characterId) {
      _controller.dispose();
      _data = CharacterRegistry.get(widget.characterId);
      _currentFrame = 0;
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Transform.scale(
      scaleX: widget.facingRight ? 1 : -1,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.2,
        child: CustomPaint(
          painter: _CharacterPainter(
            character: data,
            state: widget.state,
            frame: _currentFrame,
            totalFrames: _stateConfig?.frames ?? 1,
          ),
        ),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final CharacterData character;
  final CharacterState state;
  final int frame;
  final int totalFrames;

  _CharacterPainter({
    required this.character,
    required this.state,
    required this.frame,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final progress = totalFrames > 1 ? frame / (totalFrames - 1) : 0.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyH = size.height * 0.55;
    final bodyW = size.width * 0.45;

    // State-specific transforms
    double bodyY = cy - bodyH * 0.1;
    double bodyRotation = 0;
    double squishX = 1.0, squishY = 1.0;
    double jumpOffset = 0;
    Color glowColor = character.color.withOpacity(0);
    double glowRadius = 0;

    switch (state) {
      case CharacterState.idle:
        bodyY += sin(progress * pi * 2) * 3;
        break;
      case CharacterState.walk:
        bodyRotation = sin(progress * pi * 2) * 0.08;
        bodyY += sin(progress * pi * 4) * 2;
        break;
      case CharacterState.run:
        bodyRotation = sin(progress * pi * 2) * 0.12;
        bodyY += sin(progress * pi * 4) * 4;
        squishX = 1.0 + sin(progress * pi * 4).abs() * 0.05;
        break;
      case CharacterState.attack:
        bodyRotation = -0.3 + progress * 0.6;
        squishX = 1.0 + progress * 0.15;
        glowColor = character.color.withOpacity(0.4);
        glowRadius = 20 + progress * 30;
        break;
      case CharacterState.jump:
        jumpOffset = -sin(progress * pi) * size.height * 0.3;
        squishX = 1.0 + sin(progress * pi) * 0.1;
        squishY = 1.0 - sin(progress * pi) * 0.1;
        break;
      case CharacterState.fly:
        bodyY += sin(progress * pi * 2) * 6;
        bodyRotation = -0.2;
        glowColor = character.color.withOpacity(0.3);
        glowRadius = 15;
        break;
      case CharacterState.talk:
        bodyY += sin(progress * pi * 3) * 2;
        break;
      case CharacterState.cast:
        bodyRotation = sin(progress * pi) * 0.15;
        glowColor = const Color(0xFFAA00FF).withOpacity(0.5);
        glowRadius = 15 + progress * 40;
        break;
      case CharacterState.angry:
        bodyRotation = sin(progress * pi * 4) * 0.06;
        glowColor = Colors.red.withOpacity(0.3);
        glowRadius = 10;
        break;
      case CharacterState.happy:
        bodyY += -sin(progress * pi * 2).abs() * 8;
        squishX = 1.0 + sin(progress * pi * 2).abs() * 0.08;
        break;
      case CharacterState.sad:
        bodyY += 4;
        bodyRotation = 0.05;
        break;
      case CharacterState.victory:
        jumpOffset = -sin(progress * pi * 2).abs() * 20;
        glowColor = Colors.yellow.withOpacity(0.4);
        glowRadius = 20;
        break;
      case CharacterState.death:
        bodyRotation = progress * pi / 2;
        squishY = 1.0 - progress * 0.5;
        bodyY += progress * size.height * 0.3;
        break;
      case CharacterState.defend:
        squishX = 0.85;
        bodyY -= 5;
        glowColor = Colors.blue.withOpacity(0.3);
        glowRadius = 15;
        break;
    }

    canvas.save();
    canvas.translate(cx, cy + jumpOffset);

    // Glow effect
    if (glowRadius > 0) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
      canvas.drawCircle(Offset(0, 0), glowRadius * 0.8, glowPaint);
    }

    canvas.rotate(bodyRotation);
    canvas.scale(squishX, squishY);

    _drawCharacterBody(canvas, size, bodyW, bodyH, progress);
    canvas.restore();

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height - 8), width: bodyW * 0.8, height: 10),
      shadowPaint,
    );
  }

  void _drawCharacterBody(Canvas canvas, Size size, double bw, double bh, double progress) {
    final bodyPaint = Paint()..color = character.color;
    final darkPaint = Paint()..color = character.color.withOpacity(0.7);
    final lightPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    final darkSkinPaint = Paint()..color = const Color(0xFFE8A87C);

    // Legs
    _drawLeg(canvas, -bw * 0.18, bh * 0.52, bw * 0.14, bh * 0.38, darkPaint, progress, false);
    _drawLeg(canvas, bw * 0.18, bh * 0.52, bw * 0.14, bh * 0.38, darkPaint, progress, true);

    // Body
    final bodyGrad = Paint()
      ..shader = LinearGradient(
        colors: [character.color.withOpacity(0.9), character.color],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset.zero, width: bw, height: bh));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 0), width: bw, height: bh * 0.7),
      const Radius.circular(12),
    ), bodyGrad);

    // Chest emblem
    _drawEmblem(canvas, bodyPaint, lightPaint, bw, bh);

    // Arms
    _drawArm(canvas, -bw * 0.5, -bh * 0.05, bw * 0.13, bh * 0.35, darkPaint, progress, false);
    _drawArm(canvas, bw * 0.5, -bh * 0.05, bw * 0.13, bh * 0.35, darkPaint, progress, true);

    // Neck
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -bh * 0.35), width: bw * 0.18, height: bh * 0.12),
      skinPaint,
    );

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -bh * 0.52), width: bw * 0.55, height: bh * 0.42),
      skinPaint,
    );

    // Hair
    _drawHair(canvas, bw, bh, bodyPaint);

    // Face
    _drawFace(canvas, bw, bh, progress);
  }

  void _drawLeg(Canvas canvas, double x, double y, double w, double h, Paint paint, double progress, bool isRight) {
    final swing = isRight ? sin(progress * pi * 2) : -sin(progress * pi * 2);
    double legSwing = 0;
    if (state == CharacterState.walk || state == CharacterState.run) {
      legSwing = swing * (state == CharacterState.run ? 20 : 12);
    }
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(legSwing * pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, h * 0.3), width: w, height: h), const Radius.circular(6)),
      paint,
    );
    // Boot
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.7, h * 0.55, w * 1.4, h * 0.22), const Radius.circular(5)),
      Paint()..color = Colors.black87,
    );
    canvas.restore();
  }

  void _drawArm(Canvas canvas, double x, double y, double w, double h, Paint paint, double progress, bool isRight) {
    double armSwing = 0;
    if (state == CharacterState.walk || state == CharacterState.run) {
      armSwing = isRight ? -sin(progress * pi * 2) : sin(progress * pi * 2);
      armSwing *= (state == CharacterState.run ? 25 : 15);
    } else if (state == CharacterState.attack) {
      armSwing = isRight ? -60 + progress * 120 : 30;
    } else if (state == CharacterState.cast) {
      armSwing = isRight ? -90 + sin(progress * pi) * 30 : 20;
    }

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(armSwing * pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, h * 0.35), width: w, height: h), const Radius.circular(5)),
      paint,
    );
    // Hand
    canvas.drawCircle(Offset(0, h * 0.72), w * 0.45, Paint()..color = const Color(0xFFFFDBAC));
    canvas.restore();
  }

  void _drawHair(Canvas canvas, double bw, double bh, Paint paint) {
    final hairPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawOval(
      Rect.fromLTWH(-bw * 0.28, -bh * 0.77, bw * 0.56, bh * 0.22),
      hairPaint,
    );
  }

  void _drawFace(Canvas canvas, double bw, double bh, double progress) {
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black87;
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Eyes
    canvas.drawOval(Rect.fromCenter(center: Offset(-bw * 0.12, -bh * 0.52), width: bw * 0.12, height: bh * 0.09), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(bw * 0.12, -bh * 0.52), width: bw * 0.12, height: bh * 0.09), eyePaint);

    // Pupils
    double pupilX = 0, pupilY = 0;
    if (state == CharacterState.angry) { pupilX = 0.01; pupilY = 0.005; }

    canvas.drawCircle(Offset(-bw * 0.12 + pupilX, -bh * 0.52 + pupilY), bw * 0.04, pupilPaint);
    canvas.drawCircle(Offset(bw * 0.12 + pupilX, -bh * 0.52 + pupilY), bw * 0.04, pupilPaint);

    // Eye shine
    canvas.drawCircle(Offset(-bw * 0.10, -bh * 0.535), bw * 0.018, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(bw * 0.14, -bh * 0.535), bw * 0.018, Paint()..color = Colors.white);

    // Eyebrows
    final browPaint = Paint()..color = const Color(0xFF3E2723)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    double browAngle = 0;
    if (state == CharacterState.angry) browAngle = 0.3;
    if (state == CharacterState.sad) browAngle = -0.2;

    canvas.save();
    canvas.translate(-bw * 0.12, -bh * 0.57);
    canvas.rotate(-browAngle);
    canvas.drawLine(Offset(-bw * 0.09, 0), Offset(bw * 0.09, 0), browPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(bw * 0.12, -bh * 0.57);
    canvas.rotate(browAngle);
    canvas.drawLine(Offset(-bw * 0.09, 0), Offset(bw * 0.09, 0), browPaint);
    canvas.restore();

    // Mouth
    final mouthY = -bh * 0.44;
    if (state == CharacterState.talk || state == CharacterState.angry) {
      final openAmount = sin(progress * pi * 4).abs() * bh * 0.06;
      final mouthPath = Path()
        ..moveTo(-bw * 0.1, mouthY)
        ..quadraticBezierTo(0, mouthY + (state == CharacterState.angry ? -openAmount : openAmount), bw * 0.1, mouthY);
      canvas.drawPath(mouthPath, mouthPaint);
      if (state == CharacterState.talk && openAmount > 0.01) {
        canvas.drawOval(Rect.fromCenter(center: Offset(0, mouthY + openAmount * 0.3), width: bw * 0.15, height: openAmount * 0.8), Paint()..color = const Color(0xFFB71C1C));
      }
    } else if (state == CharacterState.happy || state == CharacterState.victory) {
      final smilePath = Path()
        ..moveTo(-bw * 0.1, mouthY)
        ..quadraticBezierTo(0, mouthY + bh * 0.06, bw * 0.1, mouthY);
      canvas.drawPath(smilePath, mouthPaint);
    } else if (state == CharacterState.sad || state == CharacterState.death) {
      final sadPath = Path()
        ..moveTo(-bw * 0.1, mouthY + bh * 0.03)
        ..quadraticBezierTo(0, mouthY - bh * 0.02, bw * 0.1, mouthY + bh * 0.03);
      canvas.drawPath(sadPath, mouthPaint);
    } else {
      canvas.drawLine(Offset(-bw * 0.07, mouthY), Offset(bw * 0.07, mouthY), mouthPaint);
    }
  }

  void _drawEmblem(Canvas canvas, Paint bodyPaint, Paint lightPaint, double bw, double bh) {
    final emblemPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final starPath = Path();
    const n = 5;
    const outerR = 0.09;
    const innerR = 0.045;
    for (int i = 0; i < n * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * pi / n) - pi / 2;
      final px = cos(angle) * bw * r;
      final py = sin(angle) * bh * r;
      if (i == 0) starPath.moveTo(px, py - bh * 0.05);
      else starPath.lineTo(px, py - bh * 0.05);
    }
    starPath.close();
    canvas.drawPath(starPath, emblemPaint);
  }

  @override
  bool shouldRepaint(_CharacterPainter old) =>
      old.frame != frame || old.state != state || old.character.id != character.id;
}

double sin(double x) => _sin(x);
double cos(double x) => _cos(x);

double _sin(double x) {
  x = x % (2 * pi);
  if (x < 0) x += 2 * pi;
  return x < pi
      ? 4 * x * (pi - x) / (pi * pi)
      : -4 * (x - pi) * (2 * pi - x) / (pi * pi);
}

double _cos(double x) => _sin(x + pi / 2);

const pi = 3.14159265358979;
