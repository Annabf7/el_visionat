import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/features/profile/models/profile_model.dart';
import '../providers/monthly_battle_provider.dart';
import '../widgets/battle_ranking_widget.dart';

class MonthlyBattlePage extends StatefulWidget {
  const MonthlyBattlePage({super.key});

  @override
  State<MonthlyBattlePage> createState() => _MonthlyBattlePageState();
}

class _MonthlyBattlePageState extends State<MonthlyBattlePage> {
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
      create: (_) => MonthlyBattleProvider()..loadCurrentBattle(),
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
                              title: 'Batalla Mensual',
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
                        title: 'Batalla Mensual',
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
    return Consumer<MonthlyBattleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isPlaying) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mostassa),
          );
        }

        if (provider.errorMessage != null && provider.battle == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  color: AppTheme.mostassa,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (provider.battle == null) {
          return _buildNoBattle(context);
        }

        // Si està jugant, mostrem les preguntes
        if (provider.isPlaying) {
          return _buildBattleInProgress(context, provider);
        }

        // Si ha completat la batalla (acaba de jugar)
        if (provider.isBattleCompleted || provider.hasPlayed) {
          return _buildBattleResult(context, provider);
        }

        // Pantalla d'inici: explicació + botó començar
        return _buildBattleIntro(context, provider);
      },
    );
  }

  /// Quan no hi ha batalla activa
  Widget _buildNoBattle(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 25, 41).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 64,
                color: AppTheme.mostassa.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pròximament...',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'La primera batalla mensual de reglament s\'obrirà aviat. Prepara\'t!',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.mostassa.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tornar al Laboratori',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mostassa,
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Pantalla d'introducció amb regles i botó de començar
  Widget _buildBattleIntro(
    BuildContext context,
    MonthlyBattleProvider provider,
  ) {
    final battle = provider.battle!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16,
                            color: AppTheme.mostassa,
                          ),
                          const SizedBox(width: 4),
                          const Text(
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
                // Icona trofeu
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mostassa.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 40,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Títol
                Text(
                  battle.title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${battle.daysRemaining} dies restants',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppTheme.mostassa.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),

                // Regles
                _buildRuleItem(
                  Icons.quiz_rounded,
                  '10 preguntes',
                  'Casos de reglament i interpretacions oficials',
                ),
                _buildRuleItem(
                  Icons.timer_rounded,
                  'Cronòmetre global',
                  'El temps total compta per al desempat al rànquing',
                ),
                _buildRuleItem(
                  Icons.block_rounded,
                  'Un sol intent',
                  'No es pot repetir — cada resposta compta!',
                ),
                _buildRuleItem(
                  Icons.leaderboard_rounded,
                  'Rànquing global',
                  'Competeix contra tots els àrbitres del Visionat',
                ),

                const SizedBox(height: 16),

                // Info participants
                if (battle.participantCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 18,
                          color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${battle.participantCount} participants',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Botó començar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.startBattle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa,
                      foregroundColor: AppTheme.porpraFosc,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Començar Batalla',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.porpraFosc,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.mostassa, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla de joc: pregunta + opcions + cronòmetre global
  Widget _buildBattleInProgress(
    BuildContext context,
    MonthlyBattleProvider provider,
  ) {
    final question = provider.currentQuestion;
    if (question == null) return const SizedBox();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 25, 41).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Capçalera: cronòmetre global + progrés
              Row(
                children: [
                  // Cronòmetre global
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.porpraFosc,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.mostassa.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 18,
                          color: AppTheme.mostassa,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.elapsedFormatted,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.mostassa,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Step dots de progrés
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(provider.questions.length, (i) {
                      final isCurrent = i == provider.currentQuestionIndex;
                      final isDone = i < provider.currentQuestionIndex;
                      return Container(
                        width: isCurrent ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isCurrent
                              ? AppTheme.mostassa
                              : isDone
                              ? AppTheme.verdeEncert
                              : AppTheme.white.withValues(alpha: 0.15),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Targeta de pregunta
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.porpraFosc,
                      AppTheme.porpraFosc.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.porpraFosc.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.mostassa.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Badge source
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mostassa.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    question.articleNumber > 0
                                        ? 'ART. ${question.articleNumber}'
                                        : question.category.name.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppTheme.mostassa.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${provider.currentQuestionIndex + 1} / ${provider.questions.length}',
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: AppTheme.grisPistacho.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.mostassa.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question.question,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Opcions
              ...List.generate(question.options.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < question.options.length - 1 ? 12 : 0,
                  ),
                  child: _BattleOptionCard(
                    letter: String.fromCharCode(65 + index),
                    text: question.options[index],
                    isSelected: provider.selectedOptionIndex == index,
                    isCorrect: index == question.correctOptionIndex,
                    showResult: provider.showExplanation,
                    onTap: () {
                      if (!provider.showExplanation) {
                        provider.answerQuestion(index);
                      }
                    },
                  ),
                );
              }),

              // Explicació i botó següent
              if (provider.showExplanation) ...[
                const SizedBox(height: 24),
                _BattleExplanationCard(
                  isCorrect: provider.isAnswerCorrect,
                  explanation: question.explanation,
                  reference: question.articleNumber > 0
                      ? 'Art. ${question.articleNumber} - ${question.articleTitle}'
                      : question.reference,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => provider.nextQuestion(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa,
                      foregroundColor: AppTheme.porpraFosc,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      provider.currentQuestionIndex <
                              provider.questions.length - 1
                          ? 'Següent pregunta'
                          : 'Veure resultats',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Vista de resultats amb puntuació, temps i rànquing
  Widget _buildBattleResult(
    BuildContext context,
    MonthlyBattleProvider provider,
  ) {
    final result = provider.userResult;
    if (result == null) return const SizedBox();

    final percentage = result.score / 10;
    final position = provider.getUserPosition();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 25, 41).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
            children: [
              const SizedBox(height: 16),

              // Cercle animat de puntuació
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percentage),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          color: _getScoreColor(percentage),
                          backgroundColor: AppTheme.white.withValues(
                            alpha: 0.08,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${result.score}/10',
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.white,
                                ),
                              ),
                              Text(
                                result.formattedTime,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 13,
                                  color: AppTheme.grisPistacho.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Títol
              const Text(
                'Batalla Completada!',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 8),

              // Posició al rànquing
              if (position != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Posició #$position de ${provider.ranking.length}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Rànquing
              if (provider.ranking.isNotEmpty)
                BattleRankingWidget(
                  ranking: provider.ranking,
                  currentUserId: result.userId,
                ),

              const SizedBox(height: 24),

              // Botó tornar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.mostassa.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Tornar al Laboratori',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.7) return AppTheme.verdeEncert;
    if (percentage >= 0.5) return AppTheme.mostassa;
    return Colors.redAccent;
  }
}

/// Targeta d'opció de la batalla
class _BattleOptionCard extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _BattleOptionCard({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color letterBgColor;
    Color letterColor;
    Color textColor = AppTheme.white.withValues(alpha: 0.9);

    if (showResult) {
      if (isCorrect) {
        bgColor = AppTheme.verdeEncert.withValues(alpha: 0.15);
        borderColor = AppTheme.verdeEncert;
        letterBgColor = AppTheme.verdeEncert;
        letterColor = Colors.white;
      } else if (isSelected) {
        bgColor = Colors.redAccent.withValues(alpha: 0.15);
        borderColor = Colors.redAccent;
        letterBgColor = Colors.redAccent;
        letterColor = Colors.white;
      } else {
        bgColor = AppTheme.white.withValues(alpha: 0.03);
        borderColor = AppTheme.white.withValues(alpha: 0.08);
        letterBgColor = AppTheme.white.withValues(alpha: 0.06);
        letterColor = AppTheme.grisPistacho.withValues(alpha: 0.4);
        textColor = AppTheme.grisPistacho.withValues(alpha: 0.4);
      }
    } else {
      bgColor = AppTheme.white.withValues(alpha: 0.04);
      borderColor = AppTheme.mostassa.withValues(alpha: 0.25);
      letterBgColor = AppTheme.mostassa.withValues(alpha: 0.12);
      letterColor = AppTheme.mostassa;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: showResult ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: letterBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: letterColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.verdeEncert,
                  size: 22,
                ),
              if (showResult && isSelected && !isCorrect)
                const Icon(
                  Icons.cancel_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panell d'explicació de la batalla
class _BattleExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final String reference;

  const _BattleExplanationCard({
    required this.isCorrect,
    required this.explanation,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isCorrect ? AppTheme.verdeEncert : Colors.redAccent;
    final headerText = isCorrect ? 'Correcte!' : 'Incorrecte';
    final headerIcon = isCorrect
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accentColor.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(headerIcon, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          headerText,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.white.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reference,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppTheme.mostassa.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
