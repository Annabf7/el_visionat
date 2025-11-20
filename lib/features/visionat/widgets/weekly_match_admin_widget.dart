import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_match_provider.dart';

/// Widget d'administració per veure info del partit de la setmana
/// 
/// Mostra l'àrbitre actual i permet recarregar les dades
class WeeklyMatchAdminWidget extends StatelessWidget {
  const WeeklyMatchAdminWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyMatchProvider>(
      builder: (context, matchProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚙️ Partit de la Setmana - Admin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (matchProvider.isLoading) 
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Carregant àrbitre...'),
                    ],
                  )
                else if (matchProvider.hasError) 
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${matchProvider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                else if (matchProvider.currentReferee != null) 
                  Column(
                    children: [
                      _buildInfoRow('Àrbitre', matchProvider.refereeName),
                      _buildInfoRow('Categoria', matchProvider.refereeCategory),
                      _buildInfoRow('Llicència', matchProvider.currentReferee!.licenseId),
                      _buildInfoRow('Partit', matchProvider.matchTitle),
                    ],
                  )
                else 
                  const Text('No hi ha dades de l\'àrbitre'),
                
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => matchProvider.refreshReferee(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Recarregar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}