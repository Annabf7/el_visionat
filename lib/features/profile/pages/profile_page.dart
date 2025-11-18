import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/features/visionat/providers/personal_analysis_provider.dart';

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
      backgroundColor: AppTheme.porpraFosc,
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
                          padding: const EdgeInsets.all(32),
                          child: _buildDesktopLayout(),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildMobileLayout(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
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
    );
  }

  Widget _buildMobileLayout() {
    return Column(
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
    );
  }

  Widget _buildPersonalInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.textBlackLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informació personal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.mostassa,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Informació
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoField(
                          'Nom i cognoms',
                          authProvider.currentUserDisplayName ?? 'Usuari',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField(
                          'Email',
                          authProvider.currentUserEmail ?? 'email@exemple.com',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField(
                          'Categoria arbitral actual',
                          'Categoria Regional',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField('Anys d\'experiència', '5 anys'),
                        const SizedBox(height: 12),
                        _buildInfoField('Número de llicència', 'LIC-2024-001'),
                        const SizedBox(height: 12),
                        _buildInfoField('Comitè territorial', 'Comitè Català'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botons d'acció
              Row(
                children: [
                  _buildActionButton(Icons.edit, 'Editar'),
                  const SizedBox(width: 12),
                  _buildActionButton(Icons.attach_file, 'Adjuntar'),
                  const SizedBox(width: 12),
                  _buildActionButton(Icons.settings, 'Configurar'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.grisBody, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.grisBody,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () {
          // TODO: Implementar accions
          debugPrint('Acció: $tooltip');
        },
        icon: Icon(icon, color: AppTheme.white, size: 20),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildEmpremtaVisionat() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.textBlackLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La teva Empremta al Visionat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildEmpremtaCard('Partits analitzats', '12'),
          const SizedBox(height: 12),
          _buildEmpremtaCard('Apunts personals creats', '48'),
          const SizedBox(height: 12),
          _buildEmpremtaCard(
            'Tags més utilitzats',
            'Falta personal, Violació 3 segons',
          ),
        ],
      ),
    );
  }

  Widget _buildEmpremtaCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.grisBody,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApuntsPersonals() {
    return Consumer<PersonalAnalysisProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.textBlackLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apunts personals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Estadístiques ràpides
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${provider.analysesCount}',
                      'Total apunts',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('12', 'Aquest mes')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('5', 'Aquesta setmana')),
                ],
              ),

              const SizedBox(height: 16),

              // Botó per veure tots
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navegar a vista completa d'apunts
                    debugPrint('Mostrar tots els apunts');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mostassa,
                    foregroundColor: AppTheme.porpraFosc,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Mostrar tot',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.mostassa,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.grisBody, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiusTemporada() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.textBlackLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objectius de la Temporada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildObjectiveCard('3 punts forts', 'Expandir'),
          const SizedBox(height: 12),
          _buildObjectiveCard('3 punts a millorar', 'Expandir'),
          const SizedBox(height: 12),
          _buildObjectiveCard('3 objectius trimestrals', 'Expandir'),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(String title, String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                action,
                style: const TextStyle(color: AppTheme.grisBody, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.grisBody,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
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
}
