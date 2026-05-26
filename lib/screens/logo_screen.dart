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

class _LogoScreenState extends State<LogoScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _symbolCtrl = TextEditingController(text: 'CA');

  Color _primary = const Color(0xFF6C63FF);
  Color _secondary = const Color(0xFF3ECFCF);
  String _style = 'gradient';
  String _shape = 'circle';
  bool _generated = false;
  bool _saving = false;

  final List<Map<String, dynamic>> _styles = [
    {'v': 'gradient', 'l': '🌈 Gradient'},
    {'v': 'dark', 'l': '🌙 Dark'},
    {'v': 'neon', 'l': '⚡ Neon'},
    {'v': 'minimal', 'l': '✨ Minimal'},
    {'v': 'gold', 'l': '🏆 Gold'},
    {'v': 'fire', 'l': '🔥 Fire'},
  ];

  final List<Map<String, dynamic>> _shapes = [
    {'v': 'circle', 'l': '⭕ Circle'},
    {'v': 'square', 'l': '⬛ Square'},
    {'v': 'hexagon', 'l': '⬡ Hexagon'},
    {'v': 'shield', 'l': '🛡 Shield'},
  ];

  final List<Color> _colors = [
    const Color(0xFF6C63FF), const Color(0xFF3ECFCF),
    const Color(0xFFFF6B6B), const Color(0xFFFFD93D),
    const Color(0xFF6BCB77), const Color(0xFF4D96FF),
    const Color(0xFFFF922B), const Color(0xFFCC5DE8),
    const Color(0xFFFFD700), const Color(0xFFFF1744),
    const Color(0xFF00BCD4), Colors.white,
  ];

  Future<void> _saveLogo() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Logo render nahi hua');

      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image data null');

      final Uint8List bytes = byteData.buffer.asUint8List();

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Pictures');
        if (!await dir.exists()) {
          dir = Directory('/storage/emulated/0/Download');
        }
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final name = _nameCtrl.text.trim().replaceAll(' ', '_');
      final fileName = '${name}_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Logo Gallery/Pictures mein save hua!'),
            backgroundColor: const Color(0xFF6C63FF),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: const Row(
          children: [
            Icon(Icons.brush, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('Logo Creator',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
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
            _input(_symbolCtrl, 'Logo Text / Initials (e.g. CA, Nike, AS)', Icons.text_fields),
            const SizedBox(height: 14),

            // Colors
            _label('🎨 Colors'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Column(
                  children: [
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
                        ),
                        child: const Center(child: Icon(Icons.colorize, color: Colors.white54, size: 20)),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  children: [
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
                        ),
                        child: const Center(child: Icon(Icons.colorize, color: Colors.white54, size: 20)),
                      ),
                    ),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 14),

            _label('🎭 Style'),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _styles.map((s) {
                  final sel = _style == s['v'];
                  return GestureDetector(
                    onTap: () => setState(() { _style = s['v']; if (_generated) setState(() {}); }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]) : null,
                        color: sel ? null : const Color(0xFF12122A),
                        border: Border.all(color: sel ? Colors.transparent : Colors.white12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s['l'], style: TextStyle(color: sel ? Colors.white : Colors.grey, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            _label('🔷 Shape'),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _shapes.map((s) {
                  final sel = _shape == s['v'];
                  return GestureDetector(
                    onTap: () => setState(() { _shape = s['v']; if (_generated) setState(() {}); }),
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
              ),
            ),
            const SizedBox(height: 20),

            // Generate
            GestureDetector(
              onTap: () {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Brand naam daalo!')));
                  return;
                }
                setState(() => _generated = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Logo Banao', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            if (_generated) ...[
              const SizedBox(height: 24),
              const Center(child: Text('Preview:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),

              Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildLogo(),
                ),
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: _saving ? null : _saveLogo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _saving ? Colors.grey : null,
                    gradient: _saving ? null : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _saving
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Saving...', style: TextStyle(color: Colors.white)),
                          ])
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.download, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Gallery mein Save Karo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                  ),
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

    Color bg1, bg2, textColor, symbolColor;
    List<BoxShadow> shadows = [];

    switch (_style) {
      case 'dark':
        bg1 = const Color(0xFF0A0A14);
        bg2 = const Color(0xFF1A1A2E);
        textColor = Colors.white;
        symbolColor = _primary;
        break;
      case 'neon':
        bg1 = Colors.black;
        bg2 = const Color(0xFF0D0D1A);
        textColor = _primary;
        symbolColor = _secondary;
        shadows = [BoxShadow(color: _primary.withOpacity(0.8), blurRadius: 20, spreadRadius: 3)];
        break;
      case 'minimal':
        bg1 = Colors.white;
        bg2 = const Color(0xFFF8F8FF);
        textColor = _primary;
        symbolColor = _secondary;
        break;
      case 'gold':
        bg1 = const Color(0xFF1A1400);
        bg2 = const Color(0xFF2D2200);
        textColor = const Color(0xFFFFD700);
        symbolColor = const Color(0xFFFFA500);
        shadows = [const BoxShadow(color: Color(0x80FFD700), blurRadius: 15, spreadRadius: 2)];
        break;
      case 'fire':
        bg1 = const Color(0xFF1A0000);
        bg2 = const Color(0xFF2D0A00);
        textColor = const Color(0xFFFF6B35);
        symbolColor = const Color(0xFFFFD93D);
        shadows = [const BoxShadow(color: Color(0x80FF4500), blurRadius: 20, spreadRadius: 3)];
        break;
      default:
        bg1 = _primary;
        bg2 = _secondary;
        textColor = Colors.white;
        symbolColor = Colors.white;
    }

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(right: -20, top: -20,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withOpacity(0.1)))),
          Positioned(left: -15, bottom: -15,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _secondary.withOpacity(0.1)))),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Symbol container
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: _shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: _shape == 'square' ? BorderRadius.circular(16)
                        : _shape == 'hexagon' ? BorderRadius.circular(12)
                        : _shape == 'shield' ? const BorderRadius.only(
                            topLeft: Radius.circular(50), topRight: Radius.circular(50),
                            bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                        : null,
                    gradient: LinearGradient(
                      colors: [_primary.withOpacity(0.3), _secondary.withOpacity(0.3)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: symbolColor.withOpacity(0.6), width: 2),
                    boxShadow: shadows,
                  ),
                  child: Center(
                    child: Text(
                      symbol.length > 3 ? symbol.substring(0, 3) : symbol,
                      style: TextStyle(
                        color: symbolColor,
                        fontSize: symbol.length == 1 ? 52 : symbol.length == 2 ? 38 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: _style == 'neon' || _style == 'gold' || _style == 'fire'
                            ? [Shadow(color: symbolColor.withOpacity(0.8), blurRadius: 10)]
                            : [],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand name
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: name.length > 10 ? 18 : name.length > 6 ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: _style == 'neon' || _style == 'gold' || _style == 'fire'
                        ? [Shadow(color: textColor.withOpacity(0.8), blurRadius: 8)]
                        : [],
                  ),
                ),

                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(tagline,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                // Accent line
                Container(
                  width: 50, height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primary, _secondary]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));

  Widget _input(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) { if (_generated) setState(() {}); },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF12122A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
    );
  }

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
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _colors.map((c) => GestureDetector(
                onTap: () {
                  setState(() { isPrimary ? _primary = c : _secondary = c; });
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
