import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import 'dart:io';

class ErrorFixerScreen extends StatefulWidget {
  const ErrorFixerScreen({super.key});

  @override
  State<ErrorFixerScreen> createState() => _ErrorFixerScreenState();
}

class _ErrorFixerScreenState extends State<ErrorFixerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _errorController = TextEditingController();
  File? _screenshot;
  String _fixedCode = '';
  bool _isLoading = false;
  bool _hasResult = false;

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _screenshot = File(picked.path));
    }
  }

  Future<void> _fixError() async {
    final code = _codeController.text.trim();
    final error = _errorController.text.trim();

    if (code.isEmpty && error.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code ya error message daalo!')),
      );
      return;
    }

    setState(() { _isLoading = true; _hasResult = false; });

    final prompt = '''Code mein error hai, fix karo:

CODE:
$code

ERROR:
$error

1. Error ka karan batao
2. Fixed complete code do
3. Kya change kiya batao''';

    try {
      final result = await AIService.sendMessage(
        userMessage: prompt,
        systemPrompt: 'Aap expert debugger ho. Code fix karo aur clear explanation do Hindi/English mein.',
        maxTokens: 4096,
      );
      setState(() {
        _fixedCode = result;
        _isLoading = false;
        _hasResult = true;
      });
    } catch (e) {
      setState(() {
        _fixedCode = 'Error: $e';
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
            Icon(Icons.bug_report, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('Error Fixer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                height: _screenshot != null ? 180 : 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  border: Border.all(
                    color: _screenshot != null
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF6C63FF).withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _screenshot != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_screenshot!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: Color(0xFF6C63FF), size: 32),
                          SizedBox(height: 8),
                          Text('Error Screenshot Upload Karo',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _errorController,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Error message paste karo...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12122A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Apna code paste karo jisme error hai...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12122A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isLoading ? null : _fixError,
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
                            Text('AI Fix Kar Raha Hai...',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_fix_high, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Error Fix Karo',
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
                  const Text('Fixed Code:',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fixedCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copy ho gaya!')));
                    },
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _fixedCode,
                    style: const TextStyle(
                        color: Color(0xFF7FFF7F), fontSize: 12, height: 1.5),
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
