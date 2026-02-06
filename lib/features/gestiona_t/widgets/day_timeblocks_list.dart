import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import 'timeblock_card.dart';

/// Llista de blocs del dia seleccionat
class DayTimeblocksList extends StatelessWidget {
  final List<TimeBlock> blocks;
  final DateTime selectedDay;

  const DayTimeblocksList({
    super.key,
    required this.blocks,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("EEEE, d 'de' MMMM", 'ca_ES');
    final isToday = DateUtils.isSameDay(selectedDay, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capçalera amb la data
        Row(
          children: [
            Text(
              dateFormat.format(selectedDay),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.verdeEncert,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Avui',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${blocks.length} blocs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grisPistacho.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Llista de blocs o estat buit
        Expanded(
          child: blocks.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    return TimeblockCard(block: blocks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppTheme.grisPistacho.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tens blocs per aquest dia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prem + per afegir-ne un o\n🌙 per planificar demà',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grisPistacho.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
