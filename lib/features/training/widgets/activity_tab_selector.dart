import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_controller.dart';

/// Widget que mostra les pestanyes per seleccionar l'activitat actual.
class ActivityTabSelector extends StatelessWidget {
  const ActivityTabSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityControllerProvider>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: TabBar(
            isScrollable: true,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
            ),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            tabs: List.generate(
              controller.activities.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Tab(text: 'Activitat ${i + 1}'),
              ),
            ),
            onTap: (index) {
              controller.selectActivity(index);
            },
          ),
        );
      },
    );
  }
}
