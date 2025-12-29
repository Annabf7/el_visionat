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
    print('PDF TEXT START ==================');
    print(text);
    print('PDF TEXT END ====================');

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
          currentMatchNumber = match.group(1);
          developer.log('Found match number: $currentMatchNumber', name: 'PdfParserService');

          // IMPORTANT: Reset equips quan comencem un nou partit
          // Això evita que s'arrosseguin valors del partit anterior
          currentLocal = null;
          currentVisitant = null;
          currentCategory = null;
          currentCompetition = null;
          currentRole = null;
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

      // Extreure categoria - cas especial: CATEGORIA i COMPETICIÓ en línies consecutives
      if (line.toUpperCase() == 'CATEGORIA' && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim().toUpperCase();

        // Si la següent línia és COMPETICIÓ, la categoria està 2 línies més avall
        if (nextLine == 'COMPETICIÓ') {
          // Buscar la categoria a partir de la línia i+2
          for (int j = i + 2; j < lines.length && j < i + 5; j++) {
            final catLine = lines[j].trim();
            if (catLine.isNotEmpty && !_isHeaderLine(catLine)) {
              currentCategory = catLine;
              print('Found category (after COMPETICIÓ): $currentCategory');
              break;
            }
          }
        }
        // Si no, buscar normalment
        else {
          for (int j = i + 1; j < lines.length && j < i + 3; j++) {
            final catLine = lines[j].trim();
            if (catLine.isNotEmpty && !_isHeaderLine(catLine)) {
              currentCategory = catLine;
              print('Found category: $currentCategory');
              break;
            }
          }
        }
      }

      // Extreure competició
      if (line.toUpperCase() == 'COMPETICIÓ') {
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          final compLine = lines[j].trim();
          if (compLine.isNotEmpty && !compLine.contains('FUNCIÓ') && !compLine.contains('JORNADA')) {
            currentCompetition = compLine;
            developer.log('Found competition: $currentCompetition', name: 'PdfParserService');
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

      // Quan tenim tota la informació mínima d'un partit, el guardem
      if (currentDate != null &&
          currentMatchNumber != null &&
          currentTime != null &&
          currentLocal != null &&
          currentVisitant != null &&
          currentCategory != null &&
          currentRole != null) {

        developer.log('Saving match: #$currentMatchNumber', name: 'PdfParserService');

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
        });

        // Reset variables per al següent partit (mantenim data i ubicació)
        currentMatchNumber = null;
        currentTime = null;
        currentLocal = null;
        currentVisitant = null;
        currentCategory = null;
        currentCompetition = null;
        currentRole = null;
      }
    }

    developer.log('Parsed ${matches.length} matches from PDF',
                  name: 'PdfParserService');
    return matches;
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