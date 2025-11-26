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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna esquerra: Imatge sense cantonades arrodonides i menys ampla
        Flexible(
          flex: 4, // Encara menys espai per la imatge
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(),
            child: ProfileBannerWidget(),
          ),
        ),
        // Columna dreta: widgets amb scroll vertical i més espai
        Flexible(
          flex: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header i info personal sobreposada
                      SizedBox(
                        height: 450,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProfileHeaderWidget(
                              onEditProfile: () => _handleEditProfile(),
                              onChangeVisibility: () =>
                                  _handleChangeVisibility(),
                              onCompareProfileEvolution: () =>
                                  _handleCompareEvolution(),
                            ),
                            Positioned(
                              right: 0,
                              bottom: -60, // Ara més avall per solapar més
                              child: SizedBox(
                                width: 420,
                                child: _buildPersonalInfo(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildEmpremtaVisionat(),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildObjectiusTemporada()),
                            const SizedBox(width: 32),
                            Expanded(child: _buildBadges()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildApuntsPersonals(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        const SizedBox(height: 8),
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
              const SizedBox(height: 32), // Marge inferior extra
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
