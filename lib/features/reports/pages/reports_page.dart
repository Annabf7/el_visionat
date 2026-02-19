import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/utils/test_requirements.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/features/reports/index.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedSeason = '2025-2026'; // Temporada actual per defecte
  String _userCategory = ''; // Categoria de l'àrbitre

  static const _videoBgUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/informes_test%2Floading-bar.mp4?alt=media&token=e3fb2619-3f33-4fc9-89bc-8044c55b4c05';

  late final VideoPlayerController _videoReportsController;
  late final VideoPlayerController _videoTestsController;
  bool _videoReportsReady = false;
  bool _videoTestsReady = false;

  @override
  void initState() {
    super.initState();

    // Inicialitzar dos controllers de vídeo independents (un per cada stat card)
    final uri = Uri.parse(_videoBgUrl);
    _videoReportsController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        _videoReportsController.setLooping(true);
        _videoReportsController.setVolume(0);
        _videoReportsController.play();
        if (mounted) setState(() => _videoReportsReady = true);
      });
    _videoTestsController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        _videoTestsController.setLooping(true);
        _videoTestsController.setVolume(0);
        _videoTestsController.play();
        if (mounted) setState(() => _videoTestsReady = true);
      });

    // Inicialitzar ReportsProvider després que el widget estigui creat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final reportsProvider = context.read<ReportsProvider>();

      if (auth.isAuthenticated && auth.currentUserUid != null) {
        debugPrint(
          '[ReportsPage] Inicialitzant ReportsProvider amb UID: ${auth.currentUserUid}',
        );
        reportsProvider.initialize(auth.currentUserUid!);
        _loadUserCategory(auth.currentUserUid!);
      } else {
        debugPrint(
          '[ReportsPage] Usuari no autenticat, no s\'inicialitza ReportsProvider',
        );
      }
    });
  }

  @override
  void dispose() {
    _videoReportsController.dispose();
    _videoTestsController.dispose();
    super.dispose();
  }

  /// Carrega la categoria de l'usuari des de Firestore
  Future<void> _loadUserCategory(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final category =
            data?['refereeCategory'] as String? ??
            data?['categoriaRrtt'] as String? ??
            '';

        debugPrint('[ReportsPage] Categoria carregada: "$category"');
        debugPrint(
          '[ReportsPage] isAuxiliarDeTaula: ${TestRequirements.isAuxiliarDeTaula(category)}',
        );
        debugPrint(
          '[ReportsPage] isFederacioEspanyolaArbitre: ${TestRequirements.isFederacioEspanyolaArbitre(category)}',
        );

        if (mounted) {
          setState(() {
            _userCategory = category;
          });
        }
      } else {
        debugPrint('[ReportsPage] Document usuari no existeix');
      }
    } catch (e) {
      debugPrint('[ReportsPage] Error carregant categoria: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reportsProvider = context.watch<ReportsProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          // Layout desktop: Menú lateral ocupa tota l'alçada
          return Scaffold(
            key: _scaffoldKey,
            body: Row(
              children: [
                // Menú lateral amb alçada completa
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),

                // Columna dreta amb GlobalHeader + contingut
                Expanded(
                  child: Column(
                    children: [
                      // GlobalHeader només per l'amplada restant
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Informes + Test',
                        showMenuButton: false,
                      ),

                      // Contingut principal
                      Expanded(
                        child: _buildWideLayoutContent(
                          context,
                          auth,
                          reportsProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: const PdfUploadButton(),
          );
        } else {
          // Layout mòbil: comportament tradicional
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                // GlobalHeader amb icona hamburguesa
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'Informes + Test',
                  showMenuButton: true,
                ),

                // Contingut principal
                Expanded(
                  child: _buildNarrowLayout(context, auth, reportsProvider),
                ),
              ],
            ),
            floatingActionButton: const PdfUploadButton(),
          );
        }
      },
    );
  }

  // --- Contingut del Layout Desktop ---
  Widget _buildWideLayoutContent(
    BuildContext context,
    AuthProvider auth,
    ReportsProvider provider,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de temporada + Resum actual
            _buildSeasonSelector(context),
            const SizedBox(height: 24),

            // Cards de resum (estadístiques clau)
            _buildSummaryCards(context, provider),
            const SizedBox(height: 24),

            // Fila: Últims informes i Tests realitzats (50% - 50%)
            SizedBox(
              height: 550,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Últims informes (esquerra)
                  Expanded(
                    flex: 1,
                    child: _buildRecentReports(context, provider),
                  ),
                  const SizedBox(width: 16),
                  // Tests realitzats (dreta)
                  Expanded(
                    flex: 1,
                    child: _buildRecentTests(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Material d'estudi generat
            _buildStudyMaterial(context, provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- Layout Estret (Mòbil) ---
  Widget _buildNarrowLayout(
    BuildContext context,
    AuthProvider auth,
    ReportsProvider provider,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSeasonSelector(context),
            const SizedBox(height: 16),
            _buildSummaryCards(context, provider),
            const SizedBox(height: 16),
            // Alçada fixa per les cards en mòbil
            SizedBox(
              height: 450,
              child: _buildRecentReports(context, provider),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 450, child: _buildRecentTests(context, provider)),
            const SizedBox(height: 16),
            _buildStudyMaterial(context, provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- Widgets de contingut ---

  Widget _buildSeasonSelector(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona la temporada per veure l\'històric',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: _selectedSeason,
                    isExpanded: true,
                    items: ['2025-2026', '2024-2025', '2023-2024']
                        .map(
                          (season) => DropdownMenuItem(
                            value: season,
                            child: Text(season),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeason = value;
                        });
                      }
                    },
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temporada',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona la temporada per veure l\'històric',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _selectedSeason,
                    items: ['2025-2026', '2024-2025', '2023-2024']
                        .map(
                          (season) => DropdownMenuItem(
                            value: season,
                            child: Text(season),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeason = value;
                        });
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.assessment_outlined,
            title: 'Informes',
            value: provider.totalReports.toString(),
            subtitle: 'aquesta temporada',
            videoController: _videoReportsController,
            videoReady: _videoReportsReady,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.quiz_outlined,
            title: 'Tests',
            value: provider.totalTests.toString(),
            subtitle:
                'mitjana ${provider.averageTestScore.toStringAsFixed(1)}/10',
            videoController: _videoTestsController,
            videoReady: _videoTestsReady,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required VideoPlayerController videoController,
    required bool videoReady,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Fons: vídeo o color sòlid mentre carrega
          Positioned.fill(
            child: videoReady
                ? ClipRect(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: videoController.value.size.width,
                        height: videoController.value.size.height,
                        child: VideoPlayer(videoController),
                      ),
                    ),
                  )
                : Container(color: AppTheme.porpraFosc),
          ),
          // Capa fosca semi-transparent per llegibilitat
          Positioned.fill(
            child: Container(
              color: AppTheme.porpraFosc.withValues(alpha: 0.55),
            ),
          ),
          // Contingut
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppTheme.mostassa, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppTheme.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context, ReportsProvider provider) {
    // Comprovar si és categoria FEB/ACB (Federació Espanyola)
    final isFebAcb = TestRequirements.isFederacioEspanyola(_userCategory);

    return _buildDarkSection(
      icon: Icons.description_outlined,
      title: 'Últims Informes',
      subtitle: 'Punts de millora identificats pels informadors',
      badge: 'INFORMES',
      children: [
        // Per FEB/ACB: mostrar NOMÉS el banner (no processem els seus PDFs)
        if (isFebAcb && _userCategory.isNotEmpty) ...[
          Expanded(child: _buildFebAcbReportsBanner(context)),
        ] else ...[
          // Llista d'informes (només per categories FCBQ)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: provider.isLoadingReports
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : provider.recentReports.isEmpty
                        ? _buildPlaceholder('No hi ha informes encara')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estadístiques d'informes (dins del scroll)
                              if (provider.reports.isNotEmpty) ...[
                                _buildReportStats(context, provider),
                                const SizedBox(height: 16),
                              ],
                              // Llista d'informes
                              ...provider.recentReports.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final report = entry.value;
                                final isLast =
                                    index == provider.recentReports.length - 1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 12,
                                  ),
                                  child: ReportCard(
                                    report: report,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReportDetailPage(
                                            report: report,
                                            onDelete: () async {
                                              try {
                                                await provider.deleteReport(
                                                  report.id,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Informe eliminat correctament',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.verdeEncert,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error eliminant informe: $e',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.mostassa,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentTests(BuildContext context, ReportsProvider provider) {
    // Utilitzem _userCategory carregada des de Firestore
    final userCategory = _userCategory;
    // Comprovar si és categoria FEB/ACB (Federació Espanyola)
    final isFebAcb = TestRequirements.isFederacioEspanyola(userCategory);

    return _buildDarkSection(
      icon: Icons.quiz_outlined,
      title: 'Tests Realitzats',
      subtitle: isFebAcb
          ? 'Seguiment de tests'
          : 'Resultats segons normativa FCBQ',
      badge: 'TESTS',
      children: [
        // Per FEB/ACB: mostrar NOMÉS el banner (no processem els seus PDFs)
        if (isFebAcb && userCategory.isNotEmpty) ...[
          Expanded(child: _buildFebAcbTestsBanner(context)),
        ] else ...[
          // Contingut amb scroll (estadístiques + llista)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: provider.isLoadingTests
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estadístiques de tests (dins del scroll)
                              if (provider.tests.isNotEmpty) ...[
                                _buildTestStats(
                                  context,
                                  provider,
                                  userCategory,
                                ),
                                const SizedBox(height: 16),
                              ],
                              // Llista de tests
                              if (provider.recentTests.isEmpty)
                                _buildPlaceholder('No hi ha tests encara')
                              else
                                ...provider.recentTests.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final test = entry.value;
                                  final isLast =
                                      index == provider.recentTests.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 12,
                                    ),
                                    child: TestCard(
                                      test: test,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TestDetailPage(
                                              test: test,
                                              onDelete: () async {
                                                try {
                                                  await provider.deleteTest(
                                                    test.id,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Test eliminat correctament',
                                                        ),
                                                        backgroundColor:
                                                            AppTheme
                                                                .verdeEncert,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error eliminant test: $e',
                                                        ),
                                                        backgroundColor:
                                                            AppTheme.mostassa,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReportStats(BuildContext context, ReportsProvider provider) {
    // Calcular estadístiques de valoracions finals (de millor a pitjor)
    int optims = 0;
    int satisfactoris = 0;
    int millorables = 0;
    int noSatisfactoris = 0;

    for (final report in provider.reports) {
      switch (report.finalGrade) {
        case AssessmentGrade.optim:
          optims++;
          break;
        case AssessmentGrade.satisfactori:
        case AssessmentGrade
            .acceptable: // Dades antigues → tractem com satisfactori
          satisfactoris++;
          break;
        case AssessmentGrade.millorable:
          millorables++;
          break;
        case AssessmentGrade.noSatisfactori:
          noSatisfactoris++;
          break;
      }
    }

    final total = optims + satisfactoris + millorables + noSatisfactoris;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Títol de la secció
          Row(
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 16,
                color: AppTheme.grisPistacho,
              ),
              const SizedBox(width: 8),
              Text(
                'Resum de valoracions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats en fila - 4 columnes
          Row(
            children: [
              // Òptims
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.star,
                  label: 'Òptim',
                  value: optims.toString(),
                  color: AppTheme.verdeEncert,
                ),
              ),
              const SizedBox(width: 6),
              // Satisfactoris
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.thumb_up,
                  label: 'Satisfactori',
                  value: satisfactoris.toString(),
                  color: AppTheme.lilaMitja,
                ),
              ),
              const SizedBox(width: 6),
              // Millorables
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.trending_up,
                  label: 'Millorable',
                  value: millorables.toString(),
                  color: AppTheme.mostassa,
                ),
              ),
              const SizedBox(width: 6),
              // No Satisfactoris
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.warning_amber,
                  label: 'No Satisf.',
                  value: noSatisfactoris.toString(),
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),

          // Barra de progrés visual
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  // Verd - Òptim
                  if (optims > 0)
                    Expanded(
                      flex: optims,
                      child: Container(height: 8, color: AppTheme.verdeEncert),
                    ),
                  // Lila - Satisfactori
                  if (satisfactoris > 0)
                    Expanded(
                      flex: satisfactoris,
                      child: Container(height: 8, color: AppTheme.lilaMitja),
                    ),
                  // Groc - Millorable
                  if (millorables > 0)
                    Expanded(
                      flex: millorables,
                      child: Container(height: 8, color: AppTheme.mostassa),
                    ),
                  // Vermell - No Satisfactori
                  if (noSatisfactoris > 0)
                    Expanded(
                      flex: noSatisfactoris,
                      child: Container(height: 8, color: Colors.redAccent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Llegenda en dues files per espai
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(context, AppTheme.verdeEncert, 'Òptim'),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                      context,
                      AppTheme.lilaMitja,
                      'Satisfactori',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(context, AppTheme.mostassa, 'Millorable'),
                    const SizedBox(width: 12),
                    _buildLegendItem(context, Colors.redAccent, 'No Satisf.'),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestStats(
    BuildContext context,
    ReportsProvider provider,
    String userCategory,
  ) {
    // Nota: Aquest mètode només es crida per categories FCBQ
    // Les categories FEB/ACB mostren el banner directament

    // Calcular estadístiques amb els dos criteris
    int approvedCategory = 0; // Apte per actuar a la categoria
    int approvedAct = 0; // Apte per actuar (més permissiu)
    int notApproved = 0; // No apte

    for (final test in provider.tests) {
      final result = TestRequirements.getTestResult(
        userCategory,
        test.correctAnswers,
        test.totalQuestions,
      );
      if (result.isApprovedForCategory) {
        approvedCategory++;
      } else if (result.isApprovedToAct) {
        approvedAct++;
      } else {
        notApproved++;
      }
    }

    final total = provider.tests.length;
    final minimCategory = TestRequirements.getMinimumRequired(userCategory);
    final minimAct = TestRequirements.getMinimumToAct(userCategory);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoria de l'usuari amb mínims
          if (userCategory.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: AppTheme.grisPistacho,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Categoria: $userCategory',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisPistacho,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mínims en dues línies
            Row(
              children: [
                Expanded(
                  child: Text(
                    '• Mínim categoria: $minimCategory/25',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisPistacho,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '• Mínim actuar: $minimAct/25',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisPistacho,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Stats en fila - 3 columnes
          Row(
            children: [
              // Apte categoria
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.workspace_premium,
                  label: 'Apte cat.',
                  value: approvedCategory.toString(),
                  color: AppTheme.verdeEncert,
                ),
              ),
              const SizedBox(width: 8),
              // Apte actuar
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.check_circle,
                  label: 'Apte actuar',
                  value: approvedAct.toString(),
                  color: AppTheme.lilaMitja,
                ),
              ),
              const SizedBox(width: 8),
              // No apte
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.cancel,
                  label: 'No apte',
                  value: notApproved.toString(),
                  color: AppTheme.mostassa,
                ),
              ),
            ],
          ),

          // Barra de progrés visual
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  // Verd - Apte categoria
                  if (approvedCategory > 0)
                    Expanded(
                      flex: approvedCategory,
                      child: Container(height: 8, color: AppTheme.verdeEncert),
                    ),
                  // Lila - Apte actuar
                  if (approvedAct > 0)
                    Expanded(
                      flex: approvedAct,
                      child: Container(height: 8, color: AppTheme.lilaMitja),
                    ),
                  // Groc - No apte
                  if (notApproved > 0)
                    Expanded(
                      flex: notApproved,
                      child: Container(height: 8, color: AppTheme.mostassa),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Llegenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, AppTheme.verdeEncert, 'Categoria'),
                const SizedBox(width: 16),
                _buildLegendItem(context, AppTheme.lilaMitja, 'Actuar'),
                const SizedBox(width: 16),
                _buildLegendItem(context, AppTheme.mostassa, 'No apte'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Banner informatiu per informes FEB/ACB
  Widget _buildFebAcbReportsBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: AppTheme.lilaMitja),
          const SizedBox(height: 16),
          Text(
            'Categoria $_userCategory',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.lilaMitja,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El sistema d\'avaluació d\'informes per àrbitres d\'aquesta categoria és competència de la Federació Espanyola (FEB).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisPistacho,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquesta funcionalitat està fora de l\'abast d\'aquesta app.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grisPistacho,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner informatiu per tests FEB/ACB
  Widget _buildFebAcbTestsBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: AppTheme.lilaMitja),
          const SizedBox(height: 16),
          Text(
            'Categoria $_userCategory',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.lilaMitja,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El seguiment de mínims i tests per àrbitres d\'aquesta categoria és competència de la Federació Espanyola (FEB).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisPistacho,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquesta funcionalitat està fora de l\'abast d\'aquesta app.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grisPistacho,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grisPistacho,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.grisPistacho),
        ),
      ],
    );
  }

  /// Secció amb fons fosc estil NeuroVisionat pilars
  Widget _buildDarkSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required List<Widget> children,
  }) {
    return Container(
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
            SizedBox(
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.mostassa.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: AppTheme.mostassa,
                              size: 22,
                            ),
                          ),
                        ),
                        const Spacer(),
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
                            badge,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.mostassa.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyMaterial(BuildContext context, ReportsProvider provider) {
    // Comprovar si és àrbitre FEB/ACB (no auxiliar)
    final isFebAcbArbitre = TestRequirements.isFederacioEspanyolaArbitre(
      _userCategory,
    );

    // Per àrbitres FEB/ACB: no mostrem aquesta secció (retornem widget buit)
    if (isFebAcbArbitre && _userCategory.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la secció (estil neuro_tip_card)
        Container(
          decoration: BoxDecoration(
            color: AppTheme.porpraFosc.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 2, color: AppTheme.mostassa),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Material d\'Estudi',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  color: AppTheme.mostassa,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.auto_stories_outlined,
                              color: AppTheme.mostassa,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Contingut generat automàticament segons els teus punts febles',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.white.withValues(alpha: 0.92),
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Contingut
        if (provider.isLoadingTracking)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (provider.topImprovements.isEmpty &&
            provider.topWeakAreas.isEmpty)
          _buildPlaceholder(
            'El material d\'estudi es generarà automàticament quan tinguis informes i tests',
          )
        else if (isWide)
          // Desktop: dues columnes costat a costat
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.topImprovements.isNotEmpty)
                  Expanded(
                    child: _buildStudySubsection(
                      context,
                      icon: Icons.trending_up_rounded,
                      title: 'Punts de Millora Recurrents',
                      accentColor: AppTheme.mostassa,
                      children: provider.topImprovements
                          .take(3)
                          .map((i) => ImprovementItem(improvement: i))
                          .toList(),
                    ),
                  ),
                if (provider.topImprovements.isNotEmpty &&
                    provider.topWeakAreas.isNotEmpty)
                  const SizedBox(width: 20),
                if (provider.topWeakAreas.isNotEmpty)
                  Expanded(
                    child: _buildStudySubsection(
                      context,
                      icon: Icons.report_problem_outlined,
                      title: 'Àrees Febles en Tests',
                      accentColor: Colors.redAccent,
                      children: provider.topWeakAreas
                          .take(3)
                          .map((w) => WeakAreaItem(weakArea: w))
                          .toList(),
                    ),
                  ),
              ],
            ),
          )
        else
          // Mòbil: apilades verticalment
          Column(
            children: [
              if (provider.topImprovements.isNotEmpty)
                _buildStudySubsection(
                  context,
                  icon: Icons.trending_up_rounded,
                  title: 'Punts de Millora Recurrents',
                  accentColor: AppTheme.mostassa,
                  children: provider.topImprovements
                      .take(3)
                      .map((i) => ImprovementItem(improvement: i))
                      .toList(),
                ),
              if (provider.topImprovements.isNotEmpty &&
                  provider.topWeakAreas.isNotEmpty)
                const SizedBox(height: 16),
              if (provider.topWeakAreas.isNotEmpty)
                _buildStudySubsection(
                  context,
                  icon: Icons.report_problem_outlined,
                  title: 'Àrees Febles en Tests',
                  accentColor: Colors.redAccent,
                  children: provider.topWeakAreas
                      .take(3)
                      .map((w) => WeakAreaItem(weakArea: w))
                      .toList(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStudySubsection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
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
            // Cercle decoratiu
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header amb icona i badge
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(icon, color: accentColor, size: 22),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${children.length} DETECTATS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: accentColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Títol
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Barra separadora
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.grisPistacho,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
