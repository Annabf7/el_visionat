import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  /// Callback per l'acció de mentoratge
  final ValueChanged<bool>? onToggleMentor;
  final bool isMentor;

  /// Altura del header (responsive)
  final double? height;

  /// Callback per guardar l'offset de la imatge
  final Function(double offset)? onImageOffsetChanged;

  /// Mostra el menú kebab (per defecte: true)
  final bool showMenu;

  /// Mostra el botó d'ajustament d'imatge (per defecte: true)
  final bool showImageAdjustButton;

  /// Callback per al botó de retorn (només quan showMenu és false)
  final VoidCallback? onBackPressed;

  const ProfileHeaderWidget({
    super.key,
    this.imageUrl,
    this.onEditProfile,
    this.onChangeVisibility,
    this.onCompareProfileEvolution,
    this.height,
    this.isMentor = false,
    this.onToggleMentor,
    this.onImageOffsetChanged,
    this.showMenu = true,
    this.showImageAdjustButton = true,
    this.onBackPressed,
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

    // Si hi ha altura específica, usar-la
    if (widget.height != null) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: _buildHeaderContent(isDesktop),
      );
    }

    // Desktop: altura fixa que omple tot l'ample
    // Mòbil: AspectRatio 4:3
    if (isDesktop) {
      // Altura basada en l'ample de pantalla amb ratio 16:9
      final height = screenWidth / (16 / 9);
      return SizedBox(
        width: double.infinity,
        height: height.clamp(300.0, 500.0), // Màxim 500px, mínim 300px
        child: _buildHeaderContent(isDesktop),
      );
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _buildHeaderContent(isDesktop),
    );
  }

  Widget _buildHeaderContent(bool isDesktop) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imatge principal del header
        _buildHeaderImage(isDesktop: isDesktop),

        // Efecte blur a la part inferior
        _buildBottomBlurOverlay(isDesktop: isDesktop),

        // Gradient overlay per millor contrast dels botons
        _buildTopGradientOverlay(),

        // Botó menú kebab (3 punts) - part superior dreta (només si showMenu és true)
        if (widget.showMenu)
          Positioned(
            top: isDesktop ? 16 : 8,
            right: isDesktop ? 16 : 8,
            child: _buildKebabMenuButton(context, isCompact: !isDesktop),
          ),

        // Botó de retorn - part superior dreta (només si showMenu és false i hi ha onBackPressed)
        if (!widget.showMenu && widget.onBackPressed != null)
          Positioned(
            top: isDesktop ? 16 : 8,
            right: isDesktop ? 16 : 8,
            child: _buildBackButton(isCompact: !isDesktop),
          ),

        // Botó d'ajustament d'imatge - desktop i mòbil (només si showImageAdjustButton és true)
        if (widget.showImageAdjustButton)
          Positioned(
            top: isDesktop ? 16 : 8,
            left: isDesktop ? 16 : 8,
            child: _buildImageAdjustButton(isCompact: !isDesktop),
          ),

        // Controls d'ajustament quan està actiu
        if (_isAdjustingImage) _buildAdjustmentControls(isCompact: !isDesktop),
      ],
    );
  }

  /// Imatge principal del header amb ajustament interactiu
  Widget _buildHeaderImage({required bool isDesktop}) {
    // Desktop: BoxFit.cover per omplir tot l'espai sense vores blanques
    // Mòbil: BoxFit.contain per veure la imatge completa
    final imageFit = isDesktop ? BoxFit.cover : BoxFit.contain;

    final imageWidget = widget.imageUrl != null && widget.imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: widget.imageUrl!,
            fit: imageFit,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: AppTheme.grisPistacho.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.mostassa),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallbackImage(),
          )
        : Image.asset(
            'assets/images/profile/profile_header.webp',
            fit: imageFit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
          );

    // Quan estem ajustant, usem GestureDetector amb verticalDrag
    // que té prioritat sobre el scroll del pare
    Widget content;

    if (isDesktop) {
      // Desktop: Amb OverflowBox per ajustar la posició vertical
      content = ClipRect(
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment(0.0, _imageOffsetY),
          child: SizedBox(
            width: double.infinity,
            height: 500, // Alçada reduïda per desktop
            child: imageWidget,
          ),
        ),
      );
    } else {
      // Mòbil: Amb OverflowBox per ajustar la posició vertical
      content = ClipRect(
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment(0.0, _imageOffsetY),
          child: SizedBox(
            width: double.infinity,
            height: 850,
            child: imageWidget,
          ),
        ),
      );
    }

    if (_isAdjustingImage) {
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              _imageOffsetY += details.delta.dy / 150;
              _imageOffsetY = _imageOffsetY.clamp(-1.5, 1.5);
            });
          },
          child: content,
        ),
      );
    }

    return Positioned.fill(child: content);
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
  Widget _buildImageAdjustButton({bool isCompact = false}) {
    final buttonSize = isCompact ? 36.0 : 40.0;
    final iconSize = isCompact ? 18.0 : 20.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isAdjustingImage
            ? AppTheme.mostassa.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.5),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          _isAdjustingImage ? Icons.check : Icons.tune,
          color: _isAdjustingImage ? Colors.black : Colors.white,
          size: iconSize,
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

  /// Controls d'ajustament - compactes per no ocupar massa espai
  Widget _buildAdjustmentControls({bool isCompact = false}) {
    return Positioned(
      bottom: isCompact ? 8 : 12,
      left: 0,
      right: isCompact ? null : null,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: isCompact ? 200 : 260),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 8 : 10,
          ),
          margin: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe_vertical,
                    color: AppTheme.mostassa,
                    size: isCompact ? 16 : 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Arrossega',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isCompact ? 11 : 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 6 : 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: isCompact ? 26 : 28,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _imageOffsetY = 0.0);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 1),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 10 : 12,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(fontSize: isCompact ? 10 : 11),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  SizedBox(
                    height: isCompact ? 26 : 28,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onImageOffsetChanged?.call(_imageOffsetY);
                        setState(() => _isAdjustingImage = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mostassa,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 14,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  /// Transició suau cap al fons blanc - EFECTE PROFESSIONAL
  Widget _buildBottomBlurOverlay({bool isDesktop = false}) {
    return Positioned(
      bottom: isDesktop ? -70 : 0, // Mòbil: a ras del bottom
      left: 0,
      right: 0,
      child: Container(
        height: isDesktop
            ? 120
            : 100, // Mòbil: degradat molt més alt per fondre bé
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0.9),
              Colors.white,
            ],
            stops: const [0.0, 0.2, 0.4, 0.55, 0.7, 0.85, 1.0],
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
  Widget _buildKebabMenuButton(BuildContext context, {bool isCompact = false}) {
    final buttonSize = isCompact ? 36.0 : 40.0;
    final iconSize = isCompact ? 18.0 : 20.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
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
        icon: Icon(Icons.more_vert, color: AppTheme.white, size: iconSize),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
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
            'Visibilitat del meu perfil',
          ),
          _buildPopupMenuItem(
            'compare_evolution',
            Icons.compare_arrows_outlined,
            'Comparar amb fa 1 any',
          ),
          const PopupMenuDivider(),
          _buildPopupMenuItem(
            'toggle_mentor',
            widget.isMentor ? Icons.check_box : Icons.check_box_outline_blank,
            'Mentoritzas?',
            isActive: widget.isMentor,
          ),
        ],
      ),
    );
  }

  /// Botó de retorn per tornar al perfil privat
  Widget _buildBackButton({bool isCompact = false}) {
    final buttonSize = isCompact ? 36.0 : 40.0;
    final iconSize = isCompact ? 18.0 : 20.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
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
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.white, size: iconSize),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        onPressed: widget.onBackPressed,
        tooltip: 'Tornar al meu perfil',
      ),
    );
  }

  /// Construeix un element del popup menú
  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text, {
    bool isActive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppTheme.verdeEncert : AppTheme.porpraFosc,
          ),
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
      case 'toggle_mentor':
        debugPrint('🎓 Acció: Toggle mentor status');
        widget.onToggleMentor?.call(!widget.isMentor);
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
