import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Core animation states for cinematic 2D characters
enum CharacterState {
  idle, walk, run, attack, jump, fly, talk,
  angry, happy, sad, victory, death, cast, defend
}

/// Character archetypes for cinematic storytelling
enum CharacterType {
  hero, villain, robot, wizard, ninja,
  princess, warrior, alien, zombie, dragon
}

/// Character definition for the animation engine
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

/// Central registry for all cinematic character assets
class CharacterRegistry {
  static final Map<String, CharacterData> _all = {
    'hero': const CharacterData(
      type: CharacterType.hero, name: 'Hero',
      primaryColor: Color(0xFF1565C0), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E), accentColor: Color(0xFFFFD600),
    ),
    'villain': const CharacterData(
      type: CharacterType.villain, name: 'Villain',
      primaryColor: Color(0xFF4A0000), skinColor: Color(0xFFB0BEC5),
      hairColor: Color(0xFF212121), accentColor: Color(0xFFFF1744),
    ),
    'robot': const CharacterData(
      type: CharacterType.robot, name: 'Robot',
      primaryColor: Color(0xFF37474F), skinColor: Color(0xFF607D8B),
      hairColor: Color(0xFF263238), accentColor: Color(0xFF00E5FF),
    ),
    'wizard': const CharacterData(
      type: CharacterType.wizard, name: 'Wizard',
      primaryColor: Color(0xFF4A148C), skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFE0E0E0), accentColor: Color(0xFFAA00FF),
    ),
    'ninja': const CharacterData(
      type: CharacterType.ninja, name: 'Ninja',
      primaryColor: Color(0xFF212121), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF212121), accentColor: Color(0xFFFF1744),
    ),
    'princess': const CharacterData(
      type: CharacterType.princess, name: 'Princess',
      primaryColor: Color(0xFFAD1457), skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFFFFD600), accentColor: Color(0xFFFF80AB),
    ),
    'warrior': const CharacterData(
      type: CharacterType.warrior, name: 'Warrior',
      primaryColor: Color(0xFF4E342E), skinColor: Color(0xFFFFCC80),
      hairColor: Color(0xFF4E342E), accentColor: Color(0xFFFFD600),
    ),
    'alien': const CharacterData(
      type: CharacterType.alien, name: 'Alien',
      primaryColor: Color(0xFF1B5E20), skinColor: Color(0xFF69F0AE),
      hairColor: Color(0xFF004D40), accentColor: Color(0xFF00E5FF),
    ),
    'zombie': const CharacterData(
      type: CharacterType.zombie, name: 'Zombie',
      primaryColor: Color(0xFF33691E), skinColor: Color(0xFF8D9A4A),
      hairColor: Color(0xFF212121), accentColor: Color(0xFF76FF03),
    ),
    'dragon': const CharacterData(
      type: CharacterType.dragon, name: 'Dragon',
      primaryColor: Color(0xFF7B1FA2), skinColor: Color(0xFF9C27B0),
      hairColor: Color(0xFF4A148C), accentColor: Color(0xFFFF6D00),
    ),
  };

  static CharacterData? get(String id) => _all[id];
  static List<String> getAllIds() => _all.keys.toList();
}

// ─── Animated Character Widget (Cinematic Controller) ──────────
class AnimatedCharacterWidget extends StatefulWidget {
  final String characterId;
  final CharacterState state;
  final double size;
  final bool facingRight;

  const AnimatedCharacterWidget({
    super.key,
    required this.characterId,
    this.state = CharacterState.idle,
    this.size = 120,
    this.facingRight = true,
  });

  @override
  State<AnimatedCharacterWidget> createState() => _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
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
          child: CustomPaint(painter: _CartoonCharacterPainter(data: data, state: widget.state, tick: _ctrl.value)),
        ),
      ),
    );
  }
}

// NOTE: _CartoonCharacterPainter class remains exactly as per your provided code 
// to ensure seamless rendering of the animated sequences.
