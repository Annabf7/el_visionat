import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/features/profile/models/profile_model.dart';
import '../providers/progress_provider.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _bgMan =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_manQuiz.webp?alt=media&token=5a3fe7f8-e43b-4708-9eea-4ae7e13639c0';
  static const String _bgWoman =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_womenQuiz.webp?alt=media&token=ef55e3f1-7432-48ec-bd0e-02f05743a09b';

  String? _gender;

  String get _backgroundUrl => _gender == 'male' ? _bgMan : _bgWoman;

  @override
  void initState() {
    super.initState();
    _loadGender();
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
    return ChangeNotifierProvider(
      create: (_) => ProgressProvider()..loadAll(),
      child: LayoutBuilder(
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
                              title: 'El meu progrés',
                              showMenuButton: false,
                            ),
                            Expanded(child: _buildContent(context)),
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
                        title: 'El meu progrés',
                        showMenuButton: true,
                      ),
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.mostassa),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          provider.errorMessage!,
          style: const TextStyle(
            fontFamily: 'Geist',
            color: AppTheme.white,
            fontSize: 16,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                20,
                25,
                41,
              ).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botó tornar
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16,
                            color: AppTheme.mostassa,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tornar',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mostassa,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Títol
                const Text(
                  'El meu progrés',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estadístiques del Laboratori Arbitral',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppTheme.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Secció 1: Resum general
                _buildSummaryCards(provider),
                const SizedBox(height: 32),

                // Secció 2: Última batalla
                if (provider.lastBattleResult != null) ...[
                  _buildBattleSection(provider),
                  const SizedBox(height: 32),
                ],

                // Secció 3: Rendiment per article
                if (provider.articleStats.isNotEmpty) ...[
                  _buildArticleSection(provider),
                  const SizedBox(height: 32),
                ],

                // Missatge si no hi ha dades
                if (provider.totalAnswers == 0) _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3 cards amb les estadístiques principals
  Widget _buildSummaryCards(ProgressProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Preguntes',
            value: '${provider.totalAnswers}',
            icon: Icons.quiz_outlined,
            color: AppTheme.mostassa,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Encerts',
            value: provider.totalAnswers > 0
                ? '${provider.accuracyPercent.toStringAsFixed(0)}%'
                : '-',
            icon: Icons.check_circle_outline,
            color: _accuracyColor(provider.accuracyPercent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Ratxa',
            value: '${provider.streak}',
            icon: Icons.local_fire_department_outlined,
            color: provider.streak >= 5
                ? AppTheme.verdeEncert
                : AppTheme.mostassa,
          ),
        ),
      ],
    );
  }

  /// Secció batalla mensual
  Widget _buildBattleSection(ProgressProvider provider) {
    final result = provider.lastBattleResult!;
    final position = provider.lastBattlePosition;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.porpraFosc.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.mostassa,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.lastBattleTitle ?? 'Batalla mensual',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BattleStatChip(
                label: 'Puntuació',
                value: '${result.score}/10',
                color: _scoreColor(result.score),
              ),
              const SizedBox(width: 10),
              _BattleStatChip(
                label: 'Temps',
                value: result.formattedTime,
                color: AppTheme.grisPistacho,
              ),
              if (position != null) ...[
                const SizedBox(width: 10),
                _BattleStatChip(
                  label: 'Posició',
                  value: '#$position',
                  color: position <= 3
                      ? AppTheme.mostassa
                      : AppTheme.grisPistacho,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Secció rendiment per article
  Widget _buildArticleSection(ProgressProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rendiment per article',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Percentatge d\'encert per cada article treballat',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppTheme.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...provider.articleStats.map((stat) => _ArticleRow(stat: stat)),
      ],
    );
  }

  /// Estat buit quan no hi ha dades
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: AppTheme.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Encara no has respost cap pregunta',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comença un entrenament setmanal o juga la batalla mensual per veure el teu progrés aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppTheme.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(double percent) {
    if (percent >= 75) return AppTheme.verdeEncert;
    if (percent >= 50) return AppTheme.mostassa;
    return Colors.redAccent;
  }

  Color _scoreColor(int score) {
    if (score >= 8) return AppTheme.verdeEncert;
    if (score >= 5) return AppTheme.mostassa;
    return Colors.redAccent;
  }
}

// ---------------------------------------------------------------------------
// Widgets privats
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BattleStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final ArticleStat stat;

  const _ArticleRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Número d'article
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  stat.articleNumber,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Barra de progrés
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Article ${stat.articleNumber}',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stat.accuracyPercent / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Percentatge i comptador
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stat.accuracyPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '${stat.correctAnswers}/${stat.totalAnswers}',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppTheme.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    if (stat.accuracyPercent >= 75) return AppTheme.verdeEncert;
    if (stat.accuracyPercent >= 50) return AppTheme.mostassa;
    return Colors.redAccent;
  }
}
