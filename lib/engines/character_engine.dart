import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CharacterState {
  idle, walk, run, attack, jump, fly, talk,
  angry, happy, sad, victory, death, cast, defend
}

enum CharacterType {
  hero, villain, robot, wizard, ninja,
  princess, warrior, alien, zombie, dragon
}

class CharacterData {
  final CharacterType type;
  final String name;
  final Color primaryColor;
  final Color skinColor;
  final Color hairColor;
  final Color accentColor;

  const CharacterData({
    required this.type,
    required this.name,
    required this.primaryColor,
    required this.skinColor,
    required this.hairColor,
    required this.accentColor,
  });
}

class CharacterRegistry {
  static const Map<String, CharacterData> _all = {
    'hero': CharacterData(
      type: CharacterType.hero, name: 'Hero',
      primaryColor: Color(0xFF1565C0), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E), accentColor: Color(0xFFFFD600),
    ),
    'villain': CharacterData(
      type: CharacterType.villain, name: 'Villain',
      primaryColor: Color(0xFF4A0000), skinColor: Color(0xFFB0BEC5),
      hairColor: Color(0xFF212121), accentColor: Color(0xFFFF1744),
    ),
    'robot': CharacterData(
      type: CharacterType.robot, name: 'Robot',
      primaryColor: Color(0xFF37474F), skinColor: Color(0xFF607D8B),
      hairColor: Color(0xFF263238), accentColor: Color(0xFF00E5FF),
    ),
    'wizard': CharacterData(
      type: CharacterType.wizard, name: 'Wizard',
      primaryColor: Color(0xFF4A148C), skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFE0E0E0), accentColor: Color(0xFFAA00FF),
    ),
    'ninja': CharacterData(
      type: CharacterType.ninja, name: 'Ninja',
      primaryColor: Color(0xFF212121), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF212121), accentColor: Color(0xFFFF1744),
    ),
    'princess': CharacterData(
      type: CharacterType.princess, name: 'Princess',
      primaryColor: Color(0xFFAD1457), skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFFFD600), accentColor: Color(0xFFFF80AB),
    ),
    'warrior': CharacterData(
      type: CharacterType.warrior, name: 'Warrior',
      primaryColor: Color(0xFF4E342E), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E), accentColor: Color(0xFFFFD600),
    ),
    'alien': CharacterData(
      type: CharacterType.alien, name: 'Alien',
      primaryColor: Color(0xFF1B5E20), skinColor: Color(0xFF69F0AE),
      hairColor: Color(0xFF004D40), accentColor: Color(0xFF00E5FF),
    ),
    'zombie': CharacterData(
      type: CharacterType.zombie, name: 'Zombie',
      primaryColor: Color(0xFF33691E), skinColor: Color(0xFF8D9A4A),
      hairColor: Color(0xFF212121), accentColor: Color(0xFF76FF03),
    ),
    'dragon': CharacterData(
      type: CharacterType.dragon, name: 'Dragon',
      primaryColor: Color(0xFF7B1FA2), skinColor: Color(0xFF9C27B0),
      hairColor: Color(0xFF4A148C), accentColor: Color(0xFFFF6D00),
    ),
  };

  static CharacterData? get(String id) => _all[id];
  static List<String> getAllIds() => _all.keys.toList();
  static List<CharacterData> getAll() => _all.values.toList();
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
    this.size = 120,
    this.facingRight = true,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedCharacterWidget> createState() =>
      _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedCharacterWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _ctrl.reset();
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = CharacterRegistry.get(widget.characterId);
    if (data == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scaleX: widget.facingRight ? 1.0 : -1.0,
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.4,
          child: CustomPaint(
            painter: _CharacterPainter(
              data: data,
              state: widget.state,
              tick: _ctrl.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final CharacterData data;
  final CharacterState state;
  final double tick;

  const _CharacterPainter({
    required this.data,
    required this.state,
    required this.tick,
  });

  Paint _fill(Color c) =>
      Paint()..color = c..style = PaintingStyle.fill;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _glow(Color c, double blur) => Paint()
    ..color = c.withOpacity(0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

  void _rrect(Canvas canvas, double x, double y, double w, double h,
      double r, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Animation values
    double bodyY = 0, bodyRot = 0, squishX = 1, squishY = 1, jumpOff = 0;
    double ll = 0, rl = 0, la = 0, ra = 0, mouthOpen = 0;
    bool glowing = false;
    Color glowColor = data.accentColor;

    final sin = math.sin;
    final pi = math.pi;
    final t = tick;

    switch (state) {
      case CharacterState.idle:
        bodyY = sin(t * pi * 2) * h * 0.015;
        break;
      case CharacterState.walk:
        bodyY = sin(t * pi * 4).abs() * h * 0.01;
        bodyRot = sin(t * pi * 2) * 0.04;
        ll = sin(t * pi * 2) * 0.5;
        rl = -sin(t * pi * 2) * 0.5;
        la = -sin(t * pi * 2) * 0.4;
        ra = sin(t * pi * 2) * 0.4;
        break;
      case CharacterState.run:
        bodyY = sin(t * pi * 6).abs() * h * 0.02;
        bodyRot = sin(t * pi * 4) * 0.07;
        ll = sin(t * pi * 4) * 0.8;
        rl = -sin(t * pi * 4) * 0.8;
        la = -sin(t * pi * 4) * 0.7;
        ra = sin(t * pi * 4) * 0.7;
        squishX = 1 + sin(t * pi * 4).abs() * 0.06;
        break;
      case CharacterState.attack:
        bodyRot = sin(t * pi * 3) * 0.18;
        ra = -pi / 2 + sin(t * pi * 3) * 0.8;
        la = 0.3;
        glowing = true;
        break;
      case CharacterState.jump:
        jumpOff = -sin(t * pi) * h * 0.22;
        squishX = 1 + sin(t * pi) * 0.08;
        squishY = 1 - sin(t * pi) * 0.08;
        ll = -0.4;
        rl = -0.4;
        la = -0.5;
        ra = 0.5;
        break;
      case CharacterState.fly:
        bodyY = sin(t * pi * 2) * h * 0.03;
        bodyRot = -0.12;
        la = -pi / 4 + sin(t * pi * 2) * 0.2;
        ra = pi / 4 - sin(t * pi * 2) * 0.2;
        glowing = true;
        break;
      case CharacterState.talk:
        bodyY = sin(t * pi * 3) * h * 0.008;
        mouthOpen = sin(t * pi * 6).abs();
        la = sin(t * pi * 2) * 0.2;
        break;
      case CharacterState.angry:
        bodyRot = sin(t * pi * 8) * 0.04;
        la = -0.3;
        ra = 0.3;
        glowing = true;
        glowColor = Colors.red;
        break;
      case CharacterState.happy:
        bodyY = -sin(t * pi * 2).abs() * h * 0.04;
        squishX = 1 + sin(t * pi * 2).abs() * 0.06;
        la = -0.7;
        ra = 0.7;
        break;
      case CharacterState.sad:
        bodyY = h * 0.02;
        bodyRot = 0.04;
        la = 0.2;
        ra = -0.2;
        break;
      case CharacterState.victory:
        bodyY = -sin(t * pi * 2).abs() * h * 0.06;
        la = -pi / 2;
        ra = pi / 2;
        glowing = true;
        glowColor = Colors.yellow;
        break;
      case CharacterState.death:
        bodyRot = (t * pi / 2).clamp(0, pi / 2);
        bodyY = (t * h * 0.3).clamp(0, h * 0.3);
        squishY = (1 - t * 0.4).clamp(0.4, 1.0);
        break;
      case CharacterState.cast:
        bodyRot = sin(t * pi * 2) * 0.1;
        ra = -pi / 2 + sin(t * pi * 3) * 0.3;
        la = 0.2;
        glowing = true;
        glowColor = const Color(0xFFAA00FF);
        break;
      case CharacterState.defend:
        squishX = 0.88;
        la = -0.1;
        ra = -pi / 2;
        glowing = true;
        glowColor = Colors.blue;
        break;
    }

    canvas.save();
    canvas.translate(cx, h * 0.55 + bodyY + jumpOff);
    canvas.rotate(bodyRot);
    canvas.scale(squishX, squishY);

    if (glowing) {
      canvas.drawCircle(
          Offset.zero, w * 0.35, _glow(glowColor, 16));
    }

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, h * 0.32),
          width: w * 0.5,
          height: h * 0.065),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    switch (data.type) {
      case CharacterType.robot:
        _drawRobot(canvas, w, h, ll, rl, la, ra, mouthOpen, t);
        break;
      case CharacterType.dragon:
        _drawDragon(canvas, w, h, ll, rl, la, ra, mouthOpen, t);
        break;
      default:
        _drawHuman(canvas, w, h, ll, rl, la, ra, mouthOpen, t);
        break;
    }

    canvas.restore();
  }

  void _drawHuman(Canvas canvas, double w, double h,
      double ll, double rl, double la, double ra,
      double mouthOpen, double t) {
    final bw = w * 0.38;
    final bh = h * 0.30;
    final lw = w * 0.11;
    final lh = h * 0.22;
    final aw = w * 0.10;
    final ah = h * 0.23;
    final hr = w * 0.22;

    // Legs
    _drawLimb(canvas, Offset(-bw * 0.28, bh * 0.5), ll, lw, lh,
        data.primaryColor, data.primaryColor.withOpacity(0.7), true);
    _drawLimb(canvas, Offset(bw * 0.28, bh * 0.5), rl, lw, lh,
        data.primaryColor, data.primaryColor.withOpacity(0.7), true);

    // Body
    _drawBody(canvas, bw, bh);
    _drawBodyDetail(canvas, bw, bh);

    // Arms
    _drawLimb(canvas, Offset(-bw * 0.52, -bh * 0.1), la, aw, ah,
        data.primaryColor, data.skinColor, false);
    _drawLimb(canvas, Offset(bw * 0.52, -bh * 0.1), ra, aw, ah,
        data.primaryColor, data.skinColor, false);

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -bh * 0.5),
            width: bw * 0.2,
            height: bh * 0.12),
        const Radius.circular(4),
      ),
      _fill(data.skinColor),
    );

    // Head
    _drawHumanHead(canvas, hr, bh, mouthOpen, t);
  }

  void _drawBody(Canvas canvas, double bw, double bh) {
    final shader = Paint()
      ..shader = LinearGradient(
        colors: [
          data.primaryColor.withOpacity(0.9),
          data.primaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
          Rect.fromCenter(center: Offset.zero, width: bw, height: bh));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        Radius.circular(bw * 0.22),
      ),
      shader,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        Radius.circular(bw * 0.22),
      ),
      _stroke(Colors.black.withOpacity(0.15), 1.5),
    );
  }

  void _drawBodyDetail(Canvas canvas, double bw, double bh) {
    switch (data.type) {
      case CharacterType.hero:
        // Cape
        final capePath = Path()
          ..moveTo(-bw * 0.44, -bh * 0.3)
          ..quadraticBezierTo(-bw * 0.85, bh * 0.4, -bw * 0.3, bh * 0.55)
          ..lineTo(-bw * 0.44, -bh * 0.3);
        canvas.drawPath(capePath, _fill(data.accentColor.withOpacity(0.9)));
        _drawStar(canvas, Offset(0, -bh * 0.05), bw * 0.1, data.accentColor);
        break;

      case CharacterType.villain:
        final cloakPath = Path()
          ..moveTo(-bw * 0.5, -bh * 0.35)
          ..quadraticBezierTo(-bw * 0.95, bh * 0.5, -bw * 0.2, bh * 0.55)
          ..lineTo(-bw * 0.5, -bh * 0.35);
        canvas.drawPath(
            cloakPath, _fill(const Color(0xFF1A0000).withOpacity(0.9)));
        canvas.drawCircle(
            Offset(0, -bh * 0.05), bw * 0.08, _fill(data.accentColor));
        break;

      case CharacterType.wizard:
        _rrect(canvas, -bw * 0.5, -bh * 0.02, bw, bh * 0.12, 4,
            _fill(data.accentColor.withOpacity(0.5)));
        break;

      case CharacterType.warrior:
        _rrect(canvas, -bw * 0.35, -bh * 0.45, bw * 0.7, bh * 0.7, 6,
            _fill(const Color(0xFF9E9E9E)));
        _rrect(canvas, -bw * 0.35, -bh * 0.45, bw * 0.7, bh * 0.7, 6,
            _stroke(Colors.black26, 1.5));
        break;

      case CharacterType.princess:
        _drawStar(canvas, Offset(0, -bh * 0.05), bw * 0.08, data.accentColor);
        break;

      case CharacterType.ninja:
        _rrect(canvas, -bw * 0.5, -bh * 0.02, bw, bh * 0.1, 4,
            _fill(data.accentColor));
        break;

      case CharacterType.alien:
        canvas.drawCircle(
            Offset(0, -bh * 0.05), bw * 0.1, _fill(data.accentColor.withOpacity(0.7)));
        break;

      case CharacterType.zombie:
        // Torn clothes detail
        final tearPath = Path()
          ..moveTo(-bw * 0.3, bh * 0.2)
          ..lineTo(-bw * 0.1, bh * 0.35)
          ..lineTo(bw * 0.1, bh * 0.15)
          ..lineTo(bw * 0.3, bh * 0.3);
        canvas.drawPath(tearPath, _stroke(Colors.black.withOpacity(0.4), 2));
        break;

      default:
        break;
    }
  }

  void _drawLimb(Canvas canvas, Offset origin, double angle, double lw,
      double lh, Color topColor, Color endColor, bool isLeg) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final grad = Paint()
      ..shader = LinearGradient(
        colors: [topColor, endColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-lw / 2, 0, lw, lh));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-lw / 2, 0, lw, lh), Radius.circular(lw / 2)),
      grad,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-lw / 2, 0, lw, lh), Radius.circular(lw / 2)),
      _stroke(Colors.black.withOpacity(0.12), 1.2),
    );

    if (isLeg) {
      // Foot
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-lw * 0.75, lh - lw * 0.35, lw * 1.7, lw * 0.65),
          Radius.circular(lw * 0.38),
        ),
        _fill(Colors.black87),
      );
    } else {
      // Hand
      canvas.drawCircle(
          Offset(0, lh + lw * 0.18), lw * 0.48, _fill(data.skinColor));
    }
    canvas.restore();
  }

  void _drawHumanHead(Canvas canvas, double hr, double bh,
      double mouthOpen, double t) {
    final headY = -bh * 0.52 - hr * 1.1;

    // Head
    canvas.drawCircle(Offset(0, headY), hr, _fill(data.skinColor));
    canvas.drawCircle(
        Offset(0, headY), hr, _stroke(Colors.black.withOpacity(0.12), 1.5));

    // Hair
    _drawHair(canvas, hr, headY);

    // Head accessories
    _drawHeadAccessory(canvas, hr, headY, bh);

    // Eyes
    _drawEyes(canvas, hr, headY, t);

    // Mouth
    _drawMouth(canvas, hr, headY, mouthOpen);
  }

  void _drawHair(Canvas canvas, double r, double hy) {
    final p = _fill(data.hairColor);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, hy), radius: r * 1.02),
      -math.pi, math.pi, true, p,
    );
    // Side hair
    _rrect(canvas, -r * 0.95, hy - r * 0.08, r * 0.2, r * 0.48, 4, p);
    _rrect(canvas, r * 0.75, hy - r * 0.08, r * 0.2, r * 0.48, 4, p);
  }

  void _drawHeadAccessory(
      Canvas canvas, double r, double hy, double bh) {
    switch (data.type) {
      case CharacterType.hero:
        _rrect(canvas, -r, hy - r * 0.18, r * 2, r * 0.34, r * 0.1,
            _fill(data.primaryColor.withOpacity(0.75)));
        break;

      case CharacterType.wizard:
        final hatPath = Path()
          ..moveTo(-r * 0.55, hy - r * 0.82)
          ..lineTo(0, hy - r * 2.15)
          ..lineTo(r * 0.55, hy - r * 0.82)
          ..close();
        canvas.drawPath(hatPath, _fill(data.primaryColor));
        _rrect(canvas, -r * 0.7, hy - r * 0.85, r * 1.4, r * 0.2,
            r * 0.08, _fill(data.primaryColor.withOpacity(0.8)));
        _drawStar(
            canvas, Offset(0, hy - r * 1.55), r * 0.12, data.accentColor);
        break;

      case CharacterType.ninja:
        _rrect(canvas, -r, hy - r * 0.27, r * 2, r * 0.22, 4,
            _fill(data.accentColor));
        _rrect(canvas, -r, hy + r * 0.12, r * 2, r * 0.5, 4,
            _fill(Colors.black87));
        break;

      case CharacterType.warrior:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, hy - r * 0.08), radius: r * 1.08),
          -math.pi * 1.12, math.pi * 1.22, false,
          _fill(const Color(0xFF9E9E9E)),
        );
        break;

      case CharacterType.princess:
        final crownPath = Path()
          ..moveTo(-r * 0.5, hy - r * 1.02)
          ..lineTo(-r * 0.5, hy - r * 1.38)
          ..lineTo(-r * 0.25, hy - r * 1.2)
          ..lineTo(0, hy - r * 1.48)
          ..lineTo(r * 0.25, hy - r * 1.2)
          ..lineTo(r * 0.5, hy - r * 1.38)
          ..lineTo(r * 0.5, hy - r * 1.02)
          ..close();
        canvas.drawPath(crownPath, _fill(const Color(0xFFFFD600)));
        canvas.drawPath(
            crownPath, _stroke(const Color(0xFFFF8F00), 1.5));
        for (final gx in [-r * 0.25, 0.0, r * 0.25]) {
          canvas.drawCircle(Offset(gx, hy - r * 1.1), r * 0.07,
              _fill(data.accentColor));
        }
        break;

      case CharacterType.alien:
        // Large alien cranium
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(0, hy - r * 0.4),
              width: r * 2.0,
              height: r * 1.1),
          _fill(data.skinColor.withOpacity(0.7)),
        );
        break;

      case CharacterType.zombie:
        // Torn hair
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(i * r * 0.22, hy - r),
            Offset(i * r * 0.28 + r * 0.05, hy - r * 1.35),
            _stroke(data.hairColor, 3),
          );
        }
        break;

      default:
        break;
    }
  }

  void _drawEyes(
      Canvas canvas, double r, double hy, double t) {
    final eyePositions = [
      Offset(-r * 0.35, hy - r * 0.05),
      Offset(r * 0.35, hy - r * 0.05),
    ];

    for (final eo in eyePositions) {
      // White
      canvas.drawOval(
        Rect.fromCenter(
            center: eo, width: r * 0.32, height: r * 0.27),
        _fill(Colors.white),
      );
      // Iris
      canvas.drawCircle(
          eo + Offset(0, r * 0.02), r * 0.1, _fill(const Color(0xFF1565C0)));
      // Pupil
      canvas.drawCircle(
          eo + Offset(0, r * 0.02), r * 0.055, _fill(Colors.black));
      // Shine
      canvas.drawCircle(
          eo + Offset(-r * 0.04, -r * 0.04), r * 0.025, _fill(Colors.white));
      // Outline
      canvas.drawOval(
        Rect.fromCenter(
            center: eo, width: r * 0.32, height: r * 0.27),
        _stroke(Colors.black.withOpacity(0.25), 1.0),
      );
    }

    // Eyebrows
    double browTilt = 0;
    if (state == CharacterState.angry) browTilt = 0.35;
    if (state == CharacterState.sad) browTilt = -0.25;

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * r * 0.35, hy - r * 0.22);
      canvas.rotate(side * browTilt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: r * 0.28, height: r * 0.065),
          const Radius.circular(3),
        ),
        _fill(data.hairColor),
      );
      canvas.restore();
    }
  }

  void _drawMouth(Canvas canvas, double r, double hy, double mouthOpen) {
    final my = hy + r * 0.32;
    final linePaint = _stroke(Colors.black87, 2.0);

    if (state == CharacterState.happy || state == CharacterState.victory) {
      final path = Path()
        ..moveTo(-r * 0.28, my - r * 0.04)
        ..quadraticBezierTo(0, my + r * 0.24, r * 0.28, my - r * 0.04);
      canvas.drawPath(path, linePaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, my + r * 0.06), width: r * 0.38, height: r * 0.1),
          const Radius.circular(3),
        ),
        _fill(Colors.white),
      );
    } else if (state == CharacterState.sad) {
      final path = Path()
        ..moveTo(-r * 0.24, my + r * 0.06)
        ..quadraticBezierTo(0, my - r * 0.12, r * 0.24, my + r * 0.06);
      canvas.drawPath(path, linePaint);
    } else if (state == CharacterState.angry) {
      final path = Path()
        ..moveTo(-r * 0.26, my + r * 0.02)
        ..lineTo(r * 0.26, my + r * 0.02);
      canvas.drawPath(path, linePaint);
    } else if (state == CharacterState.talk) {
      final openAmt = mouthOpen * r * 0.15 + r * 0.04;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, my), width: r * 0.3, height: openAmt * 2),
        _fill(const Color(0xFF880E4F)),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, my), width: r * 0.3, height: openAmt * 2),
        _stroke(Colors.black54, 1.5),
      );
      if (openAmt > r * 0.05) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-r * 0.12, my - openAmt, r * 0.24, r * 0.06),
            const Radius.circular(2),
          ),
          _fill(Colors.white.withOpacity(0.9)),
        );
      }
    } else {
      final path = Path()
        ..moveTo(-r * 0.18, my)
        ..lineTo(r * 0.18, my);
      canvas.drawPath(path, _stroke(Colors.black54, 1.8));
    }
  }

  void _drawRobot(Canvas canvas, double w, double h,
      double ll, double rl, double la, double ra,
      double mouthOpen, double t) {
    final bw = w * 0.40;
    final bh = h * 0.30;
    final lw = w * 0.13;
    final lh = h * 0.20;
    final aw = w * 0.11;
    final ah = h * 0.22;
    final hw = w * 0.42;
    final hh = h * 0.25;

    // Legs
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.27, bh * 0.5);
      canvas.rotate(side == -1 ? ll : rl);
      _rrect(canvas, -lw / 2, 0, lw, lh, 4, _fill(data.primaryColor));
      _rrect(canvas, -lw * 0.8, lh - lw * 0.4, lw * 1.7, lw * 0.65, 3,
          _fill(data.primaryColor.withOpacity(0.7)));
      canvas.restore();
    }

    // Body
    _rrect(canvas, -bw / 2, -bh / 2, bw, bh, 6, _fill(data.primaryColor));
    _rrect(canvas, -bw * 0.3, -bh * 0.45, bw * 0.6, bh * 0.5, 4,
        _fill(data.primaryColor.withOpacity(0.5)));
    // Chest LED
    canvas.drawCircle(Offset(0, -bh * 0.08), bw * 0.08, _fill(data.accentColor));
    canvas.drawCircle(Offset(0, -bh * 0.08), bw * 0.08, _glow(data.accentColor, 8));
    // Bolts
    for (final bx in [-bw * 0.38, bw * 0.38]) {
      for (final by in [-bh * 0.3, bh * 0.25]) {
        canvas.drawCircle(
            Offset(bx, by), w * 0.025, _fill(data.accentColor.withOpacity(0.6)));
      }
    }

    // Arms
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.55, -bh * 0.1);
      canvas.rotate(side == -1 ? la : ra);
      _rrect(canvas, -aw / 2, 0, aw, ah, 4,
          _fill(data.primaryColor.withOpacity(0.85)));
      canvas.drawCircle(
          Offset(0, ah + aw * 0.18), aw * 0.5, _fill(data.primaryColor));
      canvas.restore();
    }

    // Head
    _rrect(canvas, -hw / 2, -bh * 0.72 - hh / 2, hw, hh, 8,
        _fill(data.primaryColor));
    // Visor
    _rrect(canvas, -hw * 0.375, -bh * 0.72 - hh * 0.44, hw * 0.75, hh * 0.38,
        4, _fill(data.accentColor.withOpacity(0.2)));
    // LED Eyes
    final ledGlow = math.sin(t * math.pi * 4).abs();
    for (final ex in [-hw * 0.2, hw * 0.2]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.72),
            width: hw * 0.15,
            height: hh * 0.2),
        _fill(data.accentColor.withOpacity(0.6 + ledGlow * 0.4)),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.72),
            width: hw * 0.15,
            height: hh * 0.2),
        _glow(data.accentColor, 6),
      );
    }
    // Speaker
    _rrect(canvas, -hw * 0.22, -bh * 0.72 + hh * 0.18, hw * 0.44, hh * 0.14,
        3, _fill(Colors.black54));
    if (state == CharacterState.talk) {
      for (int i = -2; i <= 2; i++) {
        final lineH = hh * 0.05 + mouthOpen * hh * 0.05;
        _rrect(canvas, -hw * 0.22 + i * hw * 0.09 + hw * 0.09,
            -bh * 0.72 + hh * 0.2, hw * 0.04, lineH, 1,
            _fill(data.accentColor));
      }
    }
    // Antenna
    canvas.drawLine(
      Offset(0, -bh * 0.72 - hh * 0.5),
      Offset(0, -bh * 0.72 - hh * 0.9),
      _stroke(data.primaryColor, 2.0),
    );
    canvas.drawCircle(
        Offset(0, -bh * 0.72 - hh * 0.9), w * 0.034, _fill(data.accentColor));
    canvas.drawCircle(
        Offset(0, -bh * 0.72 - hh * 0.9), w * 0.034,
        _glow(data.accentColor, 5));
  }

  void _drawDragon(Canvas canvas, double w, double h,
      double ll, double rl, double la, double ra,
      double mouthOpen, double t) {
    final bw = w * 0.44;
    final bh = h * 0.30;

    // Tail
    final tailPath = Path()
      ..moveTo(bw * 0.4, 0)
      ..quadraticBezierTo(bw * 1.2, bh * 0.3, bw * 0.9, bh * 0.7)
      ..quadraticBezierTo(bw * 0.6, bh * 0.5, bw * 0.4, bh * 0.5);
    canvas.drawPath(tailPath, _fill(data.primaryColor.withOpacity(0.8)));

    // Wings when flying
    if (state == CharacterState.fly || state == CharacterState.attack) {
      final wFlap = math.sin(t * math.pi * 4) * 0.3;
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * bw * 0.3, -bh * 0.1);
        canvas.rotate(side * (math.pi / 4 + wFlap));
        final wingPath = Path()
          ..moveTo(0, 0)
          ..lineTo(side * bw * 1.1, -bh * 0.6)
          ..lineTo(side * bw * 0.8, 0)
          ..close();
        canvas.drawPath(wingPath, _fill(data.primaryColor.withOpacity(0.65)));
        canvas.restore();
      }
    }

    // Legs
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.28, bh * 0.45);
      canvas.rotate(side == -1 ? ll : rl);
      _rrect(canvas, -w * 0.07, 0, w * 0.14, h * 0.18, 5,
          _fill(data.primaryColor));
      for (int c = -1; c <= 1; c++) {
        canvas.drawLine(
          Offset(c * w * 0.04, h * 0.18),
          Offset(c * w * 0.055, h * 0.22),
          _stroke(Colors.black87, 2.0),
        );
      }
      canvas.restore();
    }

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
      _fill(data.primaryColor),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, bh * 0.08), width: bw * 0.55, height: bh * 0.6),
      _fill(data.skinColor.withOpacity(0.4)),
    );

    // Arms
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.5, -bh * 0.15);
      canvas.rotate(side == -1 ? la : ra);
      _rrect(canvas, -w * 0.07, 0, w * 0.14, h * 0.20, 5,
          _fill(data.primaryColor));
      canvas.restore();
    }

    // Neck
    _rrect(canvas, -bw * 0.11, -bh * 0.56, bw * 0.22, bh * 0.28, 8,
        _fill(data.primaryColor));

    // Head
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, -bh * 0.88), width: bw * 0.55, height: bh * 0.4),
      _fill(data.primaryColor),
    );

    // Snout
    final so = mouthOpen * bh * 0.1 + bh * 0.04;
    _rrect(canvas, bw * 0.04, -bh * 0.88 + so * 0.3, bw * 0.24, so, 4,
        _fill(data.primaryColor));
    _rrect(canvas, bw * 0.05, -bh * 0.88 + so, bw * 0.22, so * 0.7, 4,
        _fill(data.skinColor.withOpacity(0.5)));

    // Fire breath
    if (state == CharacterState.attack && mouthOpen > 0.3) {
      final firePath = Path()
        ..moveTo(bw * 0.3, -bh * 0.85)
        ..quadraticBezierTo(bw * 0.8, -bh * 0.7, bw * 1.1, -bh * 0.88)
        ..quadraticBezierTo(bw * 0.8, -bh * 1.0, bw * 0.3, -bh * 0.88);
      canvas.drawPath(firePath,
          _fill(const Color(0xFFFF6D00).withOpacity(0.85)));
      canvas.drawPath(firePath, _glow(const Color(0xFFFF6D00), 12));
    }

    // Eyes
    for (final ex in [-bw * 0.08, bw * 0.22]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.95), width: bw * 0.12, height: bh * 0.1),
        _fill(Colors.yellow),
      );
      canvas.drawCircle(
          Offset(ex, -bh * 0.95), bw * 0.035, _fill(Colors.black));
    }

    // Horns
    for (final hx in [-bw * 0.16, bw * 0.16]) {
      final hornPath = Path()
        ..moveTo(hx, -bh * 1.06)
        ..lineTo(hx - bw * 0.04, -bh * 1.26)
        ..lineTo(hx + bw * 0.04, -bh * 1.06)
        ..close();
      canvas.drawPath(hornPath, _fill(const Color(0xFF4A148C)));
    }

    // Scales on back
    for (int i = 0; i < 3; i++) {
      final sx = -bw * 0.15 + i * bw * 0.15;
      final sy = -bh * 0.2 - i * bh * 0.08;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(sx, sy), width: bw * 0.1, height: bh * 0.08),
        _fill(data.primaryColor.withOpacity(0.7)),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.42;
      final px = center.dx + math.cos(angle) * radius;
      final py = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, _fill(color));
  }

  @override
  bool shouldRepaint(_CharacterPainter old) =>
      old.tick != tick ||
      old.state != state ||
      old.data.type != data.type;
}
