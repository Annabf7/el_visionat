import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// 🔥 PROFILE HEADER WIDGET - EL VISIONAT
///
/// Widget reutilitzable per mostrar el header del perfil d'usuari.
/// Segueix l'arquitectura Feature-First del projecte.
///
/// FUNCIONALITATS:
/// • Mostra imatge fixa durant desenvolupament
/// • Preparada per imatges d'usuari via image_picker
/// • Menú kebab (3 punts) amb opcions de perfil
/// • Responsive design (mòbil/desktop)
///
/// ASSETS REQUERIT:
/// • assets/images/profile/profile_header.webp
class ProfileHeaderWidget extends StatefulWidget {
  /// URL de la imatge de perfil de l'usuari (null = imatge per defecte)
  final String? imageUrl;

  /// Callbacks per les accions del menú kebab
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangeVisibility;
  final VoidCallback? onCompareProfileEvolution;

  /// Altura del header (responsive)
  final double? height;

  /// Callback per guardar l'offset de la imatge
  final Function(double offset)? onImageOffsetChanged;

  const ProfileHeaderWidget({
    super.key,
    this.imageUrl,
    this.onEditProfile,
    this.onChangeVisibility,
    this.onCompareProfileEvolution,
    this.height,
    this.onImageOffsetChanged,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  bool _isAdjustingImage = false;
  double _imageOffsetY = 0.0; // -1.5 (dalt) a 1.5 (baix)
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final headerHeight = widget.height ?? (isDesktop ? 500.0 : 170.0);

    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imatge principal del header
          _buildHeaderImage(),

          // Efecte blur a la part inferior
          _buildBottomBlurOverlay(),

          // Gradient overlay per millor contrast dels botons
          _buildTopGradientOverlay(),

          // Botó menú kebab (3 punts) - part superior dreta
          Positioned(top: 16, right: 16, child: _buildKebabMenuButton(context)),

          // Botó d'ajustament d'imatge - només desktop
          if (isDesktop)
            Positioned(top: 16, left: 16, child: _buildImageAdjustButton()),

          // Controls d'ajustament quan està actiu
          if (_isAdjustingImage) _buildAdjustmentControls(),
        ],
      ),
    );
  }

  /// Imatge principal del header amb ajustament interactiu
  Widget _buildHeaderImage() {
    final imageWidget = widget.imageUrl != null && widget.imageUrl!.isNotEmpty
        ? Image.network(
            widget.imageUrl!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.mostassa),
                ),
              );
            },
          )
        : Image.asset(
            'assets/images/profile/profile_header.webp',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
          );

    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: _isAdjustingImage
            ? (details) {
                setState(() {
                  _imageOffsetY += details.delta.dy / 150;
                  _imageOffsetY = _imageOffsetY.clamp(-1.5, 1.5);
                });
              }
            : null,
        child: ClipRect(
          child: OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment(0.0, _imageOffsetY),
            child: SizedBox(
              width: double.infinity,
              height: 850, // Altura més gran per permetre més desplaçament
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  /// Imatge de fallback
  Widget _buildFallbackImage() {
    return Container(
      color: AppTheme.grisPistacho,
      child: const Center(
        child: Icon(Icons.person, size: 64, color: AppTheme.mostassa),
      ),
    );
  }

  /// Botó per activar/desactivar mode d'ajustament
  Widget _buildImageAdjustButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isAdjustingImage
            ? AppTheme.mostassa.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.5),
      ),
      child: IconButton(
        icon: Icon(
          _isAdjustingImage ? Icons.check : Icons.tune,
          color: _isAdjustingImage ? Colors.black : Colors.white,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            if (_isAdjustingImage) {
              // Guardar l'offset quan es confirma
              widget.onImageOffsetChanged?.call(_imageOffsetY);
            }
            _isAdjustingImage = !_isAdjustingImage;
          });
        },
      ),
    );
  }

  /// Controls d'ajustament
  Widget _buildAdjustmentControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      child: Align(
        alignment: Alignment.centerLeft, // Ara a l'esquerra
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_vertical,
                    color: AppTheme.mostassa,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Arrossega per ajustar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _imageOffsetY = 0.0);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onImageOffsetChanged?.call(_imageOffsetY);
                        setState(() => _isAdjustingImage = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mostassa,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Transició suau cap al fons blanc - PROTEGEIX LA FIGURA DE L'ÀRBITRE
  Widget _buildBottomBlurOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 35, // Altura reduïda - només part inferior buida
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent, // Figura nítida (0%)
              Colors.white.withValues(alpha: 0.2), // Inici suau (20%)
              Colors.white.withValues(alpha: 0.5), // Transició (50%)
              Colors.white.withValues(alpha: 0.8), // Fort (80%)
              Colors.white, // Blanc pur final (100%)
            ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  /// Gradient overlay superior per millor contrast del botó kebab
  Widget _buildTopGradientOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  /// Botó del menú kebab (3 punts) amb popup
  Widget _buildKebabMenuButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: AppTheme.white, size: 24),
        iconSize: 24,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppTheme.white,
        elevation: 8,
        onSelected: (String value) => _handleMenuAction(value),
        itemBuilder: (BuildContext context) => [
          _buildPopupMenuItem(
            'edit_profile',
            Icons.edit_outlined,
            'Editar perfil',
          ),
          _buildPopupMenuItem(
            'change_visibility',
            Icons.visibility_outlined,
            'Configuració de la visibilitat',
          ),
          _buildPopupMenuItem(
            'compare_evolution',
            Icons.compare_arrows_outlined,
            'Comparar amb fa 1 any',
          ),
        ],
      ),
    );
  }

  /// Construeix un element del popup menú
  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.porpraFosc),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBlackLow,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Gestiona les accions del menú kebab
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_profile':
        debugPrint('🔧 Acció: Editar perfil');
        widget.onEditProfile?.call();
        break;
      case 'change_visibility':
        debugPrint('👁️ Acció: Configuració de visibilitat');
        widget.onChangeVisibility?.call();
        break;
      case 'compare_evolution':
        debugPrint('📊 Acció: Comparar evolució del perfil');
        widget.onCompareProfileEvolution?.call();
        break;
      default:
        debugPrint('⚠️ Acció desconeguda: $action');
    }
  }
}

/// Widget d'efecte shimmer personalitzat
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.transparent,
                AppTheme.white.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🚀 FUNCIONS PLACEHOLDER PER FUTURES IMPLEMENTACIONS
///
/// Aquestes funcions es poden implementar més endavant segons les necessitats:

/// Obre el selector d'imatges per canviar la foto del perfil
Future<void> pickProfileImage() async {
  final ImagePicker picker = ImagePicker();
  try {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      debugPrint('📸 Imatge seleccionada: ${image.path}');
      // TODO: Pujar imatge a Firebase Storage
      // TODO: Actualitzar URL al perfil d'usuari
    }
  } catch (e) {
    debugPrint('❌ Error seleccionant imatge: $e');
  }
}

/// Mostra diàleg de configuració de visibilitat del perfil
void showVisibilitySettings(BuildContext context) {
  debugPrint('👁️ Mostrant configuració de visibilitat');
  // TODO: Implementar diàleg amb opcions de privacitat
}

/// Mostra comparativa d'evolució del perfil amb fa 1 any
void showProfileEvolution(BuildContext context) {
  debugPrint('📊 Mostrant evolució del perfil');
  // TODO: Implementar vista de comparativa temporal
}
