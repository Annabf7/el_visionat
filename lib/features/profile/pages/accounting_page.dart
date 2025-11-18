import 'package:flutter/material.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Pàgina placeholder per a la funcionalitat de comptabilitat
/// Mostra un missatge informatiu mentre es desenvolupa la funcionalitat
class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
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
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(48),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: AppTheme.textBlackLow,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _buildContent(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppTheme.textBlackLow,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _buildContent(context),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icona principal
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.mostassa.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.assessment,
            size: 40,
            color: AppTheme.mostassa,
          ),
        ),

        const SizedBox(height: 24),

        // Títol
        Text(
          'Comptabilitat',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Descripció
        Text(
          'Aviat podràs pujar les teves designacions i veure la teva comptabilitat mensual i anual.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.grisBody,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Funcionalitats previstes
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.grisBody.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.grisBody.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Funcionalitats previstes:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem('📊', 'Resum mensual i anual de designacions'),
              _buildFeatureItem(
                '💰',
                'Càlcul automàtic de dietes i quilometratge',
              ),
              _buildFeatureItem('📋', 'Historial de designacions i pagaments'),
              _buildFeatureItem('📈', 'Gràfics d\'evolució dels ingressos'),
              _buildFeatureItem('📄', 'Exportació a PDF per a Hisenda'),
              _buildFeatureItem(
                '⚙️',
                'Configuració de tarifes personalitzades',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Botó informatiu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalitat en desenvolupament'),
                  backgroundColor: AppTheme.mostassa,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mostassa,
              foregroundColor: AppTheme.porpraFosc,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Notifica\'m quan estigui disponible',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Text informatiu addicional
        Text(
          'Mentrestant, pots seguir utilitzant les funcionalitats d\'anàlisi de partits i apunts personals.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grisBody,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.grisBody, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
