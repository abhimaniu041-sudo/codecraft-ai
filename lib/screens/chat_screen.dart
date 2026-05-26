import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chat_history');
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(() {
        _messages.addAll(decoded.map((e) => Map<String, String>.from(e)));
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() => _messages.clear());
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .sublist(0, _messages.length - 1)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final reply = await AIService.sendMessage(
        userMessage: text,
        systemPrompt: '''Aap CodeCraft AI ho — ek expert, friendly aur smart AI assistant.
Aap Hindi aur English dono mein baat karte ho.
Aap code, apps, websites, games banane mein expert ho.
Jab user code maange toh complete working code do.
Markdown use karo — **bold**, bullet points, code blocks sab.
Hamesha helpful, detailed aur clear jawab do.''',
        history: history.length > 20 ? history.sublist(history.length - 20) : history,
        maxTokens: 4096,
      );

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
      await _saveHistory();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
        _isLoading = false;
      });
      await _saveHistory();
    }
  }

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          );
        } else if (line.startsWith('* ') || line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(color: Color(0xFF6C63FF), fontSize: 14)),
                Expanded(
                  child: Text(
                    line.substring(2).replaceAll('**', ''),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        } else if (line.startsWith('```') || line.endsWith('```')) {
          return const SizedBox.shrink();
        } else if (line.trim().isEmpty) {
          return const SizedBox(height: 6);
        } else {
          final boldPattern = RegExp(r'\*\*(.*?)\*\*');
          if (boldPattern.hasMatch(line)) {
            final spans = <TextSpan>[];
            int lastEnd = 0;
            for (final match in boldPattern.allMatches(line)) {
              if (match.start > lastEnd) {
                spans.add(TextSpan(
                  text: line.substring(lastEnd, match.start),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ));
              }
              spans.add(TextSpan(
                text: match.group(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ));
              lastEnd = match.end;
            }
            if (lastEnd < line.length) {
              spans.add(TextSpan(
                text: line.substring(lastEnd),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ));
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: RichText(text: TextSpan(children: spans)),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(line,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.4)),
          );
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('AI Chat',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF12122A),
                title: const Text('Chat Clear Karo?',
                    style: TextStyle(color: Colors.white)),
                content: const Text('Saari history delete ho jayegi.',
                    style: TextStyle(color: Colors.grey)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey))),
                  TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTyping();
                      final msg = _messages[index];
                      return _buildBubble(
                          msg['content']!, msg['role'] == 'user');
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('CodeCraft AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Aapka personal AI assistant — App, Website, Game sab banao!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _sectionTitle('🚀 Quick Actions'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _quickBtn('🎮 Snake game banao'),
                _quickBtn('📱 Todo app banao'),
                _quickBtn('🌐 Portfolio website'),
                _quickBtn('💡 Python code explain karo'),
                _quickBtn('🎨 Logo ideas do'),
                _quickBtn('🔧 Flutter error fix karo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _quickBtn(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A35),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5555EE)])
              : null,
          color: isUser ? null : const Color(0xFF1A1A2E),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withOpacity(0.08)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('🤖 ', style: TextStyle(fontSize: 12)),
                    Text('CodeCraft AI',
                        style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            isUser
                ? Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5))
                : _buildFormattedText(text),
            if (!isUser)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Copy ho gaya!'),
                            duration: Duration(seconds: 1)));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.copy, color: Colors.grey, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF6C63FF)),
            ),
            SizedBox(width: 10),
            Text('CodeCraft AI soch raha hai...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Kuch bhi puchho...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0A0A14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
