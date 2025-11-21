import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

import 'package:el_visionat/features/visionat/providers/weekly_match_provider.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_info_widget.dart';
import '../widgets/profile_footprint_widget.dart';
import '../widgets/personal_notes_table_widget.dart';
import '../widgets/season_goals_widget.dart';

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
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white, // Fons blanc per la transició del header
      drawer: isDesktop ? null : const SideNavigationMenu(),
      body: Column(
        children: [
          GlobalHeader(scaffoldKey: _scaffoldKey),
          Expanded(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Menú lateral en desktop
                      const SizedBox(width: 288, child: SideNavigationMenu()),
                      // Contingut principal
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildDesktopLayout(),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(child: _buildMobileLayout()),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // 🔥 PROFILE HEADER - Segueix prototip Figma (desktop, pantalla completa)
        ProfileHeaderWidget(
          height: 300, // Més alt en desktop
          onEditProfile: () => _handleEditProfile(),
          onChangeVisibility: () => _handleChangeVisibility(),
          onCompareProfileEvolution: () => _handleCompareEvolution(),
        ),
        const SizedBox(height: 32),
        // Contingut amb padding lateral
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Layout de dues columnes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna esquerra
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildPersonalInfo(),
                        const SizedBox(height: 24),
                        _buildEmpremtaVisionat(),
                        const SizedBox(height: 24),
                        _buildObjectiusTemporada(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Columna dreta
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildApuntsPersonals(),
                        const SizedBox(height: 24),
                        _buildBadges(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadgeCard(
          '10 VISIONATS',
          'Primer objectiu assolit. Bona constància.',
          AppTheme.mostassa,
          'V',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '50 APUNTS PERSONALS',
          'La teva dedicació és extraordinària.',
          AppTheme.lilaMitja,
          '✏',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '1 MES DE RUTINA SETMANAL',
          'Excel·lent compromís i esforç.',
          Colors.orange,
          '🔥',
        ),
      ],
    );
  }

  Widget _buildBadgeCard(
    String title,
    String description,
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.grisBody,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
