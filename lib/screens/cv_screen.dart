import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CVScreen extends StatefulWidget {
  const CVScreen({super.key});

  @override
  State<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends State<CVScreen> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();

  String _selectedTemplate = 'modern';
  bool _cvGenerated = false;
  String _cvContent = '';

  final List<Map<String, dynamic>> _templates = [
    {'value': 'modern', 'label': '🎯 Modern', 'color': const Color(0xFF6C63FF)},
    {'value': 'classic', 'label': '📄 Classic', 'color': const Color(0xFF2C3E50)},
    {'value': 'creative', 'label': '🎨 Creative', 'color': const Color(0xFFE74C3C)},
    {'value': 'minimal', 'label': '✨ Minimal', 'color': const Color(0xFF27AE60)},
    {'value': 'professional', 'label': '💼 Pro', 'color': const Color(0xFF2980B9)},
  ];

  String _buildCV() {
    final name = _nameCtrl.text.trim().toUpperCase();
    final job = _jobCtrl.text.trim();
    final dob = _dobCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final objective = _objectiveCtrl.text.trim();
    final education = _educationCtrl.text.trim();
    final experience = _experienceCtrl.text.trim();
    final skills = _skillsCtrl.text.trim();
    final languages = _languagesCtrl.text.trim();

    if (_selectedTemplate == 'modern') {
      return '''
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  $name
  ${job.isNotEmpty ? job : 'Professional'}
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

CONTACT
═══════════════════════════
${phone.isNotEmpty ? '📞 $phone' : ''}
${email.isNotEmpty ? '✉  $email' : ''}
${address.isNotEmpty ? '📍 $address' : ''}
${dob.isNotEmpty ? '🎂 $dob' : ''}

OBJECTIVE
═══════════════════════════
${objective.isNotEmpty ? objective : 'Seeking a challenging position to utilize my skills.'}

EDUCATION
═══════════════════════════
${education.isNotEmpty ? education : 'N/A'}

EXPERIENCE
═══════════════════════════
${experience.isNotEmpty ? experience : 'Fresher'}

SKILLS
═══════════════════════════
${skills.isNotEmpty ? skills.split(',').map((s) => '▸ ${s.trim()}').join('\n') : 'N/A'}

LANGUAGES
═══════════════════════════
${languages.isNotEmpty ? languages.split(',').map((s) => '▸ ${s.trim()}').join('\n') : '▸ Hindi\n▸ English'}
''';
    } else if (_selectedTemplate == 'classic') {
      return '''
========================================
           CURRICULUM VITAE
========================================

NAME    : $name
TITLE   : ${job.isNotEmpty ? job : 'Professional'}
DOB     : ${dob.isNotEmpty ? dob : 'N/A'}
PHONE   : ${phone.isNotEmpty ? phone : 'N/A'}
EMAIL   : ${email.isNotEmpty ? email : 'N/A'}
ADDRESS : ${address.isNotEmpty ? address : 'N/A'}

----------------------------------------
CAREER OBJECTIVE
----------------------------------------
${objective.isNotEmpty ? objective : 'To obtain a position where I can contribute effectively.'}

----------------------------------------
EDUCATIONAL QUALIFICATION
----------------------------------------
${education.isNotEmpty ? education : 'N/A'}

----------------------------------------
WORK EXPERIENCE
----------------------------------------
${experience.isNotEmpty ? experience : 'Fresher / No prior experience'}

----------------------------------------
KEY SKILLS
----------------------------------------
${skills.isNotEmpty ? skills.split(',').map((s) => '  * ${s.trim()}').join('\n') : 'N/A'}

----------------------------------------
LANGUAGES KNOWN
----------------------------------------
${languages.isNotEmpty ? languages.split(',').map((s) => '  * ${s.trim()}').join('\n') : '  * Hindi\n  * English'}

========================================
''';
    } else if (_selectedTemplate == 'creative') {
      return '''
╭─────────────────────────────────────╮
│  ★  $name  ★
│  ${job.isNotEmpty ? job : 'Creative Professional'}
╰─────────────────────────────────────╯

◆ ABOUT ME
${objective.isNotEmpty ? objective : 'A passionate professional seeking growth.'}

◆ CONTACT DETAILS
  ▷ Phone   : ${phone.isNotEmpty ? phone : 'N/A'}
  ▷ Email   : ${email.isNotEmpty ? email : 'N/A'}
  ▷ Address : ${address.isNotEmpty ? address : 'N/A'}
  ▷ DOB     : ${dob.isNotEmpty ? dob : 'N/A'}

◆ EDUCATION
${education.isNotEmpty ? education : 'N/A'}

◆ WORK HISTORY
${experience.isNotEmpty ? experience : 'Open to first opportunity!'}

◆ MY SKILLS
${skills.isNotEmpty ? skills.split(',').map((s) => '  ✓ ${s.trim()}').join('\n') : 'N/A'}

◆ LANGUAGES
${languages.isNotEmpty ? languages.split(',').map((s) => '  ✓ ${s.trim()}').join('\n') : '  ✓ Hindi\n  ✓ English'}
''';
    } else if (_selectedTemplate == 'minimal') {
      return '''
$name
${job.isNotEmpty ? job : 'Professional'}
─────────────────────────────────────

${phone.isNotEmpty ? phone : ''} | ${email.isNotEmpty ? email : ''} | ${address.isNotEmpty ? address : ''}

─────────────────────────────────────
SUMMARY
─────────────────────────────────────
${objective.isNotEmpty ? objective : 'Motivated professional with a drive to succeed.'}

─────────────────────────────────────
EDUCATION
─────────────────────────────────────
${education.isNotEmpty ? education : 'N/A'}

─────────────────────────────────────
EXPERIENCE
─────────────────────────────────────
${experience.isNotEmpty ? experience : 'Entry level'}

─────────────────────────────────────
SKILLS & LANGUAGES
─────────────────────────────────────
${skills.isNotEmpty ? skills : 'N/A'}
${languages.isNotEmpty ? languages : 'Hindi, English'}
''';
    } else {
      return '''
┌─────────────────────────────────────┐
│        PROFESSIONAL RESUME          │
└─────────────────────────────────────┘

$name
${job.isNotEmpty ? job : 'Professional'}

PERSONAL INFORMATION
────────────────────
Name         : ${_nameCtrl.text.trim()}
Date of Birth: ${dob.isNotEmpty ? dob : 'N/A'}
Phone        : ${phone.isNotEmpty ? phone : 'N/A'}
Email        : ${email.isNotEmpty ? email : 'N/A'}
Location     : ${address.isNotEmpty ? address : 'N/A'}

PROFESSIONAL SUMMARY
────────────────────
${objective.isNotEmpty ? objective : 'Results-driven professional seeking to leverage skills.'}

EDUCATION
────────────────────
${education.isNotEmpty ? education : 'N/A'}

PROFESSIONAL EXPERIENCE
────────────────────
${experience.isNotEmpty ? experience : 'Fresher'}

CORE COMPETENCIES
────────────────────
${skills.isNotEmpty ? skills.split(',').map((s) => '• ${s.trim()}').join('\n') : 'N/A'}

LANGUAGES
────────────────────
${languages.isNotEmpty ? languages.split(',').map((s) => '• ${s.trim()}').join('\n') : '• Hindi\n• English'}

└─────────────────────────────────────┘
''';
    }
  }

  void _generateCV() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Naam zaroori hai!')));
      return;
    }
    setState(() {
      _cvContent = _buildCV();
      _cvGenerated = true;
    });
  }

  Future<void> _downloadCV() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${_nameCtrl.text.trim().replaceAll(' ', '_')}_CV.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(_cvContent);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF12122A),
          title: const Text('CV Ready! ✅',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CV copy karke kahi bhi paste karo:',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _cvContent));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ CV clipboard mein copy ho gaya! WhatsApp ya Notes mein paste karo.'),
                      backgroundColor: Color(0xFF6C63FF),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Copy to Clipboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      Clipboard.setData(ClipboardData(text: _cvContent));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ CV copy ho gaya! Paste karo jahan chahiye.'),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    }
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
            Icon(Icons.description, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('CV Generator',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Selector
            const Text('Template Choose Karo:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                itemBuilder: (ctx, i) {
                  final t = _templates[i];
                  final isSelected = _selectedTemplate == t['value'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedTemplate = t['value'];
                      if (_cvGenerated) _cvContent = _buildCV();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? t['color'] : const Color(0xFF12122A),
                        border: Border.all(
                          color: isSelected ? t['color'] : const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(t['label'],
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            _buildSection('👤 Personal Info', [
              _field(_nameCtrl, 'Full Name *', Icons.person),
              _field(_dobCtrl, 'Date of Birth (DD/MM/YYYY)', Icons.cake),
              _field(_phoneCtrl, 'Phone Number', Icons.phone),
              _field(_emailCtrl, 'Email Address', Icons.email),
              _field(_addressCtrl, 'City / Address', Icons.location_on),
              _field(_jobCtrl, 'Job Title / Profession', Icons.work),
            ]),
            const SizedBox(height: 12),
            _buildSection('🎯 Objective', [
              _fieldMulti(_objectiveCtrl, 'Career objective ya summary likho...'),
            ]),
            const SizedBox(height: 12),
            _buildSection('🎓 Education', [
              _fieldMulti(_educationCtrl, 'e.g. 12th Pass, ABC School, 2022'),
            ]),
            const SizedBox(height: 12),
            _buildSection('💼 Experience', [
              _fieldMulti(_experienceCtrl, 'e.g. IT Support, Marriott Hotel, 5 months'),
            ]),
            const SizedBox(height: 12),
            _buildSection('⚡ Skills', [
              _fieldMulti(_skillsCtrl, 'Comma se alag karo: Flutter, Python...'),
            ]),
            const SizedBox(height: 12),
            _buildSection('🌐 Languages', [
              _fieldMulti(_languagesCtrl, 'e.g. Hindi, English, Punjabi'),
            ]),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _generateCV,
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
                      Text('CV Generate Karo',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            if (_cvGenerated) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_cvContent,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12,
                        fontFamily: 'monospace', height: 1.6)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _cvContent));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CV copy ho gaya!')));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12122A),
                          border: Border.all(color: const Color(0xFF6C63FF)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, color: Color(0xFF6C63FF), size: 18),
                              SizedBox(width: 6),
                              Text('Copy', style: TextStyle(color: Color(0xFF6C63FF))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _downloadCV,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Download', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
              color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
          filled: true,
          fillColor: const Color(0xFF0A0A14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6C63FF)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _fieldMulti(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0A0A14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
    );
  }
}
