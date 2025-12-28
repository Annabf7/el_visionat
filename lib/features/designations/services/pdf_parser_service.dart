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

      // Extreure equips - buscar després de LOCAL/VISITANT
      if (line.toUpperCase() == 'LOCAL') {
        // Buscar equip local en les següents línies (pot estar més endavant)
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final teamLine = lines[j].trim();
          if (teamLine.isNotEmpty &&
              !teamLine.contains('CATEGORIA') &&
              !teamLine.contains('COMPETICIÓ') &&
              !teamLine.contains('FUNCIÓ') &&
              !teamLine.contains('SAMARRETA')) {
            currentLocal = teamLine;
            developer.log('Found local team: $currentLocal', name: 'PdfParserService');
            break;
          }
        }
      }

      if (line.toUpperCase() == 'VISITANT') {
        // Buscar equip visitant en les següents línies
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final teamLine = lines[j].trim();
          if (teamLine.isNotEmpty &&
              !teamLine.contains('CATEGORIA') &&
              !teamLine.contains('COMPETICIÓ') &&
              !teamLine.contains('FUNCIÓ') &&
              !teamLine.contains('SAMARRETA')) {
            currentVisitant = teamLine;
            developer.log('Found visitant team: $currentVisitant', name: 'PdfParserService');
            break;
          }
        }
      }

      // Extreure categoria
      if (line.toUpperCase() == 'CATEGORIA') {
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          final catLine = lines[j].trim();
          if (catLine.isNotEmpty && !catLine.contains('COMPETICIÓ')) {
            currentCategory = catLine;
            developer.log('Found category: $currentCategory', name: 'PdfParserService');
            break;
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
      if ((line.contains('CIUTAT') || line.contains('PAVELLÓ') ||
          line.contains('POLIESPORTIU') || line.contains('COMPLEX')) &&
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