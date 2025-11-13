import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class RefereeCommentCard extends StatelessWidget {
  const RefereeCommentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grisBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: AppTheme.porpraFosc,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Valoració final del partit',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.lilaMitja, AppTheme.mostassa],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'MR',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marc Ribas',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Àrbitre principal',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.porpraFosc,
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grisBody,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: AppTheme.porpraFosc.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: AppTheme.lilaMitja,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comentaris tècnics',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.lilaMitja,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Teniu especial cura en el criteri de contactes en la pintura. El joc local té una tendència clara a utilitzar la cola en el bloqueig indirecte. Cal anticipar el moviment del jugador i estar present a l\'acció abans que arribui la situació. Així la lectura prèvia serà més ràpida que si apareguem al contacte incidental. Això ens donarà un posicionament excel·lent de l\'àrbitre de cua.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisPistacho,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: AppTheme.mostassa),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Comentaris verificats per l\'equip tècnic arbitral oficial.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
