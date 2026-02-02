import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/vestidor_product.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/features/vestidor/providers/vestidor_provider.dart';

/// Card de producte per a la graella de la botiga
class ProductCard extends StatelessWidget {
  final VestidorProduct product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imatge del producte (ocupa la major part de la card)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF0F0F0), // gris clar
                child:
                    Provider.of<VestidorProvider>(
                          context,
                          listen: false,
                        ).getCustomThumbnail(product) !=
                        null
                    ? Image.network(
                        Provider.of<VestidorProvider>(
                          context,
                          listen: false,
                        ).getCustomThumbnail(product)!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _buildImagePlaceholder();
                        },
                        errorBuilder: (_, error, stackTrace) {
                          debugPrint(
                            '[ProductCard ERROR] Image.network error: $error',
                          );
                          return _buildImageFallback();
                        },
                      )
                    : _buildImageFallback(),
              ),
            ),
            // Info del producte
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nom del producte
                    Flexible(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grisPistacho,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Variants count + fletxa
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lilaMitja.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.variantsCount} ${product.variantsCount == 1 ? 'variant' : 'variants'}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lilaMitja.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.grisBody.withValues(alpha: 0.15),
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
  }

  Widget _buildImageFallback() {
    return Container(
      color: AppTheme.porpraFosc.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 48,
          color: AppTheme.lilaMitja.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
