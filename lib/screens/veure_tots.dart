import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'package:el_visionat/widgets/team_card.dart';
import 'package:el_visionat/providers/backend_state.dart';
import 'package:el_visionat/providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Lightweight Match model used by VeureTotsPage (same shape as jornada_14_matches.json)
class MatchSeedVT {
  final String homeName;
  final String homeLogo;
  final String awayName;
  final String awayLogo;
  final String dateTime;

  MatchSeedVT({
    required this.homeName,
    required this.homeLogo,
    required this.awayName,
    required this.awayLogo,
    required this.dateTime,
  });

  factory MatchSeedVT.fromJson(Map<String, dynamic> json) {
    final home = json['home'] as Map<String, dynamic>?;
    final away = json['away'] as Map<String, dynamic>?;
    return MatchSeedVT(
      homeName: home != null && home['name'] != null
          ? home['name'] as String
          : (json['homeName'] as String? ?? ''),
      homeLogo: home != null && home['logo'] != null
          ? home['logo'] as String
          : (json['homeLogo'] as String? ?? ''),
      awayName: away != null && away['name'] != null
          ? away['name'] as String
          : (json['awayName'] as String? ?? ''),
      awayLogo: away != null && away['logo'] != null
          ? away['logo'] as String
          : (json['awayLogo'] as String? ?? ''),
      dateTime: json['dateTime'] as String? ?? '',
    );
  }
}

class VeureTotsPage extends StatefulWidget {
  const VeureTotsPage({super.key});

  @override
  State<VeureTotsPage> createState() => _VeureTotsPageState();
}

class _VeureTotsPageState extends State<VeureTotsPage> {
  Future<List<MatchSeedVT>>? _matchesFuture;
  final Set<int> _votedIndexes =
      {}; // local mock: which match indexes user voted

  @override
  void initState() {
    super.initState();
    _matchesFuture ??= _loadFromAssets();
  }

  Future<List<MatchSeedVT>> _loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/data/jornada_14_matches.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MatchSeedVT.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy', 'ca_ES').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm', 'ca_ES').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Provider.of<BackendState?>(context, listen: true);
    final firebaseUser = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(title: const Text('Veure tots')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<List<MatchSeedVT>>(
          future: _matchesFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error carregant enfrontaments',
                  style: GoogleFonts.inter(),
                ),
              );
            }

            final matches = snap.data ?? <MatchSeedVT>[];
            final pageMatches = matches.take(8).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 800;
                // Increase logo size on very small screens for better visibility.
                final double logoSize = constraints.maxWidth < 420
                    ? 96
                    : (wide ? 84 : 72);

                return ListView.separated(
                  itemCount: pageMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = pageMatches[index];
                    return Card(
                      color: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Home team
                                Expanded(
                                  child: TeamInfo(
                                    name: m.homeName,
                                    assetLogo: m.homeLogo.isNotEmpty
                                        ? m.homeLogo
                                        : null,
                                    size: logoSize,
                                    showName: wide,
                                    showVotes: false,
                                  ),
                                ),

                                // vs + date/time in center column
                                SizedBox(
                                  width: wide ? 220 : 96,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'vs',
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                            color: AppTheme.porpraFosc,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (_formatDate(m.dateTime).isNotEmpty)
                                        Text(
                                          _formatDate(m.dateTime),
                                          style: const TextStyle(
                                            color: AppTheme.porpraFosc,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (_formatTime(m.dateTime).isNotEmpty)
                                        Text(
                                          _formatTime(m.dateTime),
                                          style: const TextStyle(
                                            color: AppTheme.porpraFosc,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Away team
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TeamInfo(
                                      name: m.awayName,
                                      assetLogo: m.awayLogo.isNotEmpty
                                          ? m.awayLogo
                                          : null,
                                      size: logoSize,
                                      showName: wide,
                                      showVotes: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final backendLocal = backend;
                                    if (backendLocal == null) {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Estat no disponible',
                                          ),
                                          content: const Text(
                                            'L\'estat del backend no està disponible en aquest context. Torna a reiniciar l\'aplicació.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('D\'acord'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    if (!backendLocal.available) {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Back-end no disponible',
                                          ),
                                          content: const Text(
                                            'No es pot realitzar aquesta acció perquè el back-end no està disponible.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(ctx).pop();
                                                await backendLocal.recheck();
                                              },
                                              child: const Text('Reintentar'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(ctx).pop();
                                                await context
                                                    .read<AuthProvider>()
                                                    .signOut();
                                              },
                                              child: const Text('Desconnectar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    if (firebaseUser == null) {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Cal iniciar sessió',
                                          ),
                                          content: const Text(
                                            'Has d\'iniciar sessió per poder votar. Vols anar a la pantalla d\'accés?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                Navigator.of(
                                                  context,
                                                ).pushNamed('/login');
                                              },
                                              child: const Text('Sí'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    // Mock vote: mark index as voted
                                    setState(() {
                                      _votedIndexes.add(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Vot registrat (mock) per ${m.homeName}',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.how_to_vote,
                                    size: 14,
                                    color: AppTheme.white,
                                  ),
                                  label: Text(
                                    'Votar',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.white,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.porpraFosc,
                                    foregroundColor: AppTheme.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(64, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_votedIndexes.contains(index))
                                  Text(
                                    'Votat',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
