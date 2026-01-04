import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../models/home_address_model.dart';
import 'edit_home_address_dialog.dart';

/// Widget de designacions i comptabilitat automàtica
/// Permet a l'usuari penjar PDFs de designacions i calcula automàticament els cobraments
class AccountingSummaryWidget extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onAddressUpdated;

  const AccountingSummaryWidget({
    super.key,
    required this.profile,
    this.onAddressUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header amb títol i icona
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: AppTheme.mostassa, width: 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.mostassa,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designacions',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          color: AppTheme.textBlackLow,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Càlcul automàtic de cobraments',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          color: AppTheme.textBlackLow,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contingut principal - estat buit
          _buildEmptyState(context),
        ],
      ),
    );
  }

  /// Estat buit quan no hi ha designacions penjades
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icona central
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_file_outlined,
              size: 48,
              color: AppTheme.textBlackLow.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // Text explicatiu
          Text(
            'Penja les teves designacions',
            style: TextStyle(
              fontFamily: 'Geist',
              color: AppTheme.textBlackLow.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puja els PDFs de les designacions i el sistema calcularà automàticament els teus cobraments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              color: AppTheme.textBlackLow.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Adreça de casa
          _buildHomeAddressSection(context),

          const SizedBox(height: 20),

          // Botó per anar a designacions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/designations');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mostassa,
                foregroundColor: AppTheme.porpraFosc,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Afegir designació',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Secció d'adreça de casa amb opció d'editar
  Widget _buildHomeAddressSection(BuildContext context) {
    final hasAddress = profile.homeAddress.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAddress
              ? AppTheme.mostassa.withValues(alpha: 0.3)
              : AppTheme.textBlackLow.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_outlined,
                size: 18,
                color: hasAddress ? AppTheme.mostassa : AppTheme.textBlackLow.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Punt de sortida',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    color: AppTheme.textBlackLow.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _editHomeAddress(context),
                child: Row(
                  children: [
                    Icon(
                      hasAddress ? Icons.edit_outlined : Icons.add_circle_outline,
                      size: 16,
                      color: AppTheme.mostassa,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasAddress ? 'Editar' : 'Afegir',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        color: AppTheme.mostassa,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasAddress) ...[
            const SizedBox(height: 8),
            Text(
              profile.homeAddress.toString(),
              style: TextStyle(
                fontFamily: 'Geist',
                color: AppTheme.textBlackLow.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Necessari per calcular els quilòmetres',
              style: TextStyle(
                fontFamily: 'Geist',
                color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obre el diàleg per editar l'adreça de casa
  Future<void> _editHomeAddress(BuildContext context) async {
    final result = await showDialog<HomeAddress>(
      context: context,
      builder: (context) => EditHomeAddressDialog(
        currentAddress: profile.homeAddress.isComplete ? profile.homeAddress : null,
      ),
    );

    if (result != null && context.mounted) {
      // Guardar l'adreça a Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'homeAddress': result.toFirestore(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adreça actualitzada correctament'),
              backgroundColor: AppTheme.mostassa,
              duration: Duration(seconds: 2),
            ),
          );

          // Notificar a la pàgina pare per refrescar les dades
          debugPrint('🏠 Adreça guardada, refrescant pàgina...');
          onAddressUpdated?.call();
        }
      }
    }
  }
}