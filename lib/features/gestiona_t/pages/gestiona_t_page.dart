import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/weekly_calendar_view.dart';
import '../widgets/weekly_grid_view.dart';
import '../widgets/day_timeblocks_list.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/nightly_planner_sheet.dart';
import '../widgets/timeblock_editor_dialog.dart';
import '../models/time_block.dart';

/// Tipus de vista disponibles
enum ViewMode { list, grid }

/// Pàgina principal de Gestiona't - Planificació personal per àrbitres
class GestionaTPage extends StatefulWidget {
  const GestionaTPage({super.key});

  @override
  State<GestionaTPage> createState() => _GestionaTPageState();
}

class _GestionaTPageState extends State<GestionaTPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSummary = true;
  ViewMode _viewMode = ViewMode.grid; // Per defecte, vista graella

  @override
  void initState() {
    super.initState();
    // Inicialitza el provider amb l'UID de l'usuari
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUserUid != null) {
        context.read<ScheduleProvider>().initialize(auth.currentUserUid!);
      }
    });
  }

  void _openNightlyPlanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NightlyPlannerSheet(),
    );
  }

  void _openNewBlockEditor() {
    final provider = context.read<ScheduleProvider>();
    final now = DateTime.now();
    final selectedDay = provider.selectedDay;

    // Per defecte, el nou bloc comença a l'hora actual arrodonida
    final startAt = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      now.hour,
      (now.minute ~/ 15) * 15, // Arrodoneix a 15 minuts
    );
    final endAt = startAt.add(const Duration(hours: 1));

    final newBlock = TimeBlock(
      title: '',
      category: TimeBlockCategory.feina,
      priority: TimeBlockPriority.mitja,
      startAt: startAt,
      endAt: endAt,
    );

    showDialog(
      context: context,
      builder: (context) => TimeblockEditorDialog(block: newBlock, isNew: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 288, child: SideNavigationMenu()),
                Expanded(
                  child: Column(
                    children: [
                      const GlobalHeader(showMenuButton: false),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFAB(),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(scaffoldKey: _scaffoldKey, showMenuButton: true),
                Expanded(child: _buildContent()),
              ],
            ),
            floatingActionButton: _buildFAB(),
          );
        }
      },
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FAB per afegir bloc
        FloatingActionButton(
          heroTag: 'add_block',
          onPressed: _openNewBlockEditor,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 12),
        // FAB per planificar demà
        FloatingActionButton.extended(
          heroTag: 'plan_tomorrow',
          onPressed: _openNightlyPlanner,
          icon: const Text('🌙', style: TextStyle(fontSize: 20)),
          label: const Text('Planifica demà'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.weekBlocks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    final auth = context.read<AuthProvider>();
                    if (auth.currentUserUid != null) {
                      provider.initialize(auth.currentUserUid!);
                    }
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Títol i controls
              Row(
                children: [
                  Text(
                    "Gestiona't",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Toggle de vista
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.porpraFosc,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggle(
                          icon: Icons.view_list,
                          label: 'Llista',
                          isSelected: _viewMode == ViewMode.list,
                          onTap: () =>
                              setState(() => _viewMode = ViewMode.list),
                        ),
                        _buildViewToggle(
                          icon: Icons.calendar_view_week,
                          label: 'Setmana',
                          isSelected: _viewMode == ViewMode.grid,
                          onTap: () =>
                              setState(() => _viewMode = ViewMode.grid),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botó per mostrar/ocultar el resum (només en vista llista)
                  if (_viewMode == ViewMode.list)
                    IconButton(
                      icon: Icon(
                        _showSummary ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() => _showSummary = !_showSummary);
                      },
                      tooltip: _showSummary ? 'Amagar resum' : 'Mostrar resum',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Contingut segons la vista seleccionada
              Expanded(
                child: _viewMode == ViewMode.grid
                    ? const WeeklyGridView()
                    : _buildListView(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.mostassa : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.porpraFosc : AppTheme.grisPistacho,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.porpraFosc : AppTheme.grisPistacho,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(ScheduleProvider provider) {
    return Column(
      children: [
        // Calendari setmanal compacte
        const WeeklyCalendarView(),
        const SizedBox(height: 16),

        // Resum setmanal (plegable)
        if (_showSummary) ...[
          const WeeklySummaryCard(),
          const SizedBox(height: 16),
        ],

        // Llista de blocs del dia seleccionat
        Expanded(
          child: DayTimeblocksList(
            blocks: provider.selectedDayBlocks,
            selectedDay: provider.selectedDay,
          ),
        ),
      ],
    );
  }
}
