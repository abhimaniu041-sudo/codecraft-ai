import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class CVScreen extends StatefulWidget {
  const CVScreen({super.key});
  @override
  State<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends State<CVScreen> {
  final GlobalKey _cvKey = GlobalKey();
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
  bool _saving = false;

  final List<Map<String, dynamic>> _templates = [
    {'value': 'modern', 'label': '🎯 Modern', 'primary': const Color(0xFF6C63FF), 'secondary': const Color(0xFF3ECFCF), 'dark': false},
    {'value': 'executive', 'label': '💼 Executive', 'primary': const Color(0xFF1A237E), 'secondary': const Color(0xFF283593), 'dark': false},
    {'value': 'creative', 'label': '🎨 Creative', 'primary': const Color(0xFFE91E63), 'secondary': const Color(0xFFFF5722), 'dark': false},
    {'value': 'minimal', 'label': '✨ Minimal', 'primary': const Color(0xFF212121), 'secondary': const Color(0xFF757575), 'dark': false},
    {'value': 'tech', 'label': '💻 Tech', 'primary': const Color(0xFF00C853), 'secondary': const Color(0xFF1B5E20), 'dark': true},
    {'value': 'elegant', 'label': '👑 Elegant', 'primary': const Color(0xFFB8860B), 'secondary': const Color(0xFF8B6914), 'dark': true},
  ];

  Map<String, dynamic> get _currentTemplate =>
      _templates.firstWhere((t) => t['value'] == _selectedTemplate);

  Future<void> _saveAsImage() async {
    if (!_cvGenerated) return;
    setState(() => _saving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final boundary = _cvKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Render error');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image null');
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final name = _nameCtrl.text.trim().replaceAll(' ', '_');
      final file = File('${dir.path}/${name}_CV_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12122A),
            title: const Text('CV Saved! ✅', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file, height: 200, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text('CV image save ho gayi!', style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _buildTextCV()));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ CV text bhi copy ho gaya!'), backgroundColor: Color(0xFF6C63FF)));
                },
                child: const Text('Copy Text', style: TextStyle(color: Color(0xFF3ECFCF))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Color(0xFF6C63FF))),
              ),
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

  String _buildTextCV() {
    return '''${_nameCtrl.text.trim().toUpperCase()}
${_jobCtrl.text.trim()}
${_phoneCtrl.text.trim()} | ${_emailCtrl.text.trim()} | ${_addressCtrl.text.trim()}

OBJECTIVE
${_objectiveCtrl.text.trim()}

EDUCATION
${_educationCtrl.text.trim()}

EXPERIENCE
${_experienceCtrl.text.trim()}

SKILLS
${_skillsCtrl.text.trim()}

LANGUAGES
${_languagesCtrl.text.trim()}''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: const Row(children: [
          Icon(Icons.description, color: Color(0xFF6C63FF)),
          SizedBox(width: 10),
          Text('CV Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template selector
            const Text('Template:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                itemBuilder: (ctx, i) {
                  final t = _templates[i];
                  final sel = _selectedTemplate == t['value'];
                  return GestureDetector(
                    onTap: () => setState(() { _selectedTemplate = t['value']; if (_cvGenerated) setState(() {}); }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? t['primary'] : const Color(0xFF12122A),
                        border: Border.all(color: sel ? t['primary'] : Colors.white12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(t['label'], style: TextStyle(color: sel ? Colors.white : Colors.grey, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            _buildSection('👤 Personal Info', [
              _field(_nameCtrl, 'Full Name *', Icons.person),
              _field(_dobCtrl, 'Date of Birth', Icons.cake),
              _field(_phoneCtrl, 'Phone', Icons.phone),
              _field(_emailCtrl, 'Email', Icons.email),
              _field(_addressCtrl, 'City / Address', Icons.location_on),
              _field(_jobCtrl, 'Job Title / Profession', Icons.work),
            ]),
            const SizedBox(height: 12),
            _buildSection('🎯 Objective', [_fieldMulti(_objectiveCtrl, 'Career objective...')]),
            const SizedBox(height: 12),
            _buildSection('🎓 Education', [_fieldMulti(_educationCtrl, 'e.g. 12th Pass, ABC School, 2022')]),
            const SizedBox(height: 12),
            _buildSection('💼 Experience', [_fieldMulti(_experienceCtrl, 'e.g. IT Support, Hotel, 5 months')]),
            const SizedBox(height: 12),
            _buildSection('⚡ Skills', [_fieldMulti(_skillsCtrl, 'Flutter, Python, HTML...')]),
            const SizedBox(height: 12),
            _buildSection('🌐 Languages', [_fieldMulti(_languagesCtrl, 'Hindi, English, Punjabi')]),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam zaroori hai!')));
                  return;
                }
                setState(() => _cvGenerated = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_currentTemplate['primary'], _currentTemplate['secondary']]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 8),
                    Text('CV Generate Karo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )),
              ),
            ),

            if (_cvGenerated) ...[
              const SizedBox(height: 20),
              const Text('Preview:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RepaintBoundary(
                key: _cvKey,
                child: _buildVisualCV(),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _buildTextCV()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copy ho gaya!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12122A),
                        border: Border.all(color: _currentTemplate['primary']),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy, color: _currentTemplate['primary'], size: 18),
                          const SizedBox(width: 6),
                          Text('Copy', style: TextStyle(color: _currentTemplate['primary'])),
                        ],
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving ? null : _saveAsImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_currentTemplate['primary'], _currentTemplate['secondary']]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Save Image', style: TextStyle(color: Colors.white)),
                              ],
                            )),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisualCV() {
    final t = _currentTemplate;
    final Color primary = t['primary'];
    final Color secondary = t['secondary'];
    final bool isDark = t['dark'];
    final name = _nameCtrl.text.trim().toUpperCase();
    final job = _jobCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final dob = _dobCtrl.text.trim();
    final objective = _objectiveCtrl.text.trim();
    final education = _educationCtrl.text.trim();
    final experience = _experienceCtrl.text.trim();
    final skills = _skillsCtrl.text.trim();
    final languages = _languagesCtrl.text.trim();

    if (_selectedTemplate == 'modern') {
      return _modernTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    } else if (_selectedTemplate == 'executive') {
      return _executiveTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    } else if (_selectedTemplate == 'creative') {
      return _creativeTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    } else if (_selectedTemplate == 'tech') {
      return _techTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    } else if (_selectedTemplate == 'elegant') {
      return _elegantTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    } else {
      return _minimalTemplate(primary, secondary, name, job, phone, email, address, dob, objective, education, experience, skills, languages);
    }
  }

  // MODERN TEMPLATE
  Widget _modernTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p, s], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0] : 'A',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      if (job.isNotEmpty) Text(job, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contact bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: p.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (phone.isNotEmpty) _contactChip(Icons.phone, phone, p),
                if (email.isNotEmpty) _contactChip(Icons.email, email, p),
                if (address.isNotEmpty) _contactChip(Icons.location_on, address, p),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (obj.isNotEmpty) _cvSectionModern('OBJECTIVE', obj, p),
                if (edu.isNotEmpty) _cvSectionModern('EDUCATION', edu, p),
                if (exp.isNotEmpty) _cvSectionModern('EXPERIENCE', exp, p),
                if (skills.isNotEmpty) _skillsSection(skills, p),
                if (lang.isNotEmpty) _cvSectionModern('LANGUAGES', lang, p),
                if (dob.isNotEmpty) _cvSectionModern('DATE OF BIRTH', dob, p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // EXECUTIVE TEMPLATE
  Widget _executiveTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar
          Container(
            width: 130,
            decoration: BoxDecoration(
              color: p,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0] : 'A',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 16),
                _sidebarSection('CONTACT', [
                  if (phone.isNotEmpty) phone,
                  if (email.isNotEmpty) email,
                  if (address.isNotEmpty) address,
                  if (dob.isNotEmpty) dob,
                ]),
                const SizedBox(height: 12),
                if (skills.isNotEmpty) _sidebarSection('SKILLS',
                    skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()),
                const SizedBox(height: 12),
                if (lang.isNotEmpty) _sidebarSection('LANGUAGES',
                    lang.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()),
              ],
            ),
          ),
          // Right content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: p, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (job.isNotEmpty) Text(job, style: TextStyle(color: s, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(height: 3, width: 60, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [p, s]),
                    borderRadius: BorderRadius.circular(2),
                  )),
                  const SizedBox(height: 12),
                  if (obj.isNotEmpty) _rightSection('PROFESSIONAL SUMMARY', obj, p),
                  if (exp.isNotEmpty) _rightSection('WORK EXPERIENCE', exp, p),
                  if (edu.isNotEmpty) _rightSection('EDUCATION', edu, p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CREATIVE TEMPLATE
  Widget _creativeTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Creative header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p, s], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0] : 'A',
                      style: TextStyle(color: p, fontSize: 36, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                if (job.isNotEmpty) Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(job, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (phone.isNotEmpty) _whiteChip('📞 $phone'),
                    if (email.isNotEmpty) _whiteChip('✉ $email'),
                    if (address.isNotEmpty) _whiteChip('📍 $address'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (obj.isNotEmpty) _creativeSection('About Me', obj, p),
                if (exp.isNotEmpty) _creativeSection('Experience', exp, p),
                if (edu.isNotEmpty) _creativeSection('Education', edu, p),
                if (skills.isNotEmpty) _creativeSkills(skills, p),
                if (lang.isNotEmpty) _creativeSection('Languages', lang, p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TECH TEMPLATE
  Widget _techTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border.all(color: p, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p, width: 2),
                    color: p.withOpacity(0.1),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0] : 'A',
                      style: TextStyle(color: p, fontSize: 26, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: p, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      if (job.isNotEmpty) Text('> $job', style: TextStyle(color: s, fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _techInfo('phone', phone, p),
                _techInfo('email', email, p),
                _techInfo('location', address, p),
                _techInfo('dob', dob, p),
                const SizedBox(height: 12),
                if (obj.isNotEmpty) _techSection('objective', obj, p, s),
                if (exp.isNotEmpty) _techSection('experience', exp, p, s),
                if (edu.isNotEmpty) _techSection('education', edu, p, s),
                if (skills.isNotEmpty) _techSection('skills', skills, p, s),
                if (lang.isNotEmpty) _techSection('languages', lang, p, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ELEGANT TEMPLATE
  Widget _elegantTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF2D2000), const Color(0xFF1A1200)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
            ),
            child: Column(
              children: [
                Text('— ✦ —', style: TextStyle(color: p, fontSize: 16)),
                const SizedBox(height: 8),
                Text(name, style: TextStyle(color: p, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3)),
                if (job.isNotEmpty) Text(job, style: TextStyle(color: s.withOpacity(0.8), fontSize: 13, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('— ✦ —', style: TextStyle(color: p, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    if (phone.isNotEmpty) Text(phone, style: TextStyle(color: p.withOpacity(0.8), fontSize: 11)),
                    if (email.isNotEmpty) Text(email, style: TextStyle(color: p.withOpacity(0.8), fontSize: 11)),
                    if (address.isNotEmpty) Text(address, style: TextStyle(color: p.withOpacity(0.8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (obj.isNotEmpty) _elegantSection('OBJECTIVE', obj, p),
                if (exp.isNotEmpty) _elegantSection('EXPERIENCE', exp, p),
                if (edu.isNotEmpty) _elegantSection('EDUCATION', edu, p),
                if (skills.isNotEmpty) _elegantSection('SKILLS', skills, p),
                if (lang.isNotEmpty) _elegantSection('LANGUAGES', lang, p),
                if (dob.isNotEmpty) _elegantSection('DATE OF BIRTH', dob, p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MINIMAL TEMPLATE
  Widget _minimalTemplate(Color p, Color s, String name, String job, String phone, String email, String address, String dob, String obj, String edu, String exp, String skills, String lang) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: const Color(0xFF212121), fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1)),
          if (job.isNotEmpty) Text(job, style: const TextStyle(color: Color(0xFF757575), fontSize: 14)),
          const SizedBox(height: 8),
          Container(height: 2, color: const Color(0xFF212121)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
              if (email.isNotEmpty) Text(email, style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
              if (address.isNotEmpty) Text(address, style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          if (obj.isNotEmpty) _minimalSection('SUMMARY', obj),
          if (exp.isNotEmpty) _minimalSection('EXPERIENCE', exp),
          if (edu.isNotEmpty) _minimalSection('EDUCATION', edu),
          if (skills.isNotEmpty) _minimalSection('SKILLS', skills),
          if (lang.isNotEmpty) _minimalSection('LANGUAGES', lang),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _contactChip(IconData icon, String text, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 10), overflow: TextOverflow.ellipsis),
    ],
  );

  Widget _whiteChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
  );

  Widget _cvSectionModern(String title, String content, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 4, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        ]),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Color(0xFF333333), fontSize: 12, height: 1.4)),
        const Divider(color: Color(0xFFEEEEEE)),
      ],
    ),
  );

  Widget _skillsSection(String skills, Color color) {
    final list = skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
            Text('SKILLS', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: list.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(s, style: TextStyle(color: color, fontSize: 11)),
            )).toList(),
          ),
          const Divider(color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _sidebarSection(String title, List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 4),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 9), overflow: TextOverflow.ellipsis),
      )),
    ],
  );

  Widget _rightSection(String title, String content, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        Container(height: 1, color: color.withOpacity(0.3), margin: const EdgeInsets.symmetric(vertical: 4)),
        Text(content, style: const TextStyle(color: Color(0xFF333333), fontSize: 11, height: 1.4)),
      ],
    ),
  );

  Widget _creativeSection(String title, String content, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.star, color: Colors.white, size: 12)),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(color: Color(0xFF444444), fontSize: 12, height: 1.4)),
      ],
    ),
  );

  Widget _creativeSkills(String skills, Color color) {
    final list = skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.flash_on, color: Colors.white, size: 12)),
            const SizedBox(width: 8),
            Text('SKILLS', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: list.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _techInfo(String key, String value, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('const ', style: TextStyle(color: color.withOpacity(0.6), fontSize: 11, fontFamily: 'monospace')),
        Text('$key', style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        const Text(' = ', style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
        Expanded(child: Text('"$value"', style: const TextStyle(color: Color(0xFF98C379), fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _techSection(String key, String value, Color p, Color s) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('// $key', style: TextStyle(color: s, fontSize: 12, fontFamily: 'monospace')),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace', height: 1.4)),
        const SizedBox(height: 4),
      ],
    ),
  );

  Widget _elegantSection(String title, String content, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      children: [
        Row(children: [
          Expanded(child: Divider(color: color.withOpacity(0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(title, style: TextStyle(color: color, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Divider(color: color.withOpacity(0.3))),
        ]),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, height: 1.4), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _minimalSection(String title, String content) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.4)),
      ],
    ),
  );

  Widget _buildSection(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF12122A),
      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        filled: true, fillColor: const Color(0xFF0A0A14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6C63FF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );

  Widget _fieldMulti(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    maxLines: 3,
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      filled: true, fillColor: const Color(0xFF0A0A14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C63FF))),
    ),
  );
}
