import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();

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
            color: AppTheme.mostassa,
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
            color: AppTheme.mostassa,
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
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.grisPistacho),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context, ReportsProvider provider) {
    // Comprovar si és categoria FEB/ACB (Federació Espanyola)
    final isFebAcb = TestRequirements.isFederacioEspanyola(_userCategory);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: AppTheme.lilaMitja),
                  const SizedBox(width: 10),
                  Text(
                    'Últims Informes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Punts de millora identificats pels informadors',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

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
                                          index ==
                                          provider.recentReports.length - 1;
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
                                                      await provider
                                                          .deleteReport(
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
                                                              'Error eliminant informe: $e',
                                                            ),
                                                            backgroundColor:
                                                                AppTheme
                                                                    .mostassa,
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
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTests(BuildContext context, ReportsProvider provider) {
    // Utilitzem _userCategory carregada des de Firestore
    final userCategory = _userCategory;
    // Comprovar si és categoria FEB/ACB (Federació Espanyola)
    final isFebAcb = TestRequirements.isFederacioEspanyola(userCategory);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header fix (no fa scroll)
              Row(
                children: [
                  Icon(Icons.quiz_outlined, color: AppTheme.lilaMitja),
                  const SizedBox(width: 10),
                  Text(
                    'Tests Realitzats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isFebAcb
                    ? 'Seguiment de tests'
                    : 'Resultats segons normativa FCBQ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

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
                                            index ==
                                            provider.recentTests.length - 1;
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
                                                        await provider
                                                            .deleteTest(
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
                                                                  AppTheme
                                                                      .mostassa,
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
          ),
        ),
      ),
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
        case AssessmentGrade.acceptable: // Dades antigues → tractem com satisfactori
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
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.2)),
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
                    _buildLegendItem(context, AppTheme.lilaMitja, 'Satisfactori'),
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
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.2)),
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
        color: AppTheme.lilaMitja.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.3)),
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
        color: AppTheme.lilaMitja.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.3)),
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

  Widget _buildStudyMaterial(BuildContext context, ReportsProvider provider) {
    // Comprovar si és àrbitre FEB/ACB (no auxiliar)
    final isFebAcbArbitre = TestRequirements.isFederacioEspanyolaArbitre(
      _userCategory,
    );

    // Per àrbitres FEB/ACB: no mostrem aquesta secció (retornem widget buit)
    if (isFebAcbArbitre && _userCategory.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Material d\'Estudi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contingut generat automàticament segons els teus punts febles',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Punts de millora més recurrents
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
            else ...[
              // Punts de millora d'informes
              if (provider.topImprovements.isNotEmpty) ...[
                Text(
                  'Punts de Millora Recurrents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.topImprovements
                    .take(3)
                    .map(
                      (improvement) =>
                          ImprovementItem(improvement: improvement),
                    ),
                const SizedBox(height: 24),
              ],
              // Àrees febles en tests
              if (provider.topWeakAreas.isNotEmpty) ...[
                Text(
                  'Àrees Febles en Tests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.topWeakAreas
                    .take(3)
                    .map((weakArea) => WeakAreaItem(weakArea: weakArea)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.3)),
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
