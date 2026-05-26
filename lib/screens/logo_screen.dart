import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});
  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> with TickerProviderStateMixin {
  final GlobalKey _logoKey = GlobalKey();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _symbolCtrl = TextEditingController(text: 'CA');
  Color _primary = const Color(0xFF6C63FF);
  Color _secondary = const Color(0xFF3ECFCF);
  String _style = 'gradient';
  String _shape = 'circle';
  bool _generated = false;
  bool _saving = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _styles = [
    {'v': 'gradient', 'l': '🌈 Gradient'},
    {'v': 'dark', 'l': '🌙 Dark'},
    {'v': 'neon', 'l': '⚡ Neon'},
    {'v': 'minimal', 'l': '✨ Minimal'},
    {'v': 'gold', 'l': '🏆 Gold'},
    {'v': 'fire', 'l': '🔥 Fire'},
    {'v': 'corporate', 'l': '💼 Corporate'},
    {'v': 'retro', 'l': '📺 Retro'},
    {'v': 'cyber', 'l': '🤖 Cyber'},
    {'v': 'nature', 'l': '🌿 Nature'},
  ];

  final List<Map<String, dynamic>> _shapes = [
    {'v': 'circle', 'l': '⭕ Circle'},
    {'v': 'square', 'l': '⬛ Square'},
    {'v': 'rounded', 'l': '🟦 Rounded'},
    {'v': 'diamond', 'l': '💎 Diamond'},
    {'v': 'hexagon', 'l': '⬡ Hexagon'},
    {'v': 'badge', 'l': '🏅 Badge'},
  ];

  final List<Color> _colors = [
    const Color(0xFF6C63FF), const Color(0xFF3ECFCF),
    const Color(0xFFFF6B6B), const Color(0xFFFFD93D),
    const Color(0xFF6BCB77), const Color(0xFF4D96FF),
    const Color(0xFFFF922B), const Color(0xFFCC5DE8),
    const Color(0xFFFFD700), const Color(0xFFFF1744),
    const Color(0xFF00BCD4), const Color(0xFF00E676),
    Colors.white, Colors.black,
    const Color(0xFFE91E63), const Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLogo() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final boundary = _logoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Render error');
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image null');
      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final name = _nameCtrl.text.trim().replaceAll(' ', '_');
      final file = File('${dir.path}/${name}_logo_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12122A),
            title: const Text('Logo Saved! ✅', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, height: 180, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text('Logo saved successfully!', style: TextStyle(color: Colors.grey)),
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
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: const Row(children: [
          Icon(Icons.brush, color: Color(0xFF6C63FF)),
          SizedBox(width: 10),
          Text('Logo Creator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input(_nameCtrl, 'Brand / Company Naam *', Icons.title),
            const SizedBox(height: 8),
            _input(_taglineCtrl, 'Tagline (optional)', Icons.subtitles),
            const SizedBox(height: 8),
            _input(_symbolCtrl, 'Logo Initials / Text (e.g. CA, Nike, AS)', Icons.text_fields),
            const SizedBox(height: 14),

            _label('🎨 Colors'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(children: [
                const Text('Primary', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _colorPicker(true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: const Center(child: Icon(Icons.colorize, color: Colors.white70, size: 20)),
                  ),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [
                const Text('Secondary', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _colorPicker(false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _secondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [BoxShadow(color: _secondary.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: const Center(child: Icon(Icons.colorize, color: Colors.white70, size: 20)),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 14),

            _label('🎭 Style'),
            const SizedBox(height: 8),
            SizedBox(height: 40, child: ListView(
              scrollDirection: Axis.horizontal,
              children: _styles.map((s) {
                final sel = _style == s['v'];
                return GestureDetector(
                  onTap: () => setState(() { _style = s['v']; }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: sel ? LinearGradient(colors: [_primary, _secondary]) : null,
                      color: sel ? null : const Color(0xFF12122A),
                      border: Border.all(color: sel ? Colors.transparent : Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s['l'], style: TextStyle(color: sel ? Colors.white : Colors.grey, fontSize: 12)),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 14),

            _label('🔷 Shape'),
            const SizedBox(height: 8),
            SizedBox(height: 40, child: ListView(
              scrollDirection: Axis.horizontal,
              children: _shapes.map((s) {
                final sel = _shape == s['v'];
                return GestureDetector(
                  onTap: () => setState(() { _shape = s['v']; }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _primary : const Color(0xFF12122A),
                      border: Border.all(color: sel ? _primary : Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s['l'], style: TextStyle(color: sel ? Colors.white : Colors.grey, fontSize: 12)),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand naam daalo!')));
                  return;
                }
                setState(() => _generated = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _secondary]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Logo Banao', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )),
              ),
            ),

            if (_generated) ...[
              const SizedBox(height: 24),
              const Center(child: Text('Preview:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Center(
                child: RepaintBoundary(
                  key: _logoKey,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (ctx, child) => Transform.scale(scale: 1.0, child: child),
                    child: _buildLogo(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _saving ? null : _saveLogo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _saving ? null : LinearGradient(colors: [_primary, _secondary]),
                    color: _saving ? Colors.grey : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: _saving
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Saving...', style: TextStyle(color: Colors.white)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.download, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Logo Save Karo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ])),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim().toUpperCase();
    final tagline = _taglineCtrl.text.trim();

    Color bg1, bg2, textColor, symbolColor, accentColor;
    List<BoxShadow> outerShadow = [];
    List<BoxShadow> innerShadow = [];

    switch (_style) {
      case 'dark':
        bg1 = const Color(0xFF0A0A14); bg2 = const Color(0xFF1A1A2E);
        textColor = Colors.white; symbolColor = _primary; accentColor = _secondary;
        break;
      case 'neon':
        bg1 = Colors.black; bg2 = const Color(0xFF050510);
        textColor = _primary; symbolColor = _secondary; accentColor = _primary;
        outerShadow = [BoxShadow(color: _primary.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)];
        innerShadow = [BoxShadow(color: _secondary.withOpacity(0.8), blurRadius: 20)];
        break;
      case 'minimal':
        bg1 = Colors.white; bg2 = const Color(0xFFF8F8FF);
        textColor = _primary; symbolColor = _primary; accentColor = _secondary;
        break;
      case 'gold':
        bg1 = const Color(0xFF1A1000); bg2 = const Color(0xFF2D1E00);
        textColor = const Color(0xFFFFD700); symbolColor = const Color(0xFFFFA500);
        accentColor = const Color(0xFFFFD700);
        outerShadow = [const BoxShadow(color: Color(0x80FFD700), blurRadius: 20, spreadRadius: 3)];
        innerShadow = [const BoxShadow(color: Color(0x60FFD700), blurRadius: 15)];
        break;
      case 'fire':
        bg1 = const Color(0xFF1A0000); bg2 = const Color(0xFF3D0A00);
        textColor = const Color(0xFFFF6B35); symbolColor = const Color(0xFFFFD93D);
        accentColor = const Color(0xFFFF4500);
        outerShadow = [const BoxShadow(color: Color(0x80FF4500), blurRadius: 25, spreadRadius: 4)];
        break;
      case 'corporate':
        bg1 = const Color(0xFF003366); bg2 = const Color(0xFF004080);
        textColor = Colors.white; symbolColor = const Color(0xFFFFD700);
        accentColor = const Color(0xFFFFD700);
        break;
      case 'retro':
        bg1 = const Color(0xFF2D1B00); bg2 = const Color(0xFF4A2E00);
        textColor = const Color(0xFFFF9F1C); symbolColor = const Color(0xFFFFBF69);
        accentColor = const Color(0xFFFF9F1C);
        break;
      case 'cyber':
        bg1 = const Color(0xFF001A1A); bg2 = const Color(0xFF002D2D);
        textColor = const Color(0xFF00FF9F); symbolColor = const Color(0xFF00FFFF);
        accentColor = const Color(0xFF00FF9F);
        outerShadow = [const BoxShadow(color: Color(0x8000FF9F), blurRadius: 20, spreadRadius: 3)];
        break;
      case 'nature':
        bg1 = const Color(0xFF0D2818); bg2 = const Color(0xFF1A4731);
        textColor = const Color(0xFF90EE90); symbolColor = const Color(0xFF98FB98);
        accentColor = const Color(0xFF32CD32);
        break;
      default: // gradient
        bg1 = _primary; bg2 = _secondary;
        textColor = Colors.white; symbolColor = Colors.white; accentColor = Colors.white;
    }

    Widget symbolWidget = _buildSymbolShape(symbol, symbolColor, innerShadow, accentColor);

    return Container(
      width: 320, height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: outerShadow.isNotEmpty ? outerShadow : [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Background decorations
          ..._buildBgDecorations(bg1, bg2, accentColor),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                symbolWidget,
                const SizedBox(height: 16),
                // Brand name
                ShaderMask(
                  shaderCallback: (bounds) => _style == 'minimal' || _style == 'neon' || _style == 'cyber'
                      ? LinearGradient(colors: [textColor, accentColor]).createShader(bounds)
                      : LinearGradient(colors: [textColor, textColor]).createShader(bounds),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: name.length > 10 ? 18 : name.length > 6 ? 24 : 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: _style == 'neon' || _style == 'gold' || _style == 'fire' || _style == 'cyber'
                          ? [Shadow(color: textColor.withOpacity(0.8), blurRadius: 12)]
                          : [],
                    ),
                  ),
                ),
                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(tagline,
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11, letterSpacing: 1.5),
                  ),
                ],
                const SizedBox(height: 12),
                // Accent line
                Container(
                  width: 60, height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primary, _secondary]),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolShape(String symbol, Color symbolColor, List<BoxShadow> shadows, Color accentColor) {
    final text = symbol.length > 3 ? symbol.substring(0, 3) : symbol;
    final fontSize = text.length == 1 ? 56.0 : text.length == 2 ? 40.0 : 28.0;

    Widget textWidget = Text(text, style: TextStyle(
      color: symbolColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 2,
      shadows: [Shadow(color: symbolColor.withOpacity(0.6), blurRadius: 10)],
    ));

    BoxDecoration deco;
    switch (_shape) {
      case 'square':
        deco = BoxDecoration(
          color: symbolColor.withOpacity(0.15),
          border: Border.all(color: symbolColor.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: shadows,
        );
        return Container(width: 110, height: 110, decoration: deco, child: Center(child: textWidget));
      case 'rounded':
        deco = BoxDecoration(
          gradient: LinearGradient(colors: [_primary.withOpacity(0.3), _secondary.withOpacity(0.3)]),
          border: Border.all(color: symbolColor.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: shadows,
        );
        return Container(width: 110, height: 110, decoration: deco, child: Center(child: textWidget));
      case 'diamond':
        return Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: symbolColor.withOpacity(0.15),
              border: Border.all(color: symbolColor.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: shadows,
            ),
            child: Center(child: Transform.rotate(angle: -0.785, child: textWidget)),
          ),
        );
      case 'hexagon':
        return Container(
          width: 110, height: 110,
          child: CustomPaint(
            painter: _HexagonPainter(symbolColor.withOpacity(0.3), symbolColor.withOpacity(0.6)),
            child: Center(child: textWidget),
          ),
        );
      case 'badge':
        return Container(
          width: 110, height: 120,
          child: CustomPaint(
            painter: _BadgePainter(symbolColor.withOpacity(0.2), symbolColor),
            child: Center(child: textWidget),
          ),
        );
      default: // circle
        return Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_primary.withOpacity(0.3), _secondary.withOpacity(0.3)]),
            border: Border.all(color: symbolColor.withOpacity(0.7), width: 2.5),
            boxShadow: shadows,
          ),
          child: Center(child: textWidget),
        );
    }
  }

  List<Widget> _buildBgDecorations(Color bg1, Color bg2, Color accent) => [
    Positioned(right: -30, top: -30,
      child: Container(width: 150, height: 150,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.06)))),
    Positioned(left: -20, bottom: -20,
      child: Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.06)))),
    Positioned(right: 20, bottom: 40,
      child: Container(width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.08)))),
    Positioned(left: 20, top: 40,
      child: Container(width: 25, height: 25,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.08)))),
  ];

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));

  Widget _input(TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    onChanged: (_) { if (_generated) setState(() {}); },
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
      filled: true, fillColor: const Color(0xFF12122A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF))),
    ),
  );

  void _colorPicker(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isPrimary ? 'Primary Color' : 'Secondary Color',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12,
              children: _colors.map((c) => GestureDetector(
                onTap: () {
                  setState(() { isPrimary ? _primary = c : _secondary = c; });
                  Navigator.pop(ctx);
                },
                child: Container(width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)],
                  )),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _HexagonPainter(this.fill, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fill..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.48;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      if (i == 0) path.moveTo(cx + r * cos(angle), cy + r * sin(angle));
      else path.lineTo(cx + r * cos(angle), cy + r * sin(angle));
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  double cos(double a) => _cos(a);
  double sin(double a) => _sin(a);
  double _cos(double x) {
    x = x % (2 * 3.14159);
    return 1 - x*x/2 + x*x*x*x/24 - x*x*x*x*x*x/720;
  }
  double _sin(double x) {
    x = x % (2 * 3.14159);
    return x - x*x*x/6 + x*x*x*x*x/120 - x*x*x*x*x*x*x/5040;
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BadgePainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _BadgePainter(this.fill, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fill..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height * 0.75)
      ..lineTo(0, size.height * 0.25)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
