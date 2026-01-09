// Script per testejar forceProcessWinner amb la Jornada 13
// Executa aquest fitxer des de l'app o com a script separat

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Inicialitza Firebase
  await Firebase.initializeApp();

  print('🏀 Forçant processament del guanyador de la Jornada 13...\n');

  try {
    // Crida la funció forceProcessWinner
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('forceProcessWinner')
        .call({'jornada': 13});

    print('✅ Resultat:');
    print(result.data);

    if (result.data['success'] == true) {
      print('\n🎉 Processament completat amb èxit!');
      print(result.data['message']);

      if (result.data['data'] != null) {
        final focusData = result.data['data'] as Map<String, dynamic>;
        print('\n👥 Equip Arbitral:');

        final refereeInfo = focusData['refereeInfo'] as Map<String, dynamic>?;
        if (refereeInfo != null) {
          print('  Àrbitre Principal: ${refereeInfo['principal'] ?? 'No trobat'}');
          print('  Àrbitre Auxiliar: ${refereeInfo['auxiliar'] ?? 'No trobat'}');

          final tableOfficials = refereeInfo['tableOfficials'] as List<dynamic>?;
          if (tableOfficials != null && tableOfficials.isNotEmpty) {
            print('  Oficials de taula:');
            for (var official in tableOfficials) {
              final role = official['role'];
              final name = official['name'];
              print('    - $role: $name');
            }
          }

          print('\n📋 Font: ${refereeInfo['source']}');
          print('🔗 URL Acta: ${refereeInfo['actaUrl']}');
        } else {
          print('  ⚠️ No hi ha informació d\'àrbitres');
        }

        print('\n🏆 Partit guanyador:');
        final winningMatch = focusData['winningMatch'] as Map<String, dynamic>?;
        if (winningMatch != null) {
          final home = winningMatch['home'] as Map<String, dynamic>?;
          final away = winningMatch['away'] as Map<String, dynamic>?;
          print('  ${home?['teamNameDisplay']} vs ${away?['teamNameDisplay']}');
          print('  ${winningMatch['dateDisplay']}');
        }

        print('\n📊 Total vots: ${focusData['totalVotes']}');
        print('📅 Jornada: ${focusData['jornada']}');
        print('🔄 Estat: ${focusData['status']}');
      }
    } else {
      print('\n❌ Error: ${result.data['message']}');
    }
  } catch (e) {
    print('❌ Error executant la funció: $e');
  }
}
