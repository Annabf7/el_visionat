import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class UserAnalysisCard extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTextChanged;

  const UserAnalysisCard({
    super.key,
    required this.text,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white, // D9D9D9
        borderRadius: BorderRadius.circular(12),
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
                  Icons.rate_review,
                  color: AppTheme.porpraFosc,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'El teu anàlisi',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.porpraFosc,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: AppTheme.porpraFosc.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Comparteix les teves observacions i reflexions sobre l\'actuació arbitral...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: AppTheme.grisBody.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  maxLines: 8,
                  onChanged: onTextChanged,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.porpraFosc,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => debugPrint('Add contribution'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lilaMitja,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppTheme.grisPistacho,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.grisBody.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Les teves aportacions s\'inclouran a l\'apartat de valoracions col·lectives per enriquir l\'anàlisi arbitral.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisBody.withValues(alpha: 0.8),
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
