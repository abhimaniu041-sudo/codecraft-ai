import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ParticleType { fire, smoke, explosion, magic, sparks, snow, rain, stars, dust, energy }

class Particle {
  double x, y, vx, vy;
  double life, maxLife;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.life, required this.size,
    required this.color,
    this.rotation = 0,
    this.rotationSpeed = 0,
  }) : maxLife = life;

  double get alpha => (life / maxLife).clamp(0, 1);
  bool get isDead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
    rotation += rotationSpeed * dt;
  }
}

class ParticleSystem {
  final List<Particle> _particles = [];
  final math.Random _rng = math.Random();
  ParticleType type;
  double x, y;
  bool active;
  double emitRate;
  double _emitTimer = 0;

  ParticleSystem({
    required this.type,
    required this.x,
    required this.y,
    this.active = true,
    this.emitRate = 20,
  });

  void update(double dt) {
    // Remove dead
    _particles.removeWhere((p) => p.isDead);

    // Update alive
    for (final p in _particles) {
      p.update(dt);
      _applyPhysics(p, dt);
    }

    // Emit new
    if (active) {
      _emitTimer += dt;
      final interval = 1.0 / emitRate;
      while (_emitTimer >= interval) {
        _emitTimer -= interval;
        _emit();
      }
    }
  }

  void _applyPhysics(Particle p, double dt) {
    switch (type) {
      case ParticleType.fire:
        p.vy -= 80 * dt; // Rise
        p.vx += (_rng.nextDouble() - 0.5) * 30 * dt;
        p.size *= (1 - dt * 0.8);
        break;
      case ParticleType.smoke:
        p.vy -= 20 * dt;
        p.vx += (_rng.nextDouble() - 0.5) * 10 * dt;
        p.size *= (1 + dt * 0.3);
        break;
      case ParticleType.explosion:
        p.vy += 150 * dt; // Gravity
        p.size *= (1 - dt * 1.5);
        break;
      case ParticleType.magic:
        p.vy -= 40 * dt;
        p.vx += math.sin(p.life * 5) * 20 * dt;
        break;
      case ParticleType.sparks:
        p.vy += 200 * dt;
        p.size *= (1 - dt * 2);
        break;
      case ParticleType.snow:
        p.vx += math.sin(p.life * 2) * 10 * dt;
        p.vy += 20 * dt;
        break;
      case ParticleType.rain:
        p.vy += 100 * dt;
        break;
      case ParticleType.stars:
        p.size = 2 + math.sin(p.life * 3) * 1;
        break;
      case ParticleType.dust:
        p.vx *= (1 - dt * 2);
        p.vy += 30 * dt;
        p.size *= (1 - dt * 0.5);
        break;
      case ParticleType.energy:
        p.vx = math.cos(p.life * 8) * 60;
        p.vy -= 60 * dt;
        break;
    }
  }

  void _emit() {
    switch (type) {
      case ParticleType.fire:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 30,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 40,
          vy: -(_rng.nextDouble() * 60 + 40),
          life: _rng.nextDouble() * 0.8 + 0.3,
          size: _rng.nextDouble() * 16 + 8,
          color: [
            const Color(0xFFFF6D00),
            const Color(0xFFFF3D00),
            const Color(0xFFFFD600),
            const Color(0xFFFF1744),
          ][_rng.nextInt(4)],
          rotationSpeed: (_rng.nextDouble() - 0.5) * 4,
        ));
        break;
      case ParticleType.smoke:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 20,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 20,
          vy: -(_rng.nextDouble() * 30 + 10),
          life: _rng.nextDouble() * 1.5 + 0.5,
          size: _rng.nextDouble() * 25 + 10,
          color: Color.fromRGBO(150, 150, 150, _rng.nextDouble() * 0.4 + 0.1),
          rotationSpeed: (_rng.nextDouble() - 0.5) * 1,
        ));
        break;
      case ParticleType.explosion:
        for (int i = 0; i < 3; i++) {
          final angle = _rng.nextDouble() * math.pi * 2;
          final speed = _rng.nextDouble() * 200 + 100;
          _particles.add(Particle(
            x: x + (_rng.nextDouble() - 0.5) * 20,
            y: y + (_rng.nextDouble() - 0.5) * 20,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 100,
            life: _rng.nextDouble() * 0.6 + 0.2,
            size: _rng.nextDouble() * 14 + 4,
            color: [
              const Color(0xFFFF6D00),
              const Color(0xFFFFD600),
              const Color(0xFFFF1744),
              Colors.white,
            ][_rng.nextInt(4)],
            rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
          ));
        }
        break;
      case ParticleType.magic:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 40,
          y: y + (_rng.nextDouble() - 0.5) * 40,
          vx: (_rng.nextDouble() - 0.5) * 30,
          vy: -(_rng.nextDouble() * 50 + 20),
          life: _rng.nextDouble() * 1.0 + 0.4,
          size: _rng.nextDouble() * 8 + 3,
          color: [
            const Color(0xFFAA00FF),
            const Color(0xFFE040FB),
            const Color(0xFF7C4DFF),
            const Color(0xFF00E5FF),
          ][_rng.nextInt(4)],
          rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
        ));
        break;
      case ParticleType.sparks:
        final angle = _rng.nextDouble() * math.pi * 2;
        final speed = _rng.nextDouble() * 150 + 50;
        _particles.add(Particle(
          x: x, y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 80,
          life: _rng.nextDouble() * 0.3 + 0.1,
          size: _rng.nextDouble() * 4 + 2,
          color: [Colors.yellow, Colors.orange, Colors.white][_rng.nextInt(3)],
        ));
        break;
      case ParticleType.snow:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 400,
          y: y - 50,
          vx: (_rng.nextDouble() - 0.5) * 20,
          vy: _rng.nextDouble() * 40 + 20,
          life: _rng.nextDouble() * 4 + 2,
          size: _rng.nextDouble() * 6 + 2,
          color: Colors.white.withOpacity(0.8),
        ));
        break;
      case ParticleType.rain:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 400,
          y: y - 50,
          vx: -10,
          vy: _rng.nextDouble() * 200 + 200,
          life: 0.5,
          size: 2,
          color: Colors.lightBlue.withOpacity(0.6),
        ));
        break;
      case ParticleType.stars:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 300,
          y: y + (_rng.nextDouble() - 0.5) * 200,
          vx: 0, vy: 0,
          life: _rng.nextDouble() * 3 + 1,
          size: _rng.nextDouble() * 3 + 1,
          color: Colors.white.withOpacity(_rng.nextDouble() * 0.5 + 0.5),
        ));
        break;
      case ParticleType.dust:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 20,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 60,
          vy: -(_rng.nextDouble() * 30 + 10),
          life: _rng.nextDouble() * 0.8 + 0.3,
          size: _rng.nextDouble() * 10 + 4,
          color: Color.fromRGBO(180, 160, 120, _rng.nextDouble() * 0.5 + 0.2),
        ));
        break;
      case ParticleType.energy:
        _particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 10,
          y: y,
          vx: 0, vy: 0,
          life: _rng.nextDouble() * 0.5 + 0.2,
          size: _rng.nextDouble() * 6 + 2,
          color: [
            const Color(0xFF00E5FF),
            const Color(0xFF00B0FF),
            const Color(0xFFFFFFFF),
          ][_rng.nextInt(3)],
          rotationSpeed: _rng.nextDouble() * 4,
        ));
        break;
    }
  }

  void burst({int count = 30}) {
    active = false;
    for (int i = 0; i < count; i++) {
      _emit();
    }
  }

  void render(Canvas canvas) {
    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withOpacity((p.color.opacity * p.alpha).clamp(0, 1))
        ..maskFilter = type == ParticleType.fire || type == ParticleType.magic || type == ParticleType.energy
            ? MaskFilter.blur(BlurStyle.normal, p.size * 0.5)
            : null;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (type == ParticleType.rain) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 1.5, height: p.size * 4), paint);
      } else if (type == ParticleType.sparks) {
        canvas.drawLine(Offset.zero, Offset(p.vx * 0.02, p.vy * 0.02), paint..strokeWidth = p.size);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  int get count => _particles.length;
}
