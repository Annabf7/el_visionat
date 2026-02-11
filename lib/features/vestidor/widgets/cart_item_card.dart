import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/cart_item.dart';

/// Card compacte horitzontal per un element del carretó
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.syncVariantId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.grisPistacho.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imatge producte
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.12),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                  if (item.color.isNotEmpty || item.size.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [item.color, item.size]
                          .where((s) => s.isNotEmpty)
                          .join(' / '),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} ${item.currency}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Controls de quantitat
            _buildQuantityControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.porpraFosc.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove_rounded,
            onTap: () => onQuantityChanged(item.quantity - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.porpraFosc,
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add_rounded,
            onTap: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.porpraFosc,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 28,
          color: AppTheme.lilaMitja.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
