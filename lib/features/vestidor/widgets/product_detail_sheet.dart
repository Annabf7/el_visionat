import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/vestidor_provider.dart';

/// Bottom sheet de detall de producte amb galeria d'imatges i selector de variants
class ProductDetailSheet extends StatefulWidget {
  final int productId;

  const ProductDetailSheet({super.key, required this.productId});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;

  int? _lastProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VestidorProvider>().loadProductDetail(widget.productId);
    });
    _lastProductId = widget.productId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si el producte canvia, reseteja el controller i l'índex
    final provider = context.watch<VestidorProvider>();
    if (_lastProductId != provider.selectedProduct?.id) {
      _currentImageIndex = 0;
      _pageController.dispose();
      _pageController = PageController();
      _lastProductId = provider.selectedProduct?.id;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Consumer<VestidorProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingDetail) {
                    return _buildLoadingState();
                  }
                  if (provider.hasError && provider.selectedProduct == null) {
                    return _buildErrorState(provider.error!);
                  }
                  if (provider.selectedProduct == null) {
                    return _buildErrorState('Producte no trobat');
                  }

                  return Column(
                    children: [
                      _buildHandleBar(),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          children: [
                            // Galeria d'imatges
                            _buildImageGallery(provider),
                            const SizedBox(height: 24),
                            // Nom del producte
                            _buildProductTitle(provider),
                            const SizedBox(height: 16),
                            // Preu
                            _buildPricing(provider),
                            const SizedBox(height: 24),
                            // Selector de talles
                            if (provider.availableSizes.length > 1) ...[
                              _buildSizeSelector(provider),
                              const SizedBox(height: 20),
                            ],
                            // Selector de colors
                            if (provider.availableColors.length > 1) ...[
                              _buildColorSelector(provider),
                              const SizedBox(height: 20),
                            ],
                            // Disponibilitat
                            _buildAvailabilityInfo(provider),
                            const SizedBox(height: 32),
                            // Botó compra
                            _buildPurchaseButton(context),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Botó tancar
            Positioned(
              top: 8,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.read<VestidorProvider>().clearSelectedProduct();
                    Navigator.pop(context);
                  },
                  color: AppTheme.grisBody,
                  iconSize: 22,
                  tooltip: 'Tancar',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandleBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.grisPistacho.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(VestidorProvider provider) {
    final images = provider.productImages;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.porpraFosc.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.checkroom_rounded,
              size: 64,
              color: AppTheme.lilaMitja.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Carrousel amb fletxes de navegació
        AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) => Container(
                    color: AppTheme.porpraFosc.withValues(alpha: 0.04),
                    child: _buildProductImage(images[i]),
                  ),
                ),
              ),
              if (images.length > 1) ...[
                // Fletxa esquerra
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 36),
                    color: AppTheme.grisBody.withOpacity(
                      _currentImageIndex > 0 ? 0.8 : 0.2,
                    ),
                    onPressed: _currentImageIndex > 0
                        ? () {
                            final newIndex = _currentImageIndex - 1;
                            _pageController.animateToPage(
                              newIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                            setState(() => _currentImageIndex = newIndex);
                          }
                        : null,
                    tooltip: 'Imatge anterior',
                  ),
                ),
                // Fletxa dreta
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 36),
                    color: AppTheme.grisBody.withOpacity(
                      _currentImageIndex < images.length - 1 ? 0.8 : 0.2,
                    ),
                    onPressed: _currentImageIndex < images.length - 1
                        ? () {
                            final newIndex = _currentImageIndex + 1;
                            _pageController.animateToPage(
                              newIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                            setState(() => _currentImageIndex = newIndex);
                          }
                        : null,
                    tooltip: 'Imatge següent',
                  ),
                ),
              ],
            ],
          ),
        ),
        // Indicador de punts
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          _buildDotsIndicator(images.length),
        ],
      ],
    );
  }

  /// Mostra una imatge: asset local (assets/) o URL de xarxa.
  Widget _buildProductImage(String imageSource) {
    if (imageSource.startsWith('assets/')) {
      return Image.asset(
        imageSource,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.grisBody.withValues(alpha: 0.08),
          child: const Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: AppTheme.lilaMitja,
          ),
        ),
      );
    }
    return Image.network(
      imageSource,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppTheme.grisBody.withValues(alpha: 0.1),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.mostassa,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppTheme.grisBody.withValues(alpha: 0.08),
        child: const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: AppTheme.lilaMitja,
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentImageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.mostassa
                : AppTheme.grisPistacho.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildProductTitle(VestidorProvider provider) {
    return Text(
      provider.selectedProduct!.name,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppTheme.porpraFosc,
        letterSpacing: -0.3,
        height: 1.2,
      ),
    );
  }

  Widget _buildPricing(VestidorProvider provider) {
    final variant = provider.activeVariant;
    final priceText = variant != null
        ? '${variant.retailPrice.replaceAll('.', ',')} ${variant.currency}'
        : provider.priceRange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.mostassa.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_rounded, color: AppTheme.mostassa, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              priceText,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.porpraFosc,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(VestidorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talla',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.porpraFosc,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.availableSizes.map((size) {
            final isSelected = provider.activeVariant?.sizeName == size;
            return _buildChip(
              label: size,
              isSelected: isSelected,
              onTap: () {
                final variant = provider.selectedVariants.firstWhere(
                  (v) => v.sizeName == size,
                  orElse: () => provider.selectedVariants.first,
                );
                provider.selectVariant(variant);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector(VestidorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.porpraFosc,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.availableColors.map((color) {
            final isSelected = provider.activeVariant?.colorName == color;
            return _buildChip(
              label: color,
              isSelected: isSelected,
              onTap: () {
                final variant = provider.selectedVariants.firstWhere(
                  (v) => v.colorName == color,
                  orElse: () => provider.selectedVariants.first,
                );
                provider.selectVariant(variant);
                // Reset galeria a primera imatge del nou color
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
                setState(() => _currentImageIndex = 0);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.porpraFosc : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.porpraFosc
                : AppTheme.grisPistacho.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.porpraFosc.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.porpraFosc,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfo(VestidorProvider provider) {
    final variant = provider.activeVariant;
    if (variant == null) return const SizedBox.shrink();

    final isAvailable = variant.availabilityStatus == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppTheme.verdeEncert.withValues(alpha: 0.08)
            : AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.info_outline,
            color: isAvailable ? AppTheme.verdeEncert : AppTheme.mostassa,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isAvailable ? 'Disponible' : 'Temporalment exhaurit',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isAvailable ? AppTheme.verdeEncert : AppTheme.mostassa,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalitat de compra properament disponible'),
              backgroundColor: AppTheme.mostassa,
            ),
          );
        },
        icon: const Icon(Icons.shopping_bag_rounded, size: 20),
        label: const Text('Sol\u00b7licitar compra'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.porpraFosc,
          foregroundColor: AppTheme.grisPistacho,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 4,
          shadowColor: AppTheme.porpraFosc.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.mostassa),
          SizedBox(height: 16),
          Text(
            'Carregant producte...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.grisBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.mostassa,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppTheme.grisBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
