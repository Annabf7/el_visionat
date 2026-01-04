import 'dart:io';
import 'lib/features/designations/services/pdf_parser_service.dart';

void main() async {
  print('=== Testing PDF Parser ===');

  final pdfFile = File('assets/archivos/2025-12-20_T_8094.pdf');

  if (!pdfFile.existsSync()) {
    print('ERROR: PDF file not found!');
    return;
  }

  print('Reading PDF: ${pdfFile.path}');

  final matches = await PdfParserService.parsePdfDesignation(pdfFile);

  print('\n=== RESULTS ===');
  print('Total matches found: ${matches.length}\n');

  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    print('--- Match ${i + 1} ---');
    print('Number: ${match['matchNumber']}');
    print('Date: ${match['date']} ${match['time']}');
    print('Teams: ${match['localTeam']} vs ${match['visitantTeam']}');
    print('Category: ${match['category']}');
    print('Role: ${match['role']}');
    print('Referee Partner: ${match['refereePartner']}');
    print('');
  }
}