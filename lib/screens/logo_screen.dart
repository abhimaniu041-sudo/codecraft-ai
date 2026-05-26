import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _iconController = TextEditingController(text: '⚡');
  
  Color _primaryColor = const Color(0xFF6C63FF);
  Color _secondaryColor = const Color(0xFF3ECFCF);
  String _selectedStyle = 'gradient';
  bool _logoGenerated = false;

  final List<Map<String, dynamic>> _styles = [
    {'value': 'gradient', 'label': '🌈 Gradient'},
    {'value': 'dark', 'label': '🌙 Dark'},
    {'value': 'neon', 'label': '⚡ Neon'},
    {'value': 'minimal', 'label': '✨ Minimal'},
    {'value': 'bold', 'label': '💪 Bold'},
  ];

  Future<void> _saveLogo() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() 
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo saved: ${file.path}'),
            backgroundColor: const Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
          children: [
            // Brand Name
            _buildInput(_nameController, 'Brand / App Ka Naam', Icons.title),
            const SizedBox(height: 10),
            _buildInput(_taglineController, 'Tagline (optional)', Icons.subtitles),
            const SizedBox(height: 10),
            _buildInput(_iconController, 'Icon / Emoji', Icons.emoji_emotions),
            const SizedBox(height: 10),

            // Colors
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Primary', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showColorPicker(true),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Secondary', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showColorPicker(false),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Style Selector
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _styles.length,
                itemBuilder: (ctx, i) {
                  final style = _styles[i];
                  final isSelected = _selectedStyle == style['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStyle = style['value']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)])
                            : null,
                        color: isSelected ? null : const Color(0xFF12122A),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(style['label'],
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            GestureDetector(
              onTap: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Brand naam daalo!')));
                  return;
                }
                setState(() => _logoGenerated = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Logo Banao',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            if (_logoGenerated) ...[
              const SizedBox(height: 20),
              const Text('Preview:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Logo Preview
              RepaintBoundary(
                key: _repaintKey,
                child: _buildLogoCanvas(),
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: _saveLogo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12122A),
                    border: Border.all(color: const Color(0xFF6C63FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, color: Color(0xFF6C63FF)),
                        SizedBox(width: 8),
                        Text('Logo Save Karo',
                            style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCanvas() {
    final name = _nameController.text.trim().toUpperCase();
    final tagline = _taglineController.text.trim();
    final icon = _iconController.text.trim();

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: _selectedStyle == 'gradient'
            ? LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : _selectedStyle == 'dark' || _selectedStyle == 'neon'
                ? const LinearGradient(colors: [Color(0xFF0A0A14), Color(0xFF12122A)])
                : _selectedStyle == 'minimal'
                    ? const LinearGradient(colors: [Colors.white, Color(0xFFF5F5F5)])
                    : LinearGradient(colors: [_primaryColor, _primaryColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _selectedStyle == 'neon'
            ? [BoxShadow(color: _primaryColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Stack(
        children: [
          // Background circle decoration
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon circle
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(_selectedStyle == 'minimal' ? 0.8 : 0.15),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 12),

                // Brand Name
                Text(
                  name,
                  style: TextStyle(
                    color: _selectedStyle == 'minimal' ? _primaryColor : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: _selectedStyle == 'neon'
                        ? [Shadow(color: _primaryColor, blurRadius: 15)]
                        : [],
                  ),
                ),

                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    tagline,
                    style: TextStyle(
                      color: _selectedStyle == 'minimal' ? Colors.black54 : Colors.white60,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                // Accent line
                Container(
                  width: 60, height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
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

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
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

  void _showColorPicker(bool isPrimary) {
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFF3ECFCF), const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D), const Color(0xFF6BCB77), const Color(0xFF4D96FF),
      const Color(0xFFFF922B), const Color(0xFFCC5DE8), const Color(0xFF20C997),
      const Color(0xFFFF6EB4), Colors.white, Colors.black,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              children: colors.map((c) => GestureDetector(
                onTap: () {
                  setState(() {
                    if (isPrimary) _primaryColor = c;
                    else _secondaryColor = c;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
