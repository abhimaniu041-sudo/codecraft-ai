import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ai_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CodeGeneratorScreen extends StatefulWidget {
  const CodeGeneratorScreen({super.key});

  @override
  State<CodeGeneratorScreen> createState() => _CodeGeneratorScreenState();
}

class _CodeGeneratorScreenState extends State<CodeGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _selectedType = 'Android App';
  String _generatedCode = '';
  bool _isLoading = false;
  bool _hasResult = false;

  final List<String> _types = [
    'Android App',
    'Web App',
    'Game',
    'Website',
    'Landing Page',
    'Calculator',
    'Todo App',
    'Custom',
  ];

  Future<void> _generateCode() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batao kya banana hai!')),
      );
      return;
    }

    setState(() { _isLoading = true; _hasResult = false; });

    final systemPrompt = '''Aap ek expert developer ho. User jo chahta hai uska complete code banao.
- Agar Web/Game/Website: Single complete HTML file do (CSS+JS included)
- Agar Android App: Complete Flutter/Dart code do with all files
- Beautiful modern UI
- Fully functional code
- Proper comments in Hindi/English
Sirf code return karo, explanation mat do.''';

    final userPrompt = 'Type: $_selectedType\nRequest: $prompt\n\nComplete working code banao.';

    try {
      final result = await AIService.sendMessage(
        userMessage: userPrompt,
        systemPrompt: systemPrompt,
        maxTokens: 4096,
      );
      setState(() {
        _generatedCode = result.replaceAll('```html', '').replaceAll('```dart', '').replaceAll('```', '').trim();
        _isLoading = false;
        _hasResult = true;
      });
    } catch (e) {
      setState(() {
        _generatedCode = 'Error: $e';
        _isLoading = false;
        _hasResult = true;
      });
    }
  }

  Future<void> _downloadCode() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = _selectedType.contains('Web') || _selectedType.contains('Game') || _selectedType.contains('Website') ? 'html' : 'dart';
      final file = File('${dir.path}/codecraft_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsString(_generatedCode);
      await Share.shareXFiles([XFile(file.path)], text: 'CodeCraft AI se generate hua code');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            Icon(Icons.code, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('Code Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF12122A),
                  style: const TextStyle(color: Colors.white),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Prompt Input
            TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe karo kya banana hai...\nExample: Ek colorful snake game banao with score',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF12122A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('AI Code Bana Raha Hai...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Code Generate Karo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            if (_hasResult) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Generated Code:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedCode));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copy ho gaya!')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF3ECFCF)),
                    onPressed: _downloadCode,
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _generatedCode,
                    style: const TextStyle(color: Color(0xFF7FFF7F), fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
