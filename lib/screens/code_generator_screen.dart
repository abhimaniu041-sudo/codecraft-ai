import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

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

    final systemPrompt = '''Aap ek expert developer ho jo exact file paths aur complete code deta hai.

RULES — HAMESHA FOLLOW KARO:
1. Har file ko alag alag do is format mein:

## FILE 1/X
Path: `exact/file/path/filename.ext`
\`\`\`language
[complete file code]
\`\`\`

## FILE 2/X
Path: `exact/file/path/filename.ext`
\`\`\`language
[complete file code]
\`\`\`

2. Pehle project structure batao:
project-name/
├── file1
├── folder/
│   └── file2

3. Har file COMPLETE honi chahiye — koi "..." ya placeholder nahi
4. Flutter/Android ke liye: pubspec.yaml + main.dart + saari screens alag alag
5. Web ke liye: index.html (CSS+JS same file mein)
6. Game ke liye: single HTML file mein sab kuch
7. Beautiful modern dark UI with gradients
8. Fully working code — copy paste karke seedha kaam kare

KABHI MAT KARO:
- Explanation mat do
- Sirf code do file by file
- "Aap yeh kar sakte ho" type text mat likho''';

    final userPrompt = 'Type: $_selectedType\nRequest: $prompt\n\nComplete working code banao.';

    try {
      final result = await AIService.sendMessage(
        userMessage: userPrompt,
        systemPrompt: systemPrompt,
        maxTokens: 4096,
      );
      setState(() {
        _generatedCode = result
            .replaceAll('```html', '')
            .replaceAll('```dart', '')
            .replaceAll('```', '')
            .trim();
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
            Text('Code Generator',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Kya banana hai describe karo...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12122A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
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
            GestureDetector(
              onTap: _isLoading ? null : _generateCode,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('AI Bana Raha Hai...',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Code Generate Karo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                ),
              ),
            ),
            if (_hasResult) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Generated Code:',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copy ho gaya!')));
                    },
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _generatedCode,
                    style: const TextStyle(
                        color: Color(0xFF7FFF7F),
                        fontSize: 12,
                        fontFamily: 'monospace'),
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
