import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/features/profile/models/profile_model.dart';
import 'quiz_page.dart';

class QuizSetupPage extends StatefulWidget {
  const QuizSetupPage({super.key});

  @override
  State<QuizSetupPage> createState() => _QuizSetupPageState();
}

class _QuizSetupPageState extends State<QuizSetupPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _articleController = TextEditingController();

  int _questionCount = 10;
  String _selectedMode =
      'mix'; // 'mix', 'reglament', 'interpretacions', 'failed'
  String? _gender;

  static const String _bgMan =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_manQuiz.webp?alt=media&token=5a3fe7f8-e43b-4708-9eea-4ae7e13639c0';
  static const String _bgWoman =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_womenQuiz.webp?alt=media&token=ef55e3f1-7432-48ec-bd0e-02f05743a09b';

  String get _backgroundUrl => _gender == 'male' ? _bgMan : _bgWoman;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  @override
  void dispose() {
    _articleController.dispose();
    super.dispose();
  }

  Future<void> _loadGender() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final profile = ProfileModel.fromMap(doc.data()!);
        if (mounted) setState(() => _gender = profile.gender);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    _backgroundUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.grisBody),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: AppTheme.grisBody.withValues(alpha: 0.55),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 288,
                      height: double.infinity,
                      child: SideNavigationMenu(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          GlobalHeader(
                            scaffoldKey: _scaffoldKey,
                            title: 'Configuració del Test',
                            showMenuButton: false,
                          ),
                          Expanded(child: _buildSetupContent(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.black,
            drawer: const SideNavigationMenu(),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    _backgroundUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.grisBody),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: AppTheme.grisBody.withValues(alpha: 0.35),
                  ),
                ),
                Column(
                  children: [
                    GlobalHeader(
                      scaffoldKey: _scaffoldKey,
                      title: 'Configuració del Test',
                      showMenuButton: true,
                    ),
                    Expanded(child: _buildSetupContent(context)),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSetupContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personalitza el teu entrenament',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Nombre de Preguntes'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCountOption(10)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCountOption(25)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCountOption(50)),
                ],
              ),

              const SizedBox(height: 32),

              _buildSectionTitle('Enfocament'),
              const SizedBox(height: 12),
              _buildModeSelector(),

              const SizedBox(height: 32),

              // Selector d'Article (només visible si no estem en mode "failed")
              if (_selectedMode != 'failed') ...[
                _buildSectionTitle('Article Específic (Opcional)'),
                const SizedBox(height: 8),
                Text(
                  "Escriu el número (ex: 33) per practicar només aquest article.",
                  style: TextStyle(
                    color: AppTheme.grisPistacho.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _articleController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppTheme.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: 17',
                    hintStyle: TextStyle(
                      color: AppTheme.grisPistacho.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.porpraFosc,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mostassa,
                    foregroundColor: AppTheme.porpraFosc,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'COMENÇAR TEST',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountOption(int value) {
    final isSelected = _questionCount == value;
    return GestureDetector(
      onTap: () => setState(() => _questionCount = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.mostassa : AppTheme.porpraFosc,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.mostassa : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              color: isSelected ? AppTheme.porpraFosc : AppTheme.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        _buildModeOption(
          id: 'mix',
          title: 'Tot Barrejat',
          subtitle: 'Preguntes de reglament i interpretacions.',
          icon: Icons.shuffle,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          id: 'reglament',
          title: 'Només Reglament',
          subtitle: 'Centrat en el llibre de regles.',
          icon: Icons.menu_book,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          id: 'interpretacions',
          title: 'Interpretacions',
          subtitle: 'Situacions i casos pràctics.',
          icon: Icons.lightbulb,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          id: 'failed',
          title: 'Els meus errors',
          subtitle: 'Repassa les preguntes que més falles.',
          icon: Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _selectedMode = id;
          if (id == 'failed') _articleController.clear();
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.mostassa.withOpacity(0.1)
                : AppTheme.porpraFosc,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.mostassa : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.mostassa : AppTheme.grisPistacho,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.mostassa : AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.grisPistacho,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.mostassa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.mostassa,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  void _startQuiz() {
    String? source;
    bool retryFailed = false;
    int? articleNumber;

    if (_selectedMode == 'reglament') source = 'reglament';
    if (_selectedMode == 'interpretacions') source = 'interpretacions';
    if (_selectedMode == 'failed') retryFailed = true;

    if (_articleController.text.isNotEmpty) {
      articleNumber = int.tryParse(_articleController.text);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizPage(
          limit: _questionCount,
          source: source, // null means mixed
          articleNumber: articleNumber,
          retryFailed: retryFailed,
          gender: _gender,
        ),
      ),
    );
  }
}
