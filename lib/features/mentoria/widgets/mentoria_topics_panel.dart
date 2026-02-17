import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class MentoriaTopicsPanel extends StatefulWidget {
  final Set<String> selectedTopics;
  final Function(Set<String>) onTopicsChanged;

  const MentoriaTopicsPanel({
    super.key,
    required this.selectedTopics,
    required this.onTopicsChanged,
  });

  @override
  State<MentoriaTopicsPanel> createState() => _MentoriaTopicsPanelState();
}

class _MentoriaTopicsPanelState extends State<MentoriaTopicsPanel> {
  // Llista de temes predefinits
  final List<String> _topics = [
    'Mecànica i Senyalització',
    'Violacions (Passes, Dobles)',
    'Faltes de contacte',
    'Gestió de partit',
    'Comunicació amb entrenadors',
    'Treball en equip (2PO/3PO)',
    'Reglament (Canvis recents)',
    'Criteria falten antiesportives',
    'Control de rellotge i taula',
    'Actitud i presència',
  ];

  // Estat de selecció (ara ve del pare)
  // final Set<String> _selectedTopics = {}; // Eliminat perquè ara és stateless respecte l'estat, però stateful per la UI interna si calgués animacions, etc.
  // En realitat, podríem fer-ho StatelessWidget, però mantenim State per si volem afegir cerques o filtres locals més endavant.

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grisPistacho.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppTheme.mostassa),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Temàtiques a tractar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona els punts que vols treballar en les pròximes sessions.',
            style: TextStyle(fontSize: 12, color: AppTheme.grisBody),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = widget.selectedTopics.contains(topic);
                return CheckboxListTile(
                  title: Text(
                    topic,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppTheme.porpraFosc : Colors.black87,
                    ),
                  ),
                  value: isSelected,
                  activeColor: AppTheme.porpraFosc,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    final newSet = Set<String>.from(widget.selectedTopics);
                    if (val == true) {
                      newSet.add(topic);
                    } else {
                      newSet.remove(topic);
                    }
                    widget.onTopicsChanged(newSet);
                  },
                );
              },
            ),
          ),
          const Divider(),
          if (widget.selectedTopics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${widget.selectedTopics.length} temes seleccionats',
                style: const TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
