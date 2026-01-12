import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
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
      } else {
        debugPrint(
          '[ReportsPage] Usuari no autenticat, no s\'inicialitza ReportsProvider',
        );
      }
    });
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
              height: 600,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Últims informes (esquerra)
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: _buildRecentReports(context, provider),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tests realitzats (dreta)
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: _buildRecentTests(context, provider),
                    ),
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
            _buildRecentReports(context, provider),
            const SizedBox(height: 16),
            _buildRecentTests(context, provider),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
              ],
            ),
            DropdownButton<String>(
              value: _selectedSeason,
              items: [
                '2025-2026',
                '2024-2025',
                '2023-2024',
              ]
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
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.quiz_outlined,
            title: 'Tests',
            value: provider.totalTests.toString(),
            subtitle: 'mitjana ${provider.averageTestScore.toStringAsFixed(1)}/10',
            color: const Color(0xFF50C878),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.trending_up,
            title: 'Millores',
            value: provider.totalImprovementPoints.toString(),
            subtitle: 'punts actius',
            color: const Color(0xFFE8C547),
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context, ReportsProvider provider) {
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
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
            const SizedBox(height: 20),
            // Llista d'informes
            if (provider.isLoadingReports)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.recentReports.isEmpty)
              _buildPlaceholder('No hi ha informes encara')
            else
              ...provider.recentReports.map(
                (report) => ReportCard(
                  report: report,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailPage(report: report),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTests(BuildContext context, ReportsProvider provider) {
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
                  Icons.quiz_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
              'Historial de tests amb preguntes conflictives',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Llista de tests
            if (provider.isLoadingTests)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.recentTests.isEmpty)
              _buildPlaceholder('No hi ha tests encara')
            else
              ...provider.recentTests.map(
                (test) => TestCard(
                  test: test,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestDetailPage(test: test),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyMaterial(BuildContext context, ReportsProvider provider) {
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                ...provider.topImprovements.take(3).map(
                      (improvement) => ImprovementItem(
                        improvement: improvement,
                      ),
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
                ...provider.topWeakAreas.take(3).map(
                      (weakArea) => WeakAreaItem(
                        weakArea: weakArea,
                      ),
                    ),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
