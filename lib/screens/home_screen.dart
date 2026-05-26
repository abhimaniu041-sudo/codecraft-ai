import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'code_generator_screen.dart';
import 'error_fixer_screen.dart';
import 'logo_screen.dart';
import 'cv_screen.dart';
import 'video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const CodeGeneratorScreen(),
    const ErrorFixerScreen(),
    const LogoScreen(),
    const CVScreen(),
    const VideoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline, size: 22), activeIcon: Icon(Icons.chat_bubble, size: 22), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.code_outlined, size: 22), activeIcon: Icon(Icons.code, size: 22), label: 'Code'),
            BottomNavigationBarItem(icon: Icon(Icons.bug_report_outlined, size: 22), activeIcon: Icon(Icons.bug_report, size: 22), label: 'Fix'),
            BottomNavigationBarItem(icon: Icon(Icons.brush_outlined, size: 22), activeIcon: Icon(Icons.brush, size: 22), label: 'Logo'),
            BottomNavigationBarItem(icon: Icon(Icons.description_outlined, size: 22), activeIcon: Icon(Icons.description, size: 22), label: 'CV'),
            BottomNavigationBarItem(icon: Icon(Icons.movie_outlined, size: 22), activeIcon: Icon(Icons.movie, size: 22), label: 'Video'),
          ],
        ),
      ),
    );
  }
}
