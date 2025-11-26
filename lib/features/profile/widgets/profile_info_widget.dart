import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// 🔥 PROFILE INFO WIDGET - EL VISIONAT
///
/// Widget per mostrar la informació personal de l'àrbitre.
/// Inclou avatar editable, nom, categoria i experiència.
/// Segueix el prototip Figma amb línia mostassa i layout integrat.
class ProfileInfoWidget extends StatelessWidget {
  /// URL de la imatge de perfil de l'usuari (null = imatge per defecte)
  final String? portraitImageUrl;

  /// Dades de l'àrbitre
  final String refereeName;
  final String refereeCategory;
  final String refereeExperience;

  /// Callback per canviar la imatge de perfil
  final VoidCallback? onChangePortrait;

  /// Permet edició de la imatge
  final bool enableImageEdit;

  const ProfileInfoWidget({
    super.key,
    this.portraitImageUrl,
    required this.refereeName,
    required this.refereeCategory,
    required this.refereeExperience,
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
          // Informació principal amb avatar i dades
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Informació de l'àrbitre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildRefereeInfo(context, isDesktop)],
                ),
              ),
              const SizedBox(width: 24),
              // Avatar circular amb opció d'edició
              _buildEditableAvatar(context),
            ],
          ),

          const SizedBox(height: 24),

          // Línia separadora mostassa
          _buildMostassaSeparator(),
        ],
      ),
    );
  }

  /// Avatar circular amb funcionalitat d'edició
  Widget _buildEditableAvatar(BuildContext context) {
    return GestureDetector(
      onTap: enableImageEdit ? () => _handleChangePortrait(context) : null,
      child: Stack(
        children: [
          // Avatar principal
          Container(
            width: 120,
            height: 120,
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

          // Icona d'edició si està habilitada
          if (enableImageEdit)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.mostassa,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ),

          // Indicador d'estat (punt verd) si està actiu
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Imatge de l'avatar (local o de xarxa)
  Widget _buildAvatarImage() {
    if (portraitImageUrl != null && portraitImageUrl!.isNotEmpty) {
      // Imatge d'usuari des de URL externa
      return CachedNetworkImage(
        imageUrl: portraitImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildAvatarPlaceholder(),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    } else {
      // Imatge per defecte local
      return _buildDefaultAvatar();
    }
  }

  /// Imatge per defecte local
  Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/images/profile/portrait.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error carregant portrait.jpg: $error');
        return _buildFallbackAvatar();
      },
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
        // Nom de l'àrbitre
        Text(
          refereeName,
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

        // Categoria
        Text(
          refereeCategory,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.porpraFosc.withValues(alpha: 0.8),
            height: 1.3,
          ),
        ),

        const SizedBox(height: 4),

        // Experiència
        Text(
          refereeExperience,
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

  /// Gestiona el canvi de la imatge de perfil
  void _handleChangePortrait(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('📸 Portrait seleccionat: ${image.path}');
        // Cridar callback si existeix
        onChangePortrait?.call();

        // TODO: Implementar upload a Firebase Storage
        // TODO: Actualitzar URL al perfil d'usuari

        // Feedback visual temporarl
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📸 Imatge seleccionada. Upload en desenvolupament...',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error seleccionant portrait: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seleccionant imatge: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
