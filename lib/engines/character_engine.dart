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
  static final Map<String, CharacterData> _all = {
    'hero': const CharacterData(
      type: CharacterType.hero,
      name: 'Hero',
      primaryColor: Color(0xFF1565C0),
      skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E),
      accentColor: Color(0xFFFFD600),
    ),
    'villain': const CharacterData(
      type: CharacterType.villain,
      name: 'Villain',
      primaryColor: Color(0xFF4A0000),
      skinColor: Color(0xFFB0BEC5),
      hairColor: Color(0xFF212121),
      accentColor: Color(0xFFFF1744),
    ),
    'robot': const CharacterData(
      type: CharacterType.robot,
      name: 'Robot',
      primaryColor: Color(0xFF37474F),
      skinColor: Color(0xFF607D8B),
      hairColor: Color(0xFF263238),
      accentColor: Color(0xFF00E5FF),
    ),
    'wizard': const CharacterData(
      type: CharacterType.wizard,
      name: 'Wizard',
      primaryColor: Color(0xFF4A148C),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFE0E0E0),
      accentColor: Color(0xFFAA00FF),
    ),
    'ninja': const CharacterData(
      type: CharacterType.ninja,
      name: 'Ninja',
      primaryColor: Color(0xFF212121),
      skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF212121),
      accentColor: Color(0xFFFF1744),
    ),
    'princess': const CharacterData(
      type: CharacterType.princess,
      name: 'Princess',
      primaryColor: Color(0xFFAD1457),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFFFD600),
      accentColor: Color(0xFFFF80AB),
    ),
    'warrior': const CharacterData(
      type: CharacterType.warrior,
      name: 'Warrior',
      primaryColor: Color(0xFF4E342E),
      skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E),
      accentColor: Color(0xFFFFD600),
    ),
    'alien': const CharacterData(
      type: CharacterType.alien,
      name: 'Alien',
      primaryColor: Color(0xFF1B5E20),
      skinColor: Color(0xFF69F0AE),
      hairColor: Color(0xFF004D40),
      accentColor: Color(0xFF00E5FF),
    ),
    'zombie': const CharacterData(
      type: CharacterType.zombie,
      name: 'Zombie',
      primaryColor: Color(0xFF33691E),
      skinColor: Color(0xFF8D9A4A),
      hairColor: Color(0xFF212121),
      accentColor: Color(0xFF76FF03),
    ),
    'dragon': const CharacterData(
      type: CharacterType.dragon,
      name: 'Dragon',
      primaryColor: Color(0xFF7B1FA2),
      skinColor: Color(0xFF9C27B0),
      hairColor: Color(0xFF4A148C),
      accentColor: Color(0xFFFF6D00),
    ),
  };

  static CharacterData? get(String id) => _all[id];
  static List<String> getAllIds() => _all.keys.toList();
  static List<CharacterData> getAll() => _all.values.toList();
}

// ─── Animated Character Widget ────────────────────────────────
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
        scaleX: widget.facingRight ? 1 : -1,
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.4,
          child: CustomPaint(
            painter: _CartoonCharacterPainter(
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

// ─── Cartoon Character Painter ───────────────────────────────
class _CartoonCharacterPainter extends CustomPainter {
  final CharacterData data;
  final CharacterState state;
  final double tick;

  const _CartoonCharacterPainter({
    required this.data,
    required this.state,
    required this.tick,
  });

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Paint _glow(Color c, double blur) => Paint()
    ..color = c.withOpacity(0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

  @override
  void paint(Canvas canvas, Size size) {
    final t = tick;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    double bodyY = 0, bodyRot = 0, squishX = 1, squishY = 1, jumpOff = 0;
    double leftLegAngle = 0, rightLegAngle = 0;
    double leftArmAngle = 0, rightArmAngle = 0;
    double mouthOpen = 0;
    bool glowing = false;
    Color glowColor = data.accentColor;

    final sin = math.sin;
    final pi = math.pi;

    switch (state) {
      case CharacterState.idle:
        bodyY = sin(t * pi * 2) * h * 0.015;
        break;
      case CharacterState.walk:
        bodyY = sin(t * pi * 4).abs() * h * 0.01;
        bodyRot = sin(t * pi * 2) * 0.04;
        leftLegAngle = sin(t * pi * 2) * 0.5;
        rightLegAngle = -sin(t * pi * 2) * 0.5;
        leftArmAngle = -sin(t * pi * 2) * 0.4;
        rightArmAngle = sin(t * pi * 2) * 0.4;
        break;
      case CharacterState.run:
        bodyY = sin(t * pi * 6).abs() * h * 0.02;
        bodyRot = sin(t * pi * 4) * 0.07;
        leftLegAngle = sin(t * pi * 4) * 0.8;
        rightLegAngle = -sin(t * pi * 4) * 0.8;
        leftArmAngle = -sin(t * pi * 4) * 0.7;
        rightArmAngle = sin(t * pi * 4) * 0.7;
        squishX = 1 + sin(t * pi * 4).abs() * 0.06;
        break;
      case CharacterState.attack:
        bodyRot = sin(t * pi * 3) * 0.18;
        rightArmAngle = -pi / 2 + sin(t * pi * 3) * 0.8;
        leftArmAngle = 0.3;
        glowing = true;
        glowColor = data.accentColor;
        break;
      case CharacterState.jump:
        jumpOff = -sin(t * pi) * h * 0.22;
        squishX = 1 + sin(t * pi) * 0.08;
        squishY = 1 - sin(t * pi) * 0.08;
        leftLegAngle = -0.4;
        rightLegAngle = -0.4;
        leftArmAngle = -0.5;
        rightArmAngle = 0.5;
        break;
      case CharacterState.fly:
        bodyY = sin(t * pi * 2) * h * 0.03;
        bodyRot = -0.12;
        leftArmAngle = -pi / 4 + sin(t * pi * 2) * 0.2;
        rightArmAngle = pi / 4 - sin(t * pi * 2) * 0.2;
        glowing = true;
        break;
      case CharacterState.talk:
        bodyY = sin(t * pi * 3) * h * 0.008;
        mouthOpen = sin(t * pi * 6).abs();
        leftArmAngle = sin(t * pi * 2) * 0.2;
        break;
      case CharacterState.angry:
        bodyRot = sin(t * pi * 8) * 0.04;
        leftArmAngle = -0.3;
        rightArmAngle = 0.3;
        glowing = true;
        glowColor = Colors.red;
        break;
      case CharacterState.happy:
        bodyY = -sin(t * pi * 2).abs() * h * 0.04;
        squishX = 1 + sin(t * pi * 2).abs() * 0.06;
        leftArmAngle = -0.7;
        rightArmAngle = 0.7;
        break;
      case CharacterState.sad:
        bodyY = h * 0.02;
        bodyRot = 0.04;
        leftArmAngle = 0.2;
        rightArmAngle = -0.2;
        break;
      case CharacterState.victory:
        bodyY = -sin(t * pi * 2).abs() * h * 0.06;
        leftArmAngle = -pi / 2;
        rightArmAngle = pi / 2;
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
        rightArmAngle = -pi / 2 + sin(t * pi * 3) * 0.3;
        leftArmAngle = 0.2;
        glowing = true;
        glowColor = const Color(0xFFAA00FF);
        break;
      case CharacterState.defend:
        squishX = 0.88;
        leftArmAngle = -0.1;
        rightArmAngle = -pi / 2;
        glowing = true;
        glowColor = Colors.blue;
        break;
    }

    canvas.save();
    canvas.translate(cx, h * 0.55 + bodyY + jumpOff);
    canvas.rotate(bodyRot);
    canvas.scale(squishX, squishY);

    if (glowing) {
      canvas.drawCircle(Offset.zero, w * 0.38, _glow(glowColor, 18));
    }

    _drawShadow(canvas, w, h);

    switch (data.type) {
      case CharacterType.robot:
        _drawRobot(canvas, w, h, leftLegAngle, rightLegAngle,
            leftArmAngle, rightArmAngle, mouthOpen, t);
        break;
      case CharacterType.dragon:
        _drawDragon(canvas, w, h, leftLegAngle, rightLegAngle,
            leftArmAngle, rightArmAngle, mouthOpen, t);
        break;
      case CharacterType.ninja:
        _drawNinja(canvas, w, h, leftLegAngle, rightLegAngle,
            leftArmAngle, rightArmAngle, mouthOpen, t);
        break;
      default:
        _drawHuman(canvas, w, h, leftLegAngle, rightLegAngle,
            leftArmAngle, rightArmAngle, mouthOpen, t);
        break;
    }
    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, h * 0.34),
          width: w * 0.55,
          height: h * 0.07),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawHuman(
    Canvas canvas, double w, double h,
    double llA, double rlA, double laA, double raA,
    double mouthOpen, double t,
  ) {
    final bw = w * 0.38;
    final bh = h * 0.32;
    final legW = w * 0.11;
    final legH = h * 0.22;
    final armW = w * 0.10;
    final armH = h * 0.24;
    final headR = w * 0.22;

    _drawLimb(canvas, Offset(-bw * 0.28, bh * 0.5), llA, legW, legH,
        data.primaryColor, data.primaryColor.withOpacity(0.7), true);
    _drawLimb(canvas, Offset(bw * 0.28, bh * 0.5), rlA, legW, legH,
        data.primaryColor, data.primaryColor.withOpacity(0.7), true);

    _drawBody(canvas, bw, bh);
    _drawBodyAccessory(canvas, w, h, bw, bh);

    _drawLimb(canvas, Offset(-bw * 0.52, -bh * 0.1), laA, armW, armH,
        data.primaryColor, data.skinColor, false);
    _drawLimb(canvas, Offset(bw * 0.52, -bh * 0.1), raA, armW, armH,
        data.primaryColor, data.skinColor, false);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -bh * 0.52),
            width: bw * 0.2,
            height: bh * 0.12),
        const Radius.circular(4),
      ),
      _fill(data.skinColor),
    );

    _drawHead(canvas, headR, mouthOpen, t);
  }

  void _drawBody(Canvas canvas, double bw, double bh) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
      Radius.circular(bw * 0.25),
    );
    final bodyGrad = Paint()
      ..shader = LinearGradient(
        colors: [
          data.primaryColor.withOpacity(0.85),
          data.primaryColor,
          data.primaryColor.withOpacity(0.75),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(
          center: Offset.zero, width: bw, height: bh));
    canvas.drawRRect(rect, bodyGrad);
    canvas.drawRRect(rect, _stroke(Colors.black.withOpacity(0.18), 1.5));
  }

  void _drawBodyAccessory(
      Canvas canvas, double w, double h, double bw, double bh) {
    switch (data.type) {
      case CharacterType.hero:
        final capePath = Path()
          ..moveTo(-bw * 0.45, -bh * 0.3)
          ..quadraticBezierTo(
              -bw * 0.8, bh * 0.4, -bw * 0.3, bh * 0.55)
          ..lineTo(-bw * 0.45, -bh * 0.3);
        canvas.drawPath(
            capePath,
            Paint()
              ..color = data.accentColor
              ..style = PaintingStyle.fill);
        _drawStar(canvas, Offset(0, -bh * 0.05), bw * 0.1,
            data.accentColor);
        break;
      case CharacterType.villain:
        final cloakPath = Path()
          ..moveTo(-bw * 0.5, -bh * 0.35)
          ..quadraticBezierTo(
              -bw * 0.9, bh * 0.5, -bw * 0.2, bh * 0.55)
          ..lineTo(-bw * 0.5, -bh * 0.35);
        canvas.drawPath(
            cloakPath,
            Paint()
              ..color = const Color(0xFF1A0000)
              ..style = PaintingStyle.fill);
        canvas.drawCircle(
            Offset(0, -bh * 0.05), bw * 0.08, _fill(data.accentColor));
        break;
      case CharacterType.wizard:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, bh * 0.05),
                width: bw * 1.02,
                height: bh * 0.1),
            Radius.circular(4),
          ),
          _fill(data.accentColor.withOpacity(0.6)),
        );
        break;
      case CharacterType.warrior:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, -bh * 0.1),
                width: bw * 0.7,
                height: bh * 0.35),
            Radius.circular(6),
          ),
          _fill(const Color(0xFF9E9E9E)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, -bh * 0.1),
                width: bw * 0.7,
                height: bh * 0.35),
            Radius.circular(6),
          ),
          _stroke(Colors.black26, 1.5),
        );
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

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-lw / 2, 0, lw, lh),
      Radius.circular(lw / 2),
    );
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [topColor, endColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-lw / 2, 0, lw, lh));
    canvas.drawRRect(rect, grad);
    canvas.drawRRect(rect, _stroke(Colors.black.withOpacity(0.15), 1.2));

    if (isLeg) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-lw * 0.8, lh - lw * 0.4, lw * 1.8, lw * 0.7),
          Radius.circular(lw * 0.4),
        ),
        _fill(Colors.black87),
      );
    } else {
      canvas.drawCircle(
          Offset(0, lh + lw * 0.15), lw * 0.5, _fill(data.skinColor));
    }
    canvas.restore();
  }

  void _drawHead(Canvas canvas, double headR, double mouthOpen, double t) {
    final headY = -headR * 2.1;
    canvas.drawCircle(Offset(0, headY), headR, _fill(data.skinColor));
    canvas.drawCircle(Offset(0, headY), headR,
        _stroke(Colors.black.withOpacity(0.15), 1.5));
    _drawHair(canvas, headR, headY);
    _drawEyes(canvas, headR, headY, t);
    _drawMouth(canvas, headR, headY, mouthOpen);
    _drawHeadAccessory(canvas, headR, headY);
  }

  void _drawHair(Canvas canvas, double r, double hy) {
    final paint = _fill(data.hairColor);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, hy), radius: r * 1.02),
      -math.pi, math.pi, true, paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.95, hy - r * 0.1, r * 0.2, r * 0.5),
        Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r * 0.75, hy - r * 0.1, r * 0.2, r * 0.5),
        Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawEyes(Canvas canvas, double r, double hy, double t) {
    final eyeOffsets = [
      Offset(-r * 0.35, hy - r * 0.05),
      Offset(r * 0.35, hy - r * 0.05),
    ];

    for (final eo in eyeOffsets) {
      canvas.drawOval(
        Rect.fromCenter(center: eo, width: r * 0.32, height: r * 0.28),
        _fill(Colors.white),
      );
      canvas.drawCircle(eo + Offset(0, r * 0.02), r * 0.1,
          _fill(const Color(0xFF1565C0)));
      canvas.drawCircle(eo + Offset(0, r * 0.02), r * 0.055,
          _fill(Colors.black));
      canvas.drawCircle(
          eo + Offset(-r * 0.04, -r * 0.04), r * 0.03, _fill(Colors.white));
      final blinkH = state == CharacterState.idle ? math.sin(t * math.pi * 0.7).abs() * r * 0.02 : 0.0;
      if (blinkH > 0.01) {
        canvas.drawOval(
          Rect.fromCenter(
              center: eo - Offset(0, r * 0.07),
              width: r * 0.34,
              height: blinkH * 2),
          _fill(data.skinColor),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: eo, width: r * 0.32, height: r * 0.28),
        _stroke(Colors.black.withOpacity(0.3), 1.0),
      );
    }

    double browTilt = 0;
    if (state == CharacterState.angry) browTilt = 0.38;
    if (state == CharacterState.sad) browTilt = -0.28;

    for (final s in [-1.0, 1.0]) {
      final bx = s * r * 0.35;
      canvas.save();
      canvas.translate(bx, hy - r * 0.22);
      canvas.rotate(s * browTilt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 0.3, height: r * 0.07),
          Radius.circular(3),
        ),
        _fill(data.hairColor),
      );
      canvas.restore();
    }
  }

  void _drawMouth(Canvas canvas, double r, double hy, double mouthOpen) {
    final my = hy + r * 0.32;
    final path = Path();
    if (state == CharacterState.happy || state == CharacterState.victory) {
      path.moveTo(-r * 0.28, my - r * 0.04);
      path.quadraticBezierTo(0, my + r * 0.25, r * 0.28, my - r * 0.04);
      canvas.drawPath(path, _stroke(Colors.black87, 2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, my + r * 0.06),
              width: r * 0.38, height: r * 0.1),
          Radius.circular(3),
        ),
        _fill(Colors.white),
      );
    } else if (state == CharacterState.sad) {
      path.moveTo(-r * 0.24, my + r * 0.05);
      path.quadraticBezierTo(0, my - r * 0.12, r * 0.24, my + r * 0.05);
      canvas.drawPath(path, _stroke(Colors.black87, 2));
    } else if (state == CharacterState.angry) {
      path.moveTo(-r * 0.26, my + r * 0.02);
      path.lineTo(r * 0.26, my + r * 0.02);
      canvas.drawPath(path, _stroke(Colors.black87, 2.5));
    } else if (state == CharacterState.talk) {
      final openAmount = mouthOpen * r * 0.15 + r * 0.04;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, my), width: r * 0.3, height: openAmount * 2),
        _fill(const Color(0xFF880E4F)),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, my), width: r * 0.3, height: openAmount * 2),
        _stroke(Colors.black54, 1.5),
      );
      if (openAmount > r * 0.05) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-r * 0.12, my - openAmount, r * 0.24, r * 0.06),
            Radius.circular(2),
          ),
          _fill(Colors.white.withOpacity(0.9)),
        );
      }
    } else {
      path.moveTo(-r * 0.18, my);
      path.lineTo(r * 0.18, my);
      canvas.drawPath(path, _stroke(Colors.black54, 1.8));
    }
  }

  void _drawHeadAccessory(Canvas canvas, double r, double hy) {
    switch (data.type) {
      case CharacterType.hero:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, hy - r * 0.05),
                width: r * 1.1, height: r * 0.35),
            Radius.circular(r * 0.1),
          ),
          _fill(data.primaryColor.withOpacity(0.75)),
        );
        break;
      case CharacterType.wizard:
        final hatPath = Path()
          ..moveTo(-r * 0.55, hy - r * 0.8)
          ..lineTo(0, hy - r * 2.1)
          ..lineTo(r * 0.55, hy - r * 0.8)
          ..close();
        canvas.drawPath(hatPath, _fill(data.primaryColor));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, hy - r * 0.82),
                width: r * 1.4, height: r * 0.22),
            Radius.circular(r * 0.08),
          ),
          _fill(data.primaryColor.withOpacity(0.8)),
        );
        _drawStar(canvas, Offset(0, hy - r * 1.5), r * 0.12,
            data.accentColor);
        break;
      case CharacterType.ninja:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, hy + r * 0.15),
                width: r * 1.1, height: r * 0.5),
            Radius.circular(r * 0.1),
          ),
          _fill(Colors.black87),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, hy - r * 0.25),
                width: r * 1.15, height: r * 0.22),
            Radius.circular(r * 0.06),
          ),
          _fill(data.accentColor),
        );
        break;
      case CharacterType.warrior:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, hy - r * 0.08), radius: r * 1.08),
          -math.pi * 1.1, math.pi * 1.2, false,
          _fill(const Color(0xFF9E9E9E)),
        );
        break;
      case CharacterType.princess:
        final crownPath = Path()
          ..moveTo(-r * 0.5, hy - r * 1.0)
          ..lineTo(-r * 0.5, hy - r * 1.35)
          ..lineTo(-r * 0.25, hy - r * 1.2)
          ..lineTo(0, hy - r * 1.45)
          ..lineTo(r * 0.25, hy - r * 1.2)
          ..lineTo(r * 0.5, hy - r * 1.35)
          ..lineTo(r * 0.5, hy - r * 1.0)
          ..close();
        canvas.drawPath(crownPath, _fill(const Color(0xFFFFD600)));
        canvas.drawPath(crownPath, _stroke(const Color(0xFFFF8F00), 1.5));
        for (final gx in [-r * 0.25, 0.0, r * 0.25]) {
          canvas.drawCircle(Offset(gx, hy - r * 1.1), r * 0.06,
              _fill(data.accentColor));
        }
        break;
      default:
        break;
    }
  }

  void _drawRobot(
    Canvas canvas, double w, double h,
    double llA, double rlA, double laA, double raA,
    double mouthOpen, double t,
  ) {
    final bw = w * 0.4;
    final bh = h * 0.3;
    final legW = w * 0.13;
    final legH = h * 0.2;
    final armW = w * 0.11;
    final armH = h * 0.22;
    final headW = w * 0.42;
    final headH = h * 0.26;

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.27, bh * 0.5);
      canvas.rotate(side == -1 ? llA : rlA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-legW / 2, 0, legW, legH),
            Radius.circular(4)),
        _fill(data.primaryColor),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-legW * 0.8, legH - legW * 0.4, legW * 1.8, legW * 0.7),
            Radius.circular(3)),
        _fill(data.primaryColor.withOpacity(0.7)),
      );
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
          Radius.circular(6)),
      _fill(data.primaryColor),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.05), width: bw * 0.6, height: bh * 0.5),
          Radius.circular(4)),
      _fill(data.primaryColor.withOpacity(0.5)),
    );
    canvas.drawCircle(
        Offset(0, -bh * 0.08), bw * 0.08,
        _fill(data.accentColor));
    canvas.drawCircle(
        Offset(0, -bh * 0.08), bw * 0.08,
        _glow(data.accentColor, 8));
    for (final bx in [-bw * 0.38, bw * 0.38]) {
      for (final by in [-bh * 0.3, bh * 0.25]) {
        canvas.drawCircle(Offset(bx, by), w * 0.025,
            _fill(data.accentColor.withOpacity(0.6)));
      }
    }

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.55, -bh * 0.1);
      canvas.rotate(side == -1 ? laA : raA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-armW / 2, 0, armW, armH), Radius.circular(4)),
        _fill(data.primaryColor.withOpacity(0.8)),
      );
      canvas.drawCircle(
          Offset(0, armH + armW * 0.2), armW * 0.5, _fill(data.primaryColor));
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.72), width: headW, height: headH),
          Radius.circular(8)),
      _fill(data.primaryColor),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.7), width: headW * 0.75, height: headH * 0.4),
          Radius.circular(4)),
      _fill(data.accentColor.withOpacity(0.25)),
    );
    final ledGlow = math.sin(t * math.pi * 4).abs();
    for (final ex in [-headW * 0.2, headW * 0.2]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.72),
            width: headW * 0.15,
            height: headH * 0.2),
        _fill(data.accentColor.withOpacity(0.6 + ledGlow * 0.4)),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.72),
            width: headW * 0.15,
            height: headH * 0.2),
        _glow(data.accentColor, 6),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.58), width: headW * 0.45, height: headH * 0.15),
          Radius.circular(3)),
      _fill(Colors.black54),
    );
    if (state == CharacterState.talk) {
      for (int i = -2; i <= 2; i++) {
        final lineH = headH * 0.05 + mouthOpen * headH * 0.05;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(i * headW * 0.08, -bh * 0.58),
                  width: headW * 0.03,
                  height: lineH),
              Radius.circular(1)),
          _fill(data.accentColor),
        );
      }
    }
    canvas.drawLine(
      Offset(0, -bh * 0.72 - headH * 0.5),
      Offset(0, -bh * 0.72 - headH * 0.88),
      _stroke(data.primaryColor, 2),
    );
    canvas.drawCircle(
        Offset(0, -bh * 0.72 - headH * 0.88), w * 0.035,
        _fill(data.accentColor));
    canvas.drawCircle(
        Offset(0, -bh * 0.72 - headH * 0.88), w * 0.035,
        _glow(data.accentColor, 5));
  }

  void _drawDragon(
    Canvas canvas, double w, double h,
    double llA, double rlA, double laA, double raA,
    double mouthOpen, double t,
  ) {
    final bw = w * 0.44;
    final bh = h * 0.3;

    final tailPath = Path()
      ..moveTo(bw * 0.4, 0)
      ..quadraticBezierTo(bw * 1.2, bh * 0.3, bw * 0.9, bh * 0.7)
      ..quadraticBezierTo(bw * 0.6, bh * 0.5, bw * 0.4, bh * 0.5);
    canvas.drawPath(tailPath, _fill(data.primaryColor.withOpacity(0.8)));

    if (state == CharacterState.fly) {
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
        canvas.drawPath(wingPath,
            _fill(data.primaryColor.withOpacity(0.65)));
        canvas.restore();
      }
    }

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.28, bh * 0.45);
      canvas.rotate(side == -1 ? llA : rlA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * 0.07, 0, w * 0.14, h * 0.18),
            Radius.circular(5)),
        _fill(data.primaryColor),
      );
      for (int c = -1; c <= 1; c++) {
        canvas.drawLine(
          Offset(c * w * 0.04, h * 0.18),
          Offset(c * w * 0.06, h * 0.22),
          _stroke(Colors.black87, 2),
        );
      }
      canvas.restore();
    }

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
      _fill(data.primaryColor),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, bh * 0.08), width: bw * 0.55, height: bh * 0.6),
      _fill(data.skinColor.withOpacity(0.45)),
    );

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.5, -bh * 0.15);
      canvas.rotate(side == -1 ? laA : raA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * 0.07, 0, w * 0.14, h * 0.2),
            Radius.circular(5)),
        _fill(data.primaryColor),
      );
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.55), width: bw * 0.22, height: bh * 0.28),
          Radius.circular(8)),
      _fill(data.primaryColor),
    );

    final headOval =
        Rect.fromCenter(center: Offset(0, -bh * 0.88), width: bw * 0.55, height: bh * 0.4);
    canvas.drawOval(headOval, _fill(data.primaryColor));

    final snoutOpen = mouthOpen * bh * 0.1 + bh * 0.04;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(bw * 0.18, -bh * 0.88 + snoutOpen * 0.3),
              width: bw * 0.28,
              height: snoutOpen),
          Radius.circular(4)),
      _fill(data.primaryColor),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(bw * 0.18, -bh * 0.88 + snoutOpen),
              width: bw * 0.26,
              height: snoutOpen * 0.7),
          Radius.circular(4)),
      _fill(data.skinColor.withOpacity(0.6)),
    );
    if (state == CharacterState.attack && mouthOpen > 0.3) {
      final firePath = Path()
        ..moveTo(bw * 0.3, -bh * 0.85)
        ..quadraticBezierTo(bw * 0.8, -bh * 0.7, bw * 1.1, -bh * 0.88)
        ..quadraticBezierTo(bw * 0.8, -bh * 1.0, bw * 0.3, -bh * 0.88);
      canvas.drawPath(
          firePath, _fill(const Color(0xFFFF6D00).withOpacity(0.85)));
      canvas.drawPath(firePath, _glow(const Color(0xFFFF6D00), 10));
    }

    for (final ex in [-bw * 0.08, bw * 0.22]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.95), width: bw * 0.12, height: bh * 0.1),
        _fill(Colors.yellow),
      );
      canvas.drawCircle(
          Offset(ex, -bh * 0.95), bw * 0.035, _fill(Colors.black));
    }

    for (final hx in [-bw * 0.16, bw * 0.16]) {
      final hornPath = Path()
        ..moveTo(hx, -bh * 1.06)
        ..lineTo(hx - bw * 0.04, -bh * 1.25)
        ..lineTo(hx + bw * 0.04, -bh * 1.06)
        ..close();
      canvas.drawPath(hornPath, _fill(const Color(0xFF4A148C)));
    }
  }

  void _drawNinja(
    Canvas canvas, double w, double h,
    double llA, double rlA, double laA, double raA,
    double mouthOpen, double t,
  ) {
    final bw = w * 0.36;
    final bh = h * 0.30;

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.27, bh * 0.5);
      canvas.rotate(side == -1 ? llA : rlA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * 0.09, 0, w * 0.18, h * 0.22),
            Radius.circular(5)),
        _fill(Colors.black87),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * 0.12, h * 0.19, w * 0.24, w * 0.08),
            Radius.circular(4)),
        _fill(const Color(0xFF333333)),
      );
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
          Radius.circular(8)),
      _fill(Colors.black87),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, bh * 0.05), width: bw * 1.02, height: bh * 0.12),
          Radius.circular(4)),
      _fill(data.accentColor),
    );
    canvas.drawCircle(Offset(bw * 0.38, bh * 0.05), bh * 0.08,
        _fill(data.accentColor));

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * bw * 0.52, -bh * 0.08);
      canvas.rotate(side == -1 ? laA : raA);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * 0.075, 0, w * 0.15, h * 0.22),
            Radius.circular(5)),
        _fill(Colors.black87),
      );
      canvas.drawCircle(Offset(0, h * 0.22 + w * 0.07), w * 0.07,
          _fill(const Color(0xFF222222)));
      canvas.restore();
    }

    if (state == CharacterState.attack) {
      canvas.save();
      canvas.translate(-bw * 0.55, -bh * 0.05);
      canvas.rotate(t * math.pi * 8);
      _drawShuriken(canvas, w * 0.1, data.accentColor);
      canvas.restore();
    }

    canvas.drawCircle(Offset(0, -bh * 0.72), w * 0.22, _fill(data.skinColor));
    canvas.drawCircle(
        Offset(0, -bh * 0.72), w * 0.22,
        _stroke(Colors.black.withOpacity(0.15), 1.5));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.65), width: w * 0.4, height: w * 0.2),
          Radius.circular(4)),
      _fill(Colors.black87),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -bh * 0.8), width: w * 0.44, height: w * 0.12),
          Radius.circular(4)),
      _fill(data.accentColor),
    );
    for (final ex in [-w * 0.09, w * 0.09]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, -bh * 0.76),
            width: w * 0.1, height: w * 0.065),
        _fill(Colors.black),
      );
      canvas.drawCircle(
          Offset(ex + w * 0.02, -bh * 0.77), w * 0.02, _fill(Colors.white));
    }
  }

  void _drawShuriken(Canvas canvas, double r, Color color) {
    final paint = _fill(color);
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-r * 0.4, -r)
        ..lineTo(r * 0.4, -r)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * 0.25, _fill(Colors.grey));
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.42;
      final px = center.dx + math.cos(angle) * radius;
      final py = center.dy + math.sin(angle) * radius;
      if (i == 0) path.moveTo(px, py);
      else path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, _fill(color));
  }

  @override
  bool shouldRepaint(_CartoonCharacterPainter old) =>
      old.tick != tick || old.state != state || old.data.type != data.type;
}
