import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/profile_model.dart';

/// 🔥 PROFILE INFO WIDGET - EL VISIONAT
///
/// Widget per mostrar la informació personal de l'àrbitre.
/// Inclou avatar editable, nom, categoria i experiència.
/// Segueix el prototip Figma amb línia mostassa i layout integrat.
class ProfileInfoWidget extends StatelessWidget {
  /// Model de perfil amb tota la informació validada
  final ProfileModel profile;

  /// Callback per canviar la imatge de perfil
  final VoidCallback? onChangePortrait;

  /// Permet edició de la imatge
  final bool enableImageEdit;

  const ProfileInfoWidget({
    super.key,
    required this.profile,
    this.onChangePortrait,
    this.enableImageEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 2,
      ),
      color: Colors.transparent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildRefereeInfo(context, isDesktop)],
                ),
              ),
              const SizedBox(width: 24),
              _buildEditableAvatar(context),
            ],
          ),
          const SizedBox(height: 24),
          _buildMostassaSeparator(),
        ],
      ),
    );
  }

  /// Avatar circular amb funcionalitat d'edició
  Widget _buildEditableAvatar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final avatarSize = isDesktop ? 120.0 : 92.0;
    final greenDotSize = isDesktop ? 22.0 : 16.0;
    return Stack(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.grisPistacho.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: _buildAvatarImage()),
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            width: greenDotSize,
            height: greenDotSize,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Imatge de l'avatar (local o de xarxa)
  Widget _buildAvatarImage() {
    // Sempre usem resolvedAvatarUrl que ja gestiona el fallback segons gender
    return CachedNetworkImage(
      imageUrl: profile.resolvedAvatarUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildAvatarPlaceholder(),
      errorWidget: (context, url, error) => _buildFallbackAvatar(),
    );
  }

  /// Placeholder mentre es carrega la imatge
  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.2),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.porpraFosc),
          ),
        ),
      ),
    );
  }

  /// Avatar de fallback si falla tot
  Widget _buildFallbackAvatar() {
    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.person,
          size: 32,
          color: AppTheme.porpraFosc.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Informació textual de l'àrbitre
  Widget _buildRefereeInfo(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          profile.displayNameSafe,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textBlackLow,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          profile.categoriaSafe,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.porpraFosc.withValues(alpha: 0.8),
            height: 1.3,
          ),
        ),
        // Només mostrem els anys d'experiència si la visibilitat ho permet
        if (profile.visibility.showYearsExperience) ...[
          const SizedBox(height: 4),
          Text(
            profile.anysArbitratsSafe,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textBlackLow.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// Línia separadora amb color mostassa
  Widget _buildMostassaSeparator() {
    return Container(
      width: double.infinity,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.mostassa.withValues(alpha: 0.2),
            AppTheme.mostassa,
            AppTheme.mostassa,
            AppTheme.mostassa.withValues(alpha: 0.2),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// 🚀 FUNCIONS AUXILIARS PER FUTURES IMPLEMENTACIONS

/// Comprova si la imatge existeix localment
Future<bool> checkLocalImageExists(String path) async {
  try {
    // TODO: Implementar verificació d'assets
    return true;
  } catch (e) {
    return false;
  }
}

/// Optimitza i redimensiona la imatge seleccionada
Future<String?> processSelectedImage(XFile image) async {
  try {
    // TODO: Implementar compressió i optimització
    // TODO: Generar thumbnail
    return image.path;
  } catch (e) {
    debugPrint('❌ Error processant imatge: $e');
    return null;
  }
}
