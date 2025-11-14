import 'package:flutter/material.dart';

class HomeProvider with ChangeNotifier {
  // Dades de Mostra (Placeholders)
  final String featuredVisioningTitle = 'EL VISIONAT QUE ET FA CRÈIXER';
  final String featuredVisioningSubtitle =
      'Un contingut exclusiu narrat i comentat pels àrbitres del mateix partit';
  final String weeklyMatchTitle = 'EL PARTIT DE LA SETMANA';
  final String weeklyMatchDescription =
      'Analitzem els moments clau que defineixen el joc';
  final String weeklyMatchTeams = 'CB IPSI vs CB SALT';
  final String weeklyMatchScore = '2-1';
  final String weeklyMatchDate = '15 Oct 2024';
  final String weeklyMatchViews = '1,247 views';
  final String refereeProfileTitle = 'PERFIL DE L\'ÀRBITRE';
  final String refereeName = 'Marc Rodríguez';
  final String refereeCategory = 'Categoria A';
  final int analyzedMatches = 127;
  final String averagePrecision = '91%';
  final String currentLevel = 'Avançat';
  final String openVotingTitle = 'VOTACIÓ OBERTA PER AL PRÒXIM VISIONAT';

  // Lògica d'accés (per a la visibilitat de contingut de pagament)
  // Això es connectaria amb Firebase Auth/Firestore més endavant.
  final bool isSubscribed = true; // Exemple: l'usuari té subscripció

  // Mètode placeholder per carregar les dades
  void loadData() {
    // Aquí faríem les crides al FirestoreService
    notifyListeners();
  }
}
