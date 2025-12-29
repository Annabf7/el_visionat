import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/navigation/side_navigation_menu.dart';
import '../../../core/widgets/global_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/models/profile_model.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';
import '../services/pdf_parser_service.dart';
import '../services/tariff_calculator_service.dart';
import '../services/distance_calculator_service.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

      // Obtenir l'adreça de casa de l'àrbitre per calcular quilometratge
      final user = FirebaseAuth.instance.currentUser;
      String userHomeAddress = '';

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final profile = ProfileModel.fromMap(userData);

          if (profile.homeAddress.isComplete) {
            userHomeAddress = profile.homeAddress.fullAddress;
          }
        }
      }

      // Processar cada partit trobat
      int successCount = 0;
      int duplicateCount = 0;

      // Map per rastrejar pavellons visitats el mateix dia per evitar duplicar desplaçaments
      // Clau: locationAddress original, Valor: true si ja s'ha cobrat desplaçament
      final Map<String, bool> venuesWithTravelPaid = {};

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

        // Calcular quilometratge automàticament si tenim adreça de casa
        double kilometers = 0.0;
        String venueAddress = matchData['locationAddress']!;

        // Netejar l'adreça del pavelló per millorar la geocodificació
        // 1. Eliminar "S/N" (sense número)
        venueAddress = venueAddress
            .replaceAll('S/N', '')
            .replaceAll('s/n', '')
            .replaceAll('S / N', '')
            .replaceAll('s / n', '');

        // 2. Convertir separadors "·" a comes
        venueAddress = venueAddress
            .replaceAll(' · ', ', ')
            .replaceAll('·', ', ');

        // 3. Netejar comes i espais múltiples
        venueAddress = venueAddress
            .replaceAll(RegExp(r'\s+,\s*'), ', ')  // Espais abans de comes
            .replaceAll(RegExp(r',\s*,'), ',')     // Comes dobles
            .replaceAll(RegExp(r'\s+'), ' ')       // Espais múltiples
            .trim();

        // 4. Si l'adreça comença amb coma, eliminar-la
        if (venueAddress.startsWith(',')) {
          venueAddress = venueAddress.substring(1).trim();
        }

        // 5. Si l'adreça acaba amb coma, eliminar-la
        if (venueAddress.endsWith(',')) {
          venueAddress = venueAddress.substring(0, venueAddress.length - 1).trim();
        }

        // 6. Afegir "Spain" al final si no hi és per millorar la geocodificació
        if (!venueAddress.toUpperCase().contains('SPAIN') &&
            !venueAddress.toUpperCase().contains('ESPAÑA') &&
            !venueAddress.toUpperCase().contains('ESPANYA')) {
          venueAddress = '$venueAddress, Spain';
        }

        print('==== DESIGNATION DEBUG ====');
        print('Match #${matchData['matchNumber']}:');
        print('  Category: "${matchData['category']}"');
        print('  Role: "${matchData['role']}"');
        print('  Date: $date');
        print('  Time: ${matchData['time']}');
        print('  User home address: "$userHomeAddress"');
        print('  Venue address (original): "${matchData['locationAddress']}"');
        print('  Venue address (cleaned): "$venueAddress"');

        // Comprovar si ja s'ha cobrat desplaçament per aquest pavelló
        final originalVenueAddress = matchData['locationAddress']!;
        final bool shouldChargeTravel = !venuesWithTravelPaid.containsKey(originalVenueAddress);

        if (userHomeAddress.isNotEmpty && venueAddress.isNotEmpty) {
          if (shouldChargeTravel) {
            // Primer partit en aquest pavelló: calcular distància
            final oneWayKm = await DistanceCalculatorService.calculateDistance(
              originAddress: userHomeAddress,
              destinationAddress: venueAddress,
            );

            // Multiplicar per 2 per incloure anada i tornada
            kilometers = oneWayKm * 2;

            print('  Distance (one way): $oneWayKm km');
            print('  Distance (round trip): $kilometers km');

            // Marcar que ja s'ha cobrat desplaçament per aquest pavelló
            venuesWithTravelPaid[originalVenueAddress] = true;
          } else {
            // Aquest pavelló ja ha tingut un partit amb desplaçament cobrat
            print('  ⚠️ Travel already charged for this venue - setting kilometers to 0');
            kilometers = 0.0;
          }
        } else {
          print('  ⚠️ Skipping distance calculation (missing address)');
        }

        // Calcular ingressos amb quilometratge calculat
        final earnings = TariffCalculatorService.calculateEarnings(
          category: matchData['category']!,
          role: matchData['role']!,
          kilometers: kilometers,
          matchDate: date,
          matchTime: matchData['time']!,
        );

        print('  EARNINGS CALCULATED:');
        print('    Rights: ${earnings.rights}€');
        print('    Kilometers amount: ${earnings.kilometersAmount}€');
        print('    Allowance: ${earnings.allowance}€');
        print('    TOTAL: ${earnings.total}€');
        print('==========================');

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
                const SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: SideNavigationMenu(),
                ),

                // Columna dreta amb GlobalHeader + contingut
                Expanded(
                  child: Column(
                    children: [
                      // GlobalHeader només per l'amplada restant
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Les meves designacions',
                        showMenuButton: false,
                      ),

                      // Contingut principal
                      Expanded(
                        child: _buildDesktopContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(),
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
                  title: 'Les meves designacions',
                  showMenuButton: true,
                ),

                // Contingut principal
                Expanded(child: _buildMobileContent()),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        }
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isUploading ? null : _handlePdfUpload,
      backgroundColor: AppTheme.mostassa,
      foregroundColor: AppTheme.porpraFosc,
      elevation: 6,
      highlightElevation: 10,
      icon: _isUploading
          ? const SizedBox(
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
    );
  }

  Widget _buildDesktopContent() {
    final now = DateTime.now();

    // Calcular dates per cada període
    final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day, 0, 0, 0);
    final weekEnd = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day + 6, 23, 59, 59);
    final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearStart = DateTime(now.year, 1, 1, 0, 0, 0);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.12),
      child: Column(
        children: [
          // Tabs
          Container(
            color: AppTheme.porpraFosc,
            child: TabBar(
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

          // Resum econòmic i estadístiques en fila (desktop)
          const Padding(
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
    );
  }

  Widget _buildMobileContent() {
    final now = DateTime.now();

    // Calcular dates per cada període
    final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day, 0, 0, 0);
    final weekEnd = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day + 6, 23, 59, 59);
    final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearStart = DateTime(now.year, 1, 1, 0, 0, 0);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.12),
      child: Column(
        children: [
          // Tabs
          Container(
            color: AppTheme.porpraFosc,
            child: TabBar(
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

          // Resum econòmic i estadístiques en columna (mòbil)
          const Column(
            children: [
              EarningsSummaryWidget(inRow: false),
              CategoryStatsWidget(inRow: false),
            ],
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
    );
  }
}