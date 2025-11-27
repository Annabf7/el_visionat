import 'package:flutter/material.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/features/profile/widgets/edit_profile_dialog.dart';
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchProfileInfo(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return ProfileInfoWidget(
          // portraitImageUrl: null, // Imatge: es farà en un pas futur
          refereeName: ' ', // Nom: es farà en un pas futur
          refereeCategory: data == null || data['refereeCategory'] == null
              ? 'Defineix la teva categoria'
              : data['refereeCategory'] as String,
          refereeExperience: (data == null || data['anysArbitrats'] == null)
              ? '-'
              : '${data['anysArbitrats']} anys arbitrats',
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
  Future<Map<String, dynamic>?> _fetchProfileInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  void _handleEditProfile() async {
    debugPrint('🔧 ProfilePage: Editant perfil d\'usuari');
    final result = await showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        initialCategory: 'Categoria A2 - RT Girona',
        initialStartYear: 2015,
        onSave: (category, startYear) {
          debugPrint(
            'Mock save: categoria=\x1B[33m$category\x1B[0m, startYear=\x1B[33m$startYear\x1B[0m',
          ); // TODO: eliminar quan activem funcionalitat real
        },
        onChangeHeaderImage: () {
          debugPrint(
            'Mock change header image',
          ); // TODO: eliminar quan activem funcionalitat real
        },
        onChangePortraitImage: () {
          debugPrint(
            'Mock change portrait image',
          ); // TODO: eliminar quan activem funcionalitat real
        },
      ),
    );
    if (!mounted) return;
    if (result == 'header_success' ||
        result == 'portrait_success' ||
        result == 'profile_success') {
      setState(() {}); // Refresca la UI després de canvis
      String msg;
      if (result == 'header_success') {
        msg = 'Imatge de capçalera actualitzada!';
      } else if (result == 'portrait_success') {
        msg = 'Imatge de perfil actualitzada!';
      } else {
        msg = 'Perfil actualitzat correctament!';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else if (result == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('S\'ha produït un error. Torna-ho a intentar.'),
        ),
      );
    }
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
