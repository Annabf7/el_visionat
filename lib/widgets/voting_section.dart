import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/providers/backend_state.dart';
import 'package:el_visionat/providers/auth_provider.dart';
import 'package:el_visionat/widgets/team_card.dart';
import 'package:el_visionat/screens/veure_tots.dart';

import '../theme/app_theme.dart';

/// Minimal match model for the seed JSON.
class MatchSeed {
  final int jornada;
  final String homeName;
  final String homeLogo;
  final String awayName;
  final String awayLogo;
  final String dateTime;
  final String timezone;
  final String gender;
  final String source;

  MatchSeed({
    required this.jornada,
    required this.homeName,
    required this.homeLogo,
    required this.awayName,
    required this.awayLogo,
    required this.dateTime,
    required this.timezone,
    required this.gender,
    required this.source,
  });

  factory MatchSeed.fromJson(Map<String, dynamic> json) {
    final home = json['home'] as Map<String, dynamic>?;
    final away = json['away'] as Map<String, dynamic>?;
    return MatchSeed(
      jornada: json['jornada'] as int,
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
      dateTime: json['dateTime'] as String,
      timezone: json['timezone'] as String,
      gender: json['gender'] as String,
      source: json['source'] as String,
    );
  }
}

class VotingSection extends StatefulWidget {
  const VotingSection({super.key});

  @override
  State<VotingSection> createState() => _VotingSectionState();
}

class _VotingSectionState extends State<VotingSection> {
  Future<List<MatchSeed>>? _matchesFuture;
  final List<MatchSeed> _selected = [];
  bool _didPrecache = false;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _loadFromAssets();
  }

  Future<List<MatchSeed>> _loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/data/jornada_14_matches.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MatchSeed.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy', 'ca_ES').format(dt);
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('HH:mm', 'ca_ES').format(dt);
  }

  // initials helper removed — TeamInfo handles initials rendering now.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        // Use the lighter 'white' tone from AppTheme (D9D9D9) as requested
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jornada 14',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    // Inter family and grey body color
                    color: AppTheme.grisBody,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Votació Oberta',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(color: AppTheme.grisBody),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<MatchSeed>>(
            future: _matchesFuture ??= _loadFromAssets(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Error carregant enfrontaments',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(color: AppTheme.grisBody),
                    ),
                  ),
                );
              }

              final all = snap.data ?? <MatchSeed>[];
              if (all.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'No hi ha enfrontaments',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(color: AppTheme.grisBody),
                    ),
                  ),
                );
              }

              if (_selected.isEmpty) {
                final c = List<MatchSeed>.from(all);
                c.shuffle(Random());
                _selected.addAll(c.take(min(3, c.length)));
              }

              if (!_didPrecache) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  for (final m in _selected) {
                    if (m.homeLogo.isNotEmpty) {
                      precacheImage(
                        AssetImage('assets/images/teams/${m.homeLogo}'),
                        context,
                      ).catchError((_) {});
                    }
                    if (m.awayLogo.isNotEmpty) {
                      precacheImage(
                        AssetImage('assets/images/teams/${m.awayLogo}'),
                        context,
                      ).catchError((_) {});
                    }
                  }
                  _didPrecache = true;
                });
              }

              return Column(
                children: [
                  for (final m in _selected) _cardFor(m),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VeureTotsPage(),
                        ),
                      ),
                      child: Text(
                        'Veure tots',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(color: Colors.black45),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardFor(MatchSeed m) {
    // Read BackendState once during build to avoid ProviderNotFound when
    // the onPressed callback executes in a different BuildContext (dialogs,
    // overlays, hot-reload situations). We catch errors and allow a null
    // fallback so the UI can show a helpful message instead of crashing.
    BackendState? backendState;
    try {
      backendState = Provider.of<BackendState>(context, listen: false);
    } catch (_) {
      backendState = null;
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      // Remove the dark/purple rectangle — make the card surface match the section (light)
      color: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                double logoSize = 130;
                if (w >= 800) {
                  logoSize = 156;
                } else if (w >= 400) {
                  logoSize = 142;
                }
                final compact = w < 420;

                // Use the reusable TeamInfo widget for logo + name rendering.
                // We avoid showing votes here (handled elsewhere) and adapt
                // the size based on layout width.
                Widget teamBlock(
                  String name,
                  String logo, {
                  bool right = false,
                  bool showName = true,
                }) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: right
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      TeamInfo(
                        name: name,
                        assetLogo: logo.isNotEmpty ? logo : null,
                        size: logoSize,
                        showName: showName,
                        showVotes: false,
                      ),
                    ],
                  );
                }

                if (compact) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TeamInfo(
                            name: m.homeName,
                            assetLogo: m.homeLogo.isNotEmpty
                                ? m.homeLogo
                                : null,
                            size: logoSize,
                            showName: false,
                            showVotes: false,
                          ),
                          Text(
                            'vs',
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                color: AppTheme.porpraFosc,
                              ),
                            ),
                          ),
                          TeamInfo(
                            name: m.awayName,
                            assetLogo: m.awayLogo.isNotEmpty
                                ? m.awayLogo
                                : null,
                            size: logoSize,
                            showName: false,
                            showVotes: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(m.dateTime),
                              style: TextStyle(
                                color: AppTheme.porpraFosc,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(m.dateTime),
                              style: TextStyle(
                                color: AppTheme.porpraFosc,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: teamBlock(m.homeName, m.homeLogo)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'vs',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: AppTheme.porpraFosc,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: teamBlock(
                              m.awayName,
                              m.awayLogo,
                              right: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(m.dateTime),
                            style: TextStyle(
                              color: AppTheme.porpraFosc,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(m.dateTime),
                            style: TextStyle(
                              color: AppTheme.porpraFosc,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final backend = backendState;
                  if (backend == null) {
                    // Provider not available (hot-reload or wiring issue).
                    // Show a helpful dialog asking the user to restart the app.
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Estat no disponible'),
                        content: const Text(
                          'L\'estat del backend no està disponible en aquest context. Si acabes de fer canvis, fes un reinici complet de l\'aplicació (Hot Restart).',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('D\'acord'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  if (!backend.available) {
                    // Show explanatory dialog and offer to recheck
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Back-end no disponible'),
                        content: const Text(
                          'No es pot realitzar aquesta acció perquè el back-end no està disponible. Vols reintentar o desconnectar-te?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await backend.recheck();
                            },
                            child: const Text('Reintentar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await context.read<AuthProvider>().signOut();
                            },
                            child: const Text('Desconnectar'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  debugPrint('Voted for ${m.homeName} vs ${m.awayName}');
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
            ),
          ],
        ),
      ),
    );
  }
}

// AllMatchesPage removed — navigation now goes to `VeureTotsPage` in
// `lib/screens/veure_tots.dart` which implements the full list.
