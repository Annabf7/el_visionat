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

    // Mapa de rols per número de partit (extret del resum inicial)
    final Map<String, String> rolesByMatchNumber = {};
    String? lastSummaryMatchNumber;

    // Zona de detecció del pavelló (entre "ENCONTRES DEL DIA" i primer "NÚM.PARTIT")
    bool inVenueZone = false;
    String? summaryLocation;
    String? summaryLocationAddress;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      // Extreure data - dos formats possibles:
      // 1. "20/12/2025 · DISSABTE" (resum inicial)
      // 2. "DISSABTE 20/12/2025 - 17:45" (cada partit individual amb hora integrada)
      if (_isDate(line)) {
        // Format 1: "20/12/2025 · DISSABTE"
        if (line.contains('·') && !line.contains('CODINA') && !line.contains('CARRER') && !line.contains('AVINGUDA')) {
          final parts = line.split('·');
          if (parts.isNotEmpty) {
            currentDate = parts[0].trim();
            developer.log('Found date (format 1): $currentDate', name: 'PdfParserService');
          }
          inVenueZone = true;
        }
        // Format 2: "DISSABTE 20/12/2025 - 17:45"
        else {
          final dateTimeMatch = RegExp(r'(\d{2}/\d{2}/\d{4})\s*-\s*(\d{1,2}:\d{2})').firstMatch(line);
          if (dateTimeMatch != null) {
            final detectedTime = dateTimeMatch.group(2);

            // Si detectem una nova hora DESPRÉS d'haver començat un partit,
            // vol dir que és l'hora del SEGÜENT partit
            // En aquest cas, guardem el partit actual abans de canviar l'hora
            if (currentTime != null && detectedTime != currentTime && currentMatchNumber != null) {

              // Guardar el partit actual abans de canviar l'hora
              if (currentDate != null &&
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

                // Reset després de guardar
                currentMatchNumber = null;
                currentLocal = null;
                currentVisitant = null;
                currentCategory = null;
                currentCompetition = null;
                currentAllMembers = null;
                currentRefereePartner = null;
              }
            }

            currentDate = dateTimeMatch.group(1);
            currentTime = detectedTime;
            developer.log('Found date and time (format 2): $currentDate at $currentTime', name: 'PdfParserService');
          } else {
            // Si no té hora, només extreure la data
            final dateMatch = RegExp(r'(\d{2}/\d{2}/\d{4})').firstMatch(line);
            if (dateMatch != null) {
              currentDate = dateMatch.group(1);
              developer.log('Found date only (format 2): $currentDate', name: 'PdfParserService');
            }
          }
        }
      }

      // Detectar pavelló en la zona del resum (entre la data i el primer NÚM.PARTIT)
      if (inVenueZone) {
        final upperLineVenue = line.toUpperCase();
        if (upperLineVenue.contains('NÚM') && upperLineVenue.contains('PARTIT')) {
          // Fi de la zona del pavelló - primer NÚM.PARTIT trobat
          inVenueZone = false;
          // Aplicar pavelló del resum com a localització per defecte
          if (summaryLocation != null) {
            currentLocation = summaryLocation;
            currentLocationAddress = summaryLocationAddress ?? summaryLocation;
          }
        } else if (!_isDate(line) &&
            !upperLineVenue.contains('TOTAL PARTITS') &&
            !upperLineVenue.contains('ENCONTRES') &&
            !upperLineVenue.contains('DESIGNADA') &&
            !upperLineVenue.contains('EN/NA') &&
            !upperLineVenue.contains('COMITÈ') &&
            !upperLineVenue.contains('BORRAS') &&
            !upperLineVenue.contains('HAS ESTAT')) {
          // Detectar adreça (té codi postal de 5 dígits)
          if (RegExp(r'\d{5}').hasMatch(line)) {
            summaryLocationAddress = line;
          } else {
            summaryLocation ??= line;
          }
        }
      }

      // Detectar NÚM.PARTIT del resum (no DADES PARTIT) → guardar rol per partit
      if (line.contains('NÚM') && line.contains('PARTIT') && !line.contains('DADES')) {
        final match = RegExp(r'(\d{4,})').firstMatch(line);
        if (match != null) {
          lastSummaryMatchNumber = match.group(1);
        }
      }

      // Extreure funció (rol) del resum → associar amb número de partit del resum
      if (line.contains('ÀRBITRE') && lastSummaryMatchNumber != null && !line.contains('DADES') && !line.contains('COMPANYS')) {
        if (line.contains('AUXILIAR')) {
          rolesByMatchNumber[lastSummaryMatchNumber] = 'auxiliar';
        } else if (line.contains('PRINCIPAL')) {
          rolesByMatchNumber[lastSummaryMatchNumber] = 'principal';
        }
      }

      // Extreure número de partit - NOMÉS des de "DADES PARTIT" (no des del resum)
      if (line.contains('DADES') && line.contains('PARTIT') && !line.contains('COMPAN')) {
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
          currentAllMembers = null;
          currentRefereePartner = null;

          // Assignar rol del resum si existeix (cada partit pot tenir rol diferent)
          if (rolesByMatchNumber.containsKey(currentMatchNumber)) {
            currentRole = rolesByMatchNumber[currentMatchNumber];
          }
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
          // Busquem fins a 5 línies endavant per trobar el nom d'equip vàlid
          for (int j = i + 2; j < lines.length && j < i + 7; j++) {
            final localTeamLine = lines[j].trim();
            developer.log('Checking line $j for local team: "$localTeamLine"', name: 'PdfParserService');
            if (localTeamLine.isNotEmpty &&
                !_isHeaderLine(localTeamLine) &&
                !localTeamLine.toUpperCase().contains('SAMARRETA') &&
                !localTeamLine.toUpperCase().contains('PANTALÓ') &&
                currentLocal == null) {
              currentLocal = localTeamLine;
              developer.log('Found local team (consecutive): $currentLocal', name: 'PdfParserService');
              break;
            }
          }
          // Buscar equip visitant després del local
          for (int j = i + 3; j < lines.length && j < i + 8; j++) {
            final visitantTeamLine = lines[j].trim();
            developer.log('Checking line $j for visitant team: "$visitantTeamLine"', name: 'PdfParserService');
            if (visitantTeamLine.isNotEmpty &&
                !_isHeaderLine(visitantTeamLine) &&
                !visitantTeamLine.toUpperCase().contains('SAMARRETA') &&
                !visitantTeamLine.toUpperCase().contains('PANTALÓ') &&
                visitantTeamLine != currentLocal &&
                currentVisitant == null) {
              currentVisitant = visitantTeamLine;
              developer.log('Found visitant team (consecutive): $currentVisitant', name: 'PdfParserService');
              break;
            }
          }
        }
        // Si no, buscar només l'equip local
        else {
          for (int j = i + 1; j < lines.length && j < i + 5; j++) {
            final teamLine = lines[j].trim();
            if (teamLine.isNotEmpty &&
                !_isHeaderLine(teamLine) &&
                !teamLine.toUpperCase().contains('SAMARRETA') &&
                !teamLine.toUpperCase().contains('PANTALÓ')) {
              currentLocal = teamLine;
              developer.log('Found local team: $currentLocal', name: 'PdfParserService');
              break;
            }
          }
        }
      }
      // Si VISITANT apareix sol (no precedit per LOCAL)
      else if (line.toUpperCase() == 'VISITANT' && (i == 0 || lines[i - 1].trim().toUpperCase() != 'LOCAL')) {
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final teamLine = lines[j].trim();
          if (teamLine.isNotEmpty &&
              !_isHeaderLine(teamLine) &&
              !teamLine.toUpperCase().contains('SAMARRETA') &&
              !teamLine.toUpperCase().contains('PANTALÓ')) {
            currentVisitant = teamLine;
            developer.log('Found visitant team: $currentVisitant', name: 'PdfParserService');
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

      // Extreure funció (rol) - fallback si no s'ha obtingut del resum
      // Només assignar si no tenim rol (el resum ja l'ha assignat via rolesByMatchNumber)
      if (line.contains('ÀRBITRE') && currentRole == null &&
          currentMatchNumber != null && !line.contains('COMPANYS')) {
        if (line.contains('AUXILIAR')) {
          currentRole = 'auxiliar';
          developer.log('Found role: auxiliar', name: 'PdfParserService');
        } else if (line.contains('PRINCIPAL')) {
          currentRole = 'principal';
          developer.log('Found role: principal', name: 'PdfParserService');
        }
      }

      // Extreure localització
      // Buscar paraules clau de pavellons (incloent abreviatures com PAV., POL., C.E.)
      final upperLine = line.toUpperCase();
      final isLocationLine = (
          upperLine.contains('CIUTAT') ||
          upperLine.contains('PAVELLÓ') ||
          upperLine.contains('PAVELLO') ||
          upperLine.contains('POLIESPORTIU') ||
          upperLine.contains('COMPLEX') ||
          upperLine.contains('PARC') ||
          upperLine.contains('MUNICIPAL') ||
          // Abreviatures comunes
          RegExp(r'\bPAV\.?\s*MUN', caseSensitive: false).hasMatch(line) ||
          RegExp(r'\bPAV\.?\s*ESP', caseSensitive: false).hasMatch(line) ||
          RegExp(r'\bPAV\.?\s*POL', caseSensitive: false).hasMatch(line) ||
          RegExp(r'\bPOL\.?\s*MUN', caseSensitive: false).hasMatch(line) ||
          RegExp(r'\bC\.?\s*E\.?\s*M', caseSensitive: false).hasMatch(line) ||
          RegExp(r'\bPAV\.', caseSensitive: false).hasMatch(line)
      ) && !upperLine.contains('CATEGORIA');

      if (isLocationLine) {
        currentLocation = line;
        currentLocationAddress = line; // La línia ja conté l'adreça completa
        developer.log('Found location: $currentLocation', name: 'PdfParserService');
        // Buscar adreça addicional a la línia següent (si existeix)
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Si la línia següent és una adreça (no és una capçalera ni està buida)
          if (nextLine.isNotEmpty &&
              !nextLine.contains('NÚM') &&
              !nextLine.toUpperCase().contains('CATEGORIA') &&
              !nextLine.toUpperCase().contains('DATA') &&
              !nextLine.toUpperCase().contains('HORA')) {
            // Concatenar amb la localització si sembla una adreça
            if (nextLine.contains(',') || RegExp(r'\d{5}').hasMatch(nextLine)) {
              currentLocationAddress = '$line, $nextLine';
              developer.log('Found extended address: $currentLocationAddress', name: 'PdfParserService');
            }
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
                    final phone = _extractPhone(lines, k);
                    allMembers.add({
                      'role': role,
                      'name': cleanName,
                      if (phone != null) 'phone': phone,
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
                  final phone = _extractPhone(lines, k);
                  allMembers.add({
                    'role': 'anotador',
                    'name': cleanName,
                    if (phone != null) 'phone': phone,
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
                  final phone = _extractPhone(lines, k);
                  allMembers.add({
                    'role': 'cronometrador',
                    'name': cleanName,
                    if (phone != null) 'phone': phone,
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
                  final phone = _extractPhone(lines, k);
                  allMembers.add({
                    'role': 'operador',
                    'name': cleanName,
                    if (phone != null) 'phone': phone,
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
    String? partnerPhone;

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
            partnerPhone = member['phone'];
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
      } else {
      }
    } else {
    }

    // Determinar si és arbitratge individual o a dobles
    bool isDoubleReferee = false;
    if (currentAllMembers != null && currentAllMembers.isNotEmpty) {
      // Comprovar si hi ha TANT principal COM auxiliar (arbitratge a dobles)
      bool hasPrincipal = currentAllMembers.any((m) => m['role'] == 'principal');
      bool hasAuxiliar = currentAllMembers.any((m) => m['role'] == 'auxiliar');

      // Només és arbitratge a dobles si hi ha TOTS DOS rols
      isDoubleReferee = hasPrincipal && hasAuxiliar;

      developer.log('Referee type: ${isDoubleReferee ? "double" : "individual"}', name: 'PdfParserService');
    } else {
      // Si no hi ha membres, és arbitratge individual
      developer.log('Referee type: individual (no members)', name: 'PdfParserService');
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
      'refereePartnerPhone': partnerPhone ?? '',
      'isDoubleReferee': isDoubleReferee.toString(),
    });
  }

  /// Comprova si una línia conté una data vàlida
  static bool _isDate(String line) {
    return RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(line);
  }

  /// Comprova si una línia és una capçalera (no un nom d'equip o categoria)
  static bool _isHeaderLine(String line) {
    final upper = line.toUpperCase();

    // Paraules clau que indiquen que NO és un nom d'equip
    final invalidTeamNames = [
      'LOCAL',
      'VISITANT',
      'CATEGORIA',
      'COMPETICIÓ',
      'FUNCIÓ',
      'JORNADA',
      'NÚM',
      'HORA',
      'SAMARRETA',        // Secció d'uniformes
      'PANTALÓ',          // Pantalons
      'MITJÓ',            // Mitjons
      'CALCETÍN',         // Mitjons (espanyol)
      'DADES',            // Capçalera de seccions
      'COLOR',            // Colors d'uniformes
    ];

    // Comprovar si la línia comença amb alguna paraula invàlida
    for (final invalid in invalidTeamNames) {
      if (upper.startsWith(invalid) || upper == invalid) {
        return true;
      }
    }

    // Comprovar si conté NOMÉS paraules d'uniformes (colors típics)
    final uniformColors = ['BLANC', 'NEGRE', 'VERMELL', 'BLAU', 'VERD', 'GROC', 'TARONJA', 'ROSA', 'GRIS', 'MARRÓ'];
    final words = upper.split(RegExp(r'\s+'));
    if (words.every((word) => uniformColors.contains(word) || word.isEmpty)) {
      return true;
    }

    // Comprovar si és una data
    return _isDate(line);
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

  /// Extreu el telèfon de les línies següents al nom d'un membre
  static String? _extractPhone(List<String> lines, int nameLineIndex) {
    for (int p = nameLineIndex + 1; p < lines.length && p < nameLineIndex + 4; p++) {
      final phoneLine = lines[p].trim();
      final phoneMatch = RegExp(r'^(\d{9})\b').firstMatch(phoneLine);
      if (phoneMatch != null) {
        return phoneMatch.group(1);
      }
    }
    return null;
  }
}