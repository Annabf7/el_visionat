import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';

import 'package:el_visionat/features/visionat/providers/weekly_match_provider.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_info_widget.dart';
import '../widgets/profile_footprint_widget.dart';
import '../widgets/personal_notes_table_widget.dart';
import '../widgets/season_goals_widget.dart';
import '../widgets/badges_widget.dart';
import '../widgets/profile_banner_widget.dart';

/// Pàgina de perfil d'usuari amb layout responsiu
/// Segueix el prototip Figma amb la paleta de colors Visionat
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          // Layout desktop: Menú lateral ocupa tota l'alçada
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            body: Row(
              children: [
                // Menú lateral amb alçada completa (inclou l'espai del header)
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
                        showMenuButton: false,
                      ),

                      // Contingut principal sense scroll extern
                      Expanded(child: _buildDesktopLayout()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout mòbil: comportament tradicional
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                // GlobalHeader amb icona hamburguesa
                GlobalHeader(scaffoldKey: _scaffoldKey, showMenuButton: true),

                // Contingut principal
                Expanded(
                  child: SingleChildScrollView(child: _buildMobileLayout()),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 COLUMNA ESQUERRA: Imatge àvia que ocupa tota l'altura de la pàgina
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const ProfileBannerWidget(),
            ),
          ),

          const SizedBox(width: 32),

          // 🔥 COLUMNA DRETA: Imatge àrbitre + widgets inferiors amb scroll
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Secció superior: Imatge àrbitre amb card info
                  SizedBox(
                    height: 600,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Imatge gran de l'àrbitre de fons
                          Image.asset(
                            'assets/images/profile/profile_header.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                '❌ Error carregant profile_header.webp: $error',
                              );
                              return Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Gradient subtil a la part inferior per millorar contrast
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.05),
                                    Colors.black.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Card d'informació personal superposat a la part inferior
                          Positioned(
                            bottom: 32,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _buildPersonalInfo(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Widgets inferiors a la columna dreta
                  _buildEmpremtaVisionat(),
                  const SizedBox(height: 32),
                  _buildApuntsPersonals(),
                  const SizedBox(height: 32),
                  _buildObjectiusTemporada(),
                  const SizedBox(height: 32),
                  _buildBadges(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 🔥 PROFILE HEADER - Segueix prototip Figma (pantalla completa)
        ProfileHeaderWidget(
          onEditProfile: () => _handleEditProfile(),
          onChangeVisibility: () => _handleChangeVisibility(),
          onCompareProfileEvolution: () => _handleCompareEvolution(),
        ),
        const SizedBox(height: 24),
        // Contingut amb padding lateral
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildPersonalInfo(),
              const SizedBox(height: 24),
              _buildEmpremtaVisionat(),
              const SizedBox(height: 24),
              _buildApuntsPersonals(),
              const SizedBox(height: 24),
              _buildObjectiusTemporada(),
              const SizedBox(height: 24),
              _buildBadges(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Consumer<WeeklyMatchProvider>(
      builder: (context, matchProvider, _) {
        return ProfileInfoWidget(
          // portraitImageUrl: null, // Utilitzarà imatge local per defecte
          refereeName: matchProvider.isLoading
              ? 'Carregant àrbitre...'
              : matchProvider.hasError
              ? 'Anna Borràs Font' // Fallback
              : matchProvider.refereeName,
          refereeCategory: matchProvider.isLoading
              ? '...'
              : matchProvider.hasError
              ? 'Categoria A2 - RT Girona' // Fallback del prototip
              : matchProvider.refereeCategory,
          refereeExperience: '10 anys arbitrats', // Del prototip Figma
          onChangePortrait: () => _handleChangePortrait(),
          enableImageEdit: true,
        );
      },
    );
  }

  Widget _buildEmpremtaVisionat() {
    return const ProfileFootprintWidget();
  }

  Widget _buildApuntsPersonals() {
    return const PersonalNotesTableWidget();
  }

  Widget _buildObjectiusTemporada() {
    return const SeasonGoalsWidget();
  }

  Widget _buildBadges() {
    return const BadgesWidget();
  }

  // 🔥 PROFILE HEADER CALLBACKS
  // Implementació placeholder per les funcions del menú kebab

  /// Gestiona l'edició del perfil d'usuari
  void _handleEditProfile() {
    debugPrint('🔧 ProfilePage: Editant perfil d\'usuari');
    // TODO: Navegar a pàgina d'edició de perfil
    // TODO: Obrir bottomsheet amb formulari
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🔧 Funcionalitat d\'edició del perfil en desenvolupament',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gestiona la configuració de visibilitat del perfil
  void _handleChangeVisibility() {
    debugPrint('👁️ ProfilePage: Configurant visibilitat del perfil');
    // TODO: Mostrar diàleg de configuració de privacitat
    // TODO: Opcions: Públic, Només àrbitres, Privat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('👁️ Configuració de visibilitat en desenvolupament'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gestiona la comparació d'evolució del perfil
  void _handleCompareEvolution() {
    debugPrint('📊 ProfilePage: Mostrant evolució del perfil');
    // TODO: Generar informe de comparativa temporal
    // TODO: Mostrar estadístiques d'evolució (1 any enrere)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Comparativa d\'evolució en desenvolupament'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gestiona el canvi de la imatge de portrait/avatar
  void _handleChangePortrait() {
    debugPrint('📸 ProfilePage: Canviant imatge de portrait');
    // TODO: Implementar upload a Firebase Storage
    // TODO: Actualitzar URL al perfil d'usuari
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Selecció d\'imatge de portrait en desenvolupament'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
