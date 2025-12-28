import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';
import '../services/pdf_parser_service.dart';
import '../services/tariff_calculator_service.dart';
import '../widgets/designations_tab_view.dart';
import '../widgets/earnings_summary_widget.dart';
import '../widgets/category_stats_widget.dart';

/// Pàgina principal de designacions arbitrals
class DesignationsPage extends StatefulWidget {
  const DesignationsPage({super.key});

  @override
  State<DesignationsPage> createState() => _DesignationsPageState();
}

class _DesignationsPageState extends State<DesignationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = DesignationsRepository();

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Gestiona la càrrega d'un PDF de designació
  Future<void> _handlePdfUpload() async {
    try {
      // Seleccionar fitxer PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No s\'ha pogut llegir el fitxer'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Parsejar el PDF
      final matches = await PdfParserService.parsePdfDesignationFromBytes(fileBytes);

      if (matches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No s\'han trobat partits al PDF'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Processar cada partit trobat
      int successCount = 0;
      int duplicateCount = 0;

      for (final matchData in matches) {
        final date = PdfParserService.parseDate(
          matchData['date']!,
          matchData['time']!,
        );

        if (date == null) continue;

        // Comprovar si el partit ja existeix
        final exists = await _repository.designationExists(
          matchData['matchNumber']!,
          date,
        );

        if (exists) {
          duplicateCount++;
          continue;
        }

        // Calcular quilometratge (podríem implementar càlcul automàtic amb Google Maps API)
        // Per ara, posem 0 i l'usuari ho pot editar després
        const kilometers = 0.0;

        // Calcular ingressos
        final earnings = TariffCalculatorService.calculateEarnings(
          category: matchData['category']!,
          role: matchData['role']!,
          kilometers: kilometers,
          matchDate: date,
          matchTime: matchData['time']!,
        );

        // Crear designació
        final designation = DesignationModel(
          id: '',
          date: date,
          category: matchData['category']!,
          competition: matchData['competition']!,
          role: matchData['role']!,
          matchNumber: matchData['matchNumber']!,
          localTeam: matchData['localTeam']!,
          visitantTeam: matchData['visitantTeam']!,
          location: matchData['location']!,
          locationAddress: matchData['locationAddress']!,
          kilometers: kilometers,
          earnings: earnings,
          createdAt: DateTime.now(),
        );

        // Guardar a Firestore
        final designationId = await _repository.createDesignation(designation);

        if (designationId != null) {
          // Pujar PDF a Storage
          await _repository.uploadPdfFromBytes(fileBytes, designationId);
          successCount++;
        }
      }

      if (mounted) {
        // Construir missatge segons resultats
        String message = '';
        Color backgroundColor = Colors.green;

        if (successCount > 0 && duplicateCount == 0) {
          message = '$successCount ${successCount == 1 ? "partit processat" : "partits processats"} correctament';
        } else if (successCount > 0 && duplicateCount > 0) {
          message = '$successCount ${successCount == 1 ? "partit processat" : "partits processats"} correctament. '
              '$duplicateCount ${duplicateCount == 1 ? "duplicat omès" : "duplicats omesos"}.';
        } else if (successCount == 0 && duplicateCount > 0) {
          message = 'Tots els partits ($duplicateCount) ja existeixen a la base de dades';
          backgroundColor = Colors.orange;
        }

        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processant el PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Calcular dates per cada període
    final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day, 0, 0, 0);
    final weekEnd = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day + 6, 23, 59, 59);
    final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearStart = DateTime(now.year, 1, 1, 0, 0, 0);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppTheme.grisPistacho.withValues(alpha: 0.12),
      appBar: AppBar(
        backgroundColor: AppTheme.porpraFosc,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Les meves designacions',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.mostassa,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Setmana'),
            Tab(text: 'Mes'),
            Tab(text: 'Any'),
            Tab(text: 'Tot'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Resum econòmic i estadístiques
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 900;

              if (isWideScreen) {
                // En pantalles grans: row amb dos widgets
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: EarningsSummaryWidget(inRow: true),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CategoryStatsWidget(inRow: true),
                      ),
                    ],
                  ),
                );
              } else {
                // En pantalles petites: column amb dos widgets
                return const Column(
                  children: [
                    EarningsSummaryWidget(inRow: false),
                    CategoryStatsWidget(inRow: false),
                  ],
                );
              }
            },
          ),

          // Historial de partits
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DesignationsTabView(
                  startDate: weekStart,
                  endDate: weekEnd,
                ),
                DesignationsTabView(
                  startDate: monthStart,
                  endDate: monthEnd,
                ),
                DesignationsTabView(
                  startDate: yearStart,
                  endDate: yearEnd,
                ),
                const DesignationsTabView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _handlePdfUpload,
        backgroundColor: AppTheme.mostassa,
        foregroundColor: AppTheme.porpraFosc,
        elevation: 6,
        highlightElevation: 10,
        icon: _isUploading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.porpraFosc),
                ),
              )
            : const Icon(Icons.upload_file_rounded, size: 22),
        label: Text(
          _isUploading ? 'Processant...' : 'Pujar PDF',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}