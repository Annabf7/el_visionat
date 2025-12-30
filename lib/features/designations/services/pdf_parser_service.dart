import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Servei per parsejar PDFs de designació de la FCBQ
class PdfParserService {
  /// Extreu la informació d'un PDF de designació des d'un fitxer
  static Future<List<Map<String, String>>> parsePdfDesignation(
      File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      return parsePdfDesignationFromBytes(bytes);
    } catch (e) {
      developer.log('Error parsing PDF from file: $e', name: 'PdfParserService');
      rethrow;
    }
  }

  /// Extreu la informació d'un PDF de designació des de bytes
  static Future<List<Map<String, String>>> parsePdfDesignationFromBytes(
      Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extreure text de totes les pàgines
      String text = '';
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      for (int i = 0; i < document.pages.count; i++) {
        text += extractor.extractText(startPageIndex: i, endPageIndex: i);
        text += '\n';
      }

      document.dispose();

      // Parsejar el text del PDF
      return _extractMatchesFromText(text);
    } catch (e) {
      developer.log('Error parsing PDF from bytes: $e', name: 'PdfParserService');
      rethrow;
    }
  }

  /// Extreu els partits del text del PDF
  static List<Map<String, String>> _extractMatchesFromText(String text) {
    final List<Map<String, String>> matches = [];

    developer.log('Starting to parse PDF text', name: 'PdfParserService');

    // Dividir el text en línies
    final lines = text.split('\n');

    // Variables per acumular informació
    String? currentDate;
    String? currentMatchNumber;
    String? currentTime;
    String? currentLocal;
    String? currentVisitant;
    String? currentCategory;
    String? currentCompetition;
    String? currentRole;
    String? currentLocation;
    String? currentLocationAddress;
    String? currentRefereePartner;
    List<Map<String, String>>? currentAllMembers; // Emmagatzemar membres fins tenir currentRole

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      // Extreure data (format: "20/12/2025 · DISSABTE")
      if (line.contains('·') && _isDate(line)) {
        final parts = line.split('·');
        if (parts.isNotEmpty) {
          currentDate = parts[0].trim();
          developer.log('Found date: $currentDate', name: 'PdfParserService');
        }
      }

      // Extreure número de partit - més flexible
      if (line.contains('NÚM') && line.contains('PARTIT')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          final newMatchNumber = match.group(1);

          // IMPORTANT: Abans de començar un nou partit, guardar l'anterior si existeix
          if (currentDate != null &&
              currentMatchNumber != null &&
              currentTime != null &&
              currentLocal != null &&
              currentVisitant != null &&
              currentCategory != null &&
              currentRole != null) {

            _saveMatch(
              matches,
              currentDate,
              currentMatchNumber,
              currentTime,
              currentLocal,
              currentVisitant,
              currentCategory,
              currentCompetition,
              currentRole,
              currentLocation,
              currentLocationAddress,
              currentRefereePartner,
              currentAllMembers,
            );
          }

          currentMatchNumber = newMatchNumber;
          developer.log('Found match number: $currentMatchNumber', name: 'PdfParserService');

          // Reset variables per al nou partit
          currentLocal = null;
          currentVisitant = null;
          currentCategory = null;
          currentCompetition = null;
          currentRole = null;
          currentAllMembers = null;
          currentRefereePartner = null;
        }
      }

      // Extreure hora - més flexible
      if (line.contains('HORA')) {
        final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(line);
        if (match != null) {
          currentTime = match.group(1);
          developer.log('Found time: $currentTime', name: 'PdfParserService');
        }
      }

      // Extreure equips - cas especial: LOCAL i VISITANT en línies consecutives
      if (line.toUpperCase() == 'LOCAL' && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim().toUpperCase();

        // Si la següent línia és VISITANT, els equips estan a les 2 línies següents
        if (nextLine == 'VISITANT') {
          // Buscar els dos equips a les línies següents
          if (i + 2 < lines.length) {
            final localTeamLine = lines[i + 2].trim();
            if (localTeamLine.isNotEmpty && !_isHeaderLine(localTeamLine)) {
              currentLocal = localTeamLine;
              print('Found local team (consecutive): $currentLocal');
            }
          }
          if (i + 3 < lines.length) {
            final visitantTeamLine = lines[i + 3].trim();
            if (visitantTeamLine.isNotEmpty && !_isHeaderLine(visitantTeamLine)) {
              currentVisitant = visitantTeamLine;
              print('Found visitant team (consecutive): $currentVisitant');
            }
          }
        }
        // Si no, buscar només l'equip local
        else {
          for (int j = i + 1; j < lines.length && j < i + 3; j++) {
            final teamLine = lines[j].trim();
            if (teamLine.isNotEmpty && !_isHeaderLine(teamLine)) {
              currentLocal = teamLine;
              print('Found local team: $currentLocal');
              break;
            }
          }
        }
      }
      // Si VISITANT apareix sol (no precedit per LOCAL)
      else if (line.toUpperCase() == 'VISITANT' && (i == 0 || lines[i - 1].trim().toUpperCase() != 'LOCAL')) {
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          final teamLine = lines[j].trim();
          if (teamLine.isNotEmpty && !_isHeaderLine(teamLine)) {
            currentVisitant = teamLine;
            print('Found visitant team: $currentVisitant');
            break;
          }
        }
      }

      // Extreure categoria i competició - cas especial: poden estar en la mateixa línia o en línies adjacents
      if (line.toUpperCase() == 'CATEGORIA' && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim().toUpperCase();

        // Si la següent línia és COMPETICIÓ, categoria i competició estan en format taula
        if (nextLine == 'COMPETICIÓ') {
          // Buscar la línia amb els valors (línia i+2)
          if (i + 2 < lines.length) {
            final valuesLine = lines[i + 2].trim();

            // Intentar separar categoria i competició
            // Format típic: "C.C. PRIMERA CATEGORIA MASCULINA FASE PRÈVIA - 04"
            // O poden estar en línies separades

            // Primer, buscar si hi ha múltiples línies amb valors
            final categoryLine = valuesLine;
            String? competitionLine;

            if (i + 3 < lines.length) {
              final possibleCompLine = lines[i + 3].trim();
              if (possibleCompLine.isNotEmpty &&
                  !_isHeaderLine(possibleCompLine) &&
                  !possibleCompLine.contains('FUNCIÓ') &&
                  !possibleCompLine.contains('JORNADA')) {
                competitionLine = possibleCompLine;
              }
            }

            // Si no hi ha línia separada, intentar dividir la línia
            if (competitionLine == null && categoryLine.isNotEmpty) {
              // Buscar patrons comuns de competició: "FASE", "GRUP", "RONDA", etc.
              final faseMatch = RegExp(r'(FASE[^A-Z]*(?:PRÈVIA|REGULAR|FINAL)[^A-Z]*-[^A-Z]*\d+)', caseSensitive: false).firstMatch(categoryLine);
              final grupMatch = RegExp(r'(GRUP[^A-Z]*\d+)', caseSensitive: false).firstMatch(categoryLine);

              if (faseMatch != null) {
                currentCompetition = faseMatch.group(1)!.trim();
                currentCategory = categoryLine.substring(0, faseMatch.start).trim();
                developer.log('Found category and competition (split): $currentCategory | $currentCompetition', name: 'PdfParserService');
              } else if (grupMatch != null) {
                currentCompetition = grupMatch.group(1)!.trim();
                currentCategory = categoryLine.substring(0, grupMatch.start).trim();
                developer.log('Found category and competition (split): $currentCategory | $currentCompetition', name: 'PdfParserService');
              } else {
                // No s'ha pogut separar, assignar tot a categoria
                currentCategory = categoryLine;
                developer.log('Found category only: $currentCategory', name: 'PdfParserService');
              }
            } else if (competitionLine != null) {
              // Hi ha línies separades
              currentCategory = categoryLine;
              currentCompetition = competitionLine;
              developer.log('Found category and competition (separate lines): $currentCategory | $currentCompetition', name: 'PdfParserService');
            }
          }
        }
        // Si no, buscar normalment
        else {
          for (int j = i + 1; j < lines.length && j < i + 3; j++) {
            final catLine = lines[j].trim();
            if (catLine.isNotEmpty && !_isHeaderLine(catLine)) {
              currentCategory = catLine;
              developer.log('Found category: $currentCategory', name: 'PdfParserService');
              break;
            }
          }
        }
      }

      // Extreure competició (si no s'ha extret abans)
      if (line.toUpperCase() == 'COMPETICIÓ' && currentCompetition == null) {
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          final compLine = lines[j].trim();
          if (compLine.isNotEmpty && !compLine.contains('FUNCIÓ') && !compLine.contains('JORNADA')) {
            currentCompetition = compLine;
            developer.log('Found competition (standalone): $currentCompetition', name: 'PdfParserService');
            break;
          }
        }
      }

      // Extreure funció (rol) - buscar ÀRBITRE
      if (line.contains('ÀRBITRE')) {
        if (line.contains('AUXILIAR')) {
          currentRole = 'auxiliar';
          developer.log('Found role: auxiliar', name: 'PdfParserService');
        } else if (line.contains('PRINCIPAL')) {
          currentRole = 'principal';
          developer.log('Found role: principal', name: 'PdfParserService');
        }
      }

      // Extreure localització
      if ((line.contains('CIUTAT') || line.contains('PAVELLÓ') || line.contains('PAVELLO') ||
          line.contains('POLIESPORTIU') || line.contains('COMPLEX') ||
          line.contains('PARC') || line.contains('MUNICIPAL')) &&
          !line.contains('CATEGORIA')) {
        currentLocation = line;
        developer.log('Found location: $currentLocation', name: 'PdfParserService');
        // Buscar adreça
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.contains('NÚM')) {
            currentLocationAddress = nextLine;
            developer.log('Found address: $currentLocationAddress', name: 'PdfParserService');
          }
        }
      }

      // Extreure companys/companyes (DADES COMPANYS/ES)
      if (line.toUpperCase().contains('DADES') &&
          (line.toUpperCase().contains('COMPAN') || line.toUpperCase().contains('COMPANY'))) {

        // Llista de tots els membres (àrbitres i auxiliars de taula)
        List<Map<String, String>> allMembers = [];

        developer.log('Found DADES COMPANYS/ES section', name: 'PdfParserService');

        // Buscar tots els membres a les línies següents
        for (int j = i + 1; j < lines.length && j < i + 40; j++) {
          final memberLine = lines[j].trim();

          // Si arribem a la secció de substituts, sortir
          if (memberLine.toUpperCase().contains('ÀRBITRES') && memberLine.toUpperCase().contains('SUBSTITUTS')) {
            break;
          }

          // Detectar PRINCIPAL o AUXILIAR directament
          if (memberLine.toUpperCase() == 'PRINCIPAL' || memberLine.toUpperCase() == 'AUXILIAR') {
            final role = memberLine.toUpperCase() == 'PRINCIPAL' ? 'principal' : 'auxiliar';

            // Buscar el nom a la línia següent
            if (j + 1 < lines.length) {
              for (int k = j + 1; k < lines.length && k < j + 5; k++) {
                final nameLine = lines[k].trim();

                // Saltar línies buides i capçaleres
                if (nameLine.isEmpty ||
                    nameLine.toUpperCase().contains('TELÈFON') ||
                    nameLine.toUpperCase().contains('POBLACIÓ') ||
                    nameLine.toUpperCase().contains('FUNCIÓ') ||
                    nameLine.toUpperCase().contains('NOM I COGNOMS') ||
                    RegExp(r'^\d{9}$').hasMatch(nameLine)) {
                  continue;
                }

                // Extreure nom (amb o sense llicència)
                final nameMatch = RegExp(r'^([A-ZÀ-Ÿ][A-Za-zÀ-ÿ\s,]+)\s*(?:\(\d+\))?$').firstMatch(nameLine);

                if (nameMatch != null) {
                  final cleanName = nameMatch.group(1)!.trim();

                  if (cleanName.split(' ').length >= 2 || cleanName.contains(',')) {
                    allMembers.add({
                      'role': role,
                      'name': cleanName,
                    });
                    developer.log('Found referee $role: $cleanName', name: 'PdfParserService');
                    break;
                  }
                }
              }
            }
          }
          // Detectar ANOTADOR/A
          else if (memberLine.toUpperCase().contains('ANOTADOR/A')) {
            for (int k = j + 1; k < lines.length && k < j + 4; k++) {
              final nameLine = lines[k].trim();

              if (nameLine.isEmpty ||
                  nameLine.toUpperCase().contains('TELÈFON') ||
                  nameLine.toUpperCase().contains('POBLACIÓ') ||
                  nameLine.toUpperCase().contains('FUNCIÓ') ||
                  RegExp(r'^\d{9}$').hasMatch(nameLine)) {
                continue;
              }

              final nameMatch = RegExp(r'^([A-ZÀ-Ÿ][A-Za-zÀ-ÿ\s,]+)\s*(?:\(\d+\))?$').firstMatch(nameLine);
              if (nameMatch != null) {
                final cleanName = nameMatch.group(1)!.trim();
                if (cleanName.split(' ').length >= 2 || cleanName.contains(',')) {
                  allMembers.add({
                    'role': 'anotador',
                    'name': cleanName,
                  });
                  developer.log('Found anotador: $cleanName', name: 'PdfParserService');
                  break;
                }
              }
            }
          }
          // Detectar CRONOMETRADOR/A
          else if (memberLine.toUpperCase().contains('CRONOMETRADOR')) {
            for (int k = j + 1; k < lines.length && k < j + 4; k++) {
              final nameLine = lines[k].trim();

              if (nameLine.isEmpty ||
                  nameLine.toUpperCase().contains('TELÈFON') ||
                  nameLine.toUpperCase().contains('POBLACIÓ') ||
                  nameLine.toUpperCase().contains('FUNCIÓ') ||
                  RegExp(r'^\d{9}$').hasMatch(nameLine)) {
                continue;
              }

              final nameMatch = RegExp(r'^([A-ZÀ-Ÿ][A-Za-zÀ-ÿ\s,]+)\s*(?:\(\d+\))?$').firstMatch(nameLine);
              if (nameMatch != null) {
                final cleanName = nameMatch.group(1)!.trim();
                if (cleanName.split(' ').length >= 2 || cleanName.contains(',')) {
                  allMembers.add({
                    'role': 'cronometrador',
                    'name': cleanName,
                  });
                  developer.log('Found cronometrador: $cleanName', name: 'PdfParserService');
                  break;
                }
              }
            }
          }
          // Detectar OPERADOR/A RLL
          else if (memberLine.toUpperCase().contains('OPERADOR')) {
            for (int k = j + 1; k < lines.length && k < j + 4; k++) {
              final nameLine = lines[k].trim();

              if (nameLine.isEmpty ||
                  nameLine.toUpperCase().contains('TELÈFON') ||
                  nameLine.toUpperCase().contains('POBLACIÓ') ||
                  nameLine.toUpperCase().contains('FUNCIÓ') ||
                  RegExp(r'^\d{9}$').hasMatch(nameLine)) {
                continue;
              }

              final nameMatch = RegExp(r'^([A-ZÀ-Ÿ][A-Za-zÀ-ÿ\s,]+)\s*(?:\s*\(\d+\))?$').firstMatch(nameLine);
              if (nameMatch != null) {
                final cleanName = nameMatch.group(1)!.trim();
                if (cleanName.split(' ').length >= 2 || cleanName.contains(',')) {
                  allMembers.add({
                    'role': 'operador',
                    'name': cleanName,
                  });
                  developer.log('Found operador: $cleanName', name: 'PdfParserService');
                  break;
                }
              }
            }
          }
        }

        // Emmagatzemar els membres per processar-los després (quan tinguem currentRole)
        currentAllMembers = allMembers;
        developer.log('Stored ${allMembers.length} members for later processing', name: 'PdfParserService');
      }

    }

    // Guardar l'últim partit si existeix
    if (currentDate != null &&
        currentMatchNumber != null &&
        currentTime != null &&
        currentLocal != null &&
        currentVisitant != null &&
        currentCategory != null &&
        currentRole != null) {
      _saveMatch(
        matches,
        currentDate,
        currentMatchNumber,
        currentTime,
        currentLocal,
        currentVisitant,
        currentCategory,
        currentCompetition,
        currentRole,
        currentLocation,
        currentLocationAddress,
        currentRefereePartner,
        currentAllMembers,
      );
    }

    developer.log('Parsed ${matches.length} matches from PDF',
                  name: 'PdfParserService');
    return matches;
  }

  /// Guarda un partit a la llista de partits
  static void _saveMatch(
    List<Map<String, String>> matches,
    String currentDate,
    String currentMatchNumber,
    String currentTime,
    String currentLocal,
    String currentVisitant,
    String currentCategory,
    String? currentCompetition,
    String currentRole,
    String? currentLocation,
    String? currentLocationAddress,
    String? currentRefereePartner,
    List<Map<String, String>>? currentAllMembers,
  ) {
    developer.log('Saving match: #$currentMatchNumber', name: 'PdfParserService');

    // Processar els companys si existeixen
    String? finalRefereePartner = currentRefereePartner;

    if (currentAllMembers != null && currentAllMembers.isNotEmpty) {
      List<String> partners = [];

      developer.log('Processing ${currentAllMembers.length} members with role: $currentRole', name: 'PdfParserService');

      if (currentRole == 'principal' || currentRole == 'auxiliar') {
        // Si ets àrbitre, afegir l'altre àrbitre
        for (var member in currentAllMembers) {
          if (member['role'] != currentRole &&
              (member['role'] == 'principal' || member['role'] == 'auxiliar')) {
            String roleLabel = member['role'] == 'principal' ? 'Principal' : 'Auxiliar';
            partners.add('${member['name']} ($roleLabel)');
            developer.log('Added referee partner: ${member['name']} ($roleLabel)', name: 'PdfParserService');
          }
        }
      } else if (currentRole == 'anotador' || currentRole == 'cronometrador' || currentRole == 'operador') {
        // Si ets auxiliar de taula, afegir els altres membres de taula
        for (var member in currentAllMembers) {
          if (member['role'] != currentRole &&
              (member['role'] == 'anotador' ||
               member['role'] == 'cronometrador' ||
               member['role'] == 'operador')) {
            String roleLabel = member['role'] == 'anotador' ? 'Anotador/a' :
                              member['role'] == 'cronometrador' ? 'Cronometrador/a' :
                              'Operador/a';
            partners.add('${member['name']} ($roleLabel)');
            developer.log('Added table partner: ${member['name']} ($roleLabel)', name: 'PdfParserService');
          }
        }
      }

      if (partners.isNotEmpty) {
        finalRefereePartner = partners.join(', ');
        developer.log('Final partners: $finalRefereePartner', name: 'PdfParserService');
      }
    }

    matches.add({
      'date': currentDate,
      'matchNumber': currentMatchNumber,
      'time': currentTime,
      'localTeam': currentLocal,
      'visitantTeam': currentVisitant,
      'category': currentCategory,
      'competition': currentCompetition ?? '',
      'role': currentRole,
      'location': currentLocation ?? '',
      'locationAddress': currentLocationAddress ?? '',
      'refereePartner': finalRefereePartner ?? '',
    });
  }

  /// Comprova si una línia conté una data vàlida
  static bool _isDate(String line) {
    return RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(line);
  }

  /// Comprova si una línia és una capçalera (no un nom d'equip o categoria)
  static bool _isHeaderLine(String line) {
    final upper = line.toUpperCase();
    return upper.startsWith('LOCAL') ||
        upper.startsWith('VISITANT') ||
        upper.startsWith('CATEGORIA') ||
        upper.startsWith('COMPETICIÓ') ||
        upper.startsWith('FUNCIÓ') ||
        upper.startsWith('JORNADA') ||
        upper.startsWith('NÚM') ||
        upper.startsWith('HORA') ||
        _isDate(line);
  }

  /// Converteix una data en format "DD/MM/YYYY" a DateTime
  static DateTime? parseDate(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) return null;

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      developer.log('Error parsing date: $e', name: 'PdfParserService');
      return null;
    }
  }
}