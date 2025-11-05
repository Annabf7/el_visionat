import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/providers/backend_state.dart';
import 'package:el_visionat/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:el_visionat/services/vote_service.dart';
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
  final Set<int> _votedSelected = {};

  String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  String _matchIdFor(MatchSeed m) {
    final h = _slug(m.homeName);
    final a = _slug(m.awayName);
    return 'j${m.jornada}_${h}_$a';
  }

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
                  // Capture user and messenger before awaiting async work.
                  // Use FirebaseAuth.instance.currentUser directly to avoid provider
                  // timing issues where the StreamProvider may not be available
                  // in this BuildContext during callbacks.
                  // Capture the current user synchronously before any awaits.
                  var firebaseUser = FirebaseAuth.instance.currentUser;
                  // Debug log to help trace auth timing issues.
                  // ignore: avoid_print
                  print(
                    'User before voting_section vote handler (initial): ${firebaseUser?.uid}',
                  );
                  final messenger = ScaffoldMessenger.of(context);

                  // Defensive quick-check: if currentUser is null, wait a short
                  // time and listen for an authStateChanges event (small timeout)
                  // so we reduce false negatives when the auth stream hasn't
                  // propagated yet.
                  if (firebaseUser == null) {
                    try {
                      final ev = await FirebaseAuth.instance
                          .authStateChanges()
                          .first
                          .timeout(const Duration(milliseconds: 250));
                      // ignore: avoid_print
                      print('Auth quick-check returned: ${ev?.uid}');
                      firebaseUser = ev;
                    } catch (_) {
                      // Timeout/no event — treat as still null
                    }
                  }

                  if (!mounted) {
                    return; // ensure BuildContext is still valid after await
                  }

                  if (firebaseUser == null) {
                    // Avoid showing a blocking dialog — use a SnackBar with
                    // an action to navigate to login. Signed-in users will
                    // not see this and can proceed to vote.
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Has d\'iniciar sessió per poder votar.',
                        ),
                        action: SnackBarAction(
                          label: 'Iniciar sessió',
                          onPressed: () {
                            if (mounted) {
                              Navigator.of(context).pushNamed('/login');
                            }
                          },
                        ),
                      ),
                    );
                    return;
                  }

                  final service = VoteService();

                  // Check existing vote for this jornada
                  final existing = await service.getUserVoteForJornada(
                    jornada: m.jornada,
                  );

                  if (!mounted) {
                    return;
                  }

                  final currentMatchId = _matchIdFor(m);
                  final prevMatchId = existing == null
                      ? null
                      : existing['matchId'] as String?;

                  if (prevMatchId != null && prevMatchId == currentMatchId) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Ja has votat per aquest enfrontament'),
                      ),
                    );
                    return;
                  }

                  // If user voted for a different match, ask to confirm modification
                  if (prevMatchId != null && prevMatchId != currentMatchId) {
                    final prevLabel = prevMatchId
                        .replaceFirst(RegExp(r'^j\d+_'), '')
                        .replaceAll('_', ' – ');
                    final change = await showDialog<bool?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Modificar vot'),
                        content: Text(
                          'Has votat actualment per "$prevLabel". Vols canviar el teu vot per "${m.homeName} – ${m.awayName}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel·lar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Modificar vot'),
                          ),
                        ],
                      ),
                    );
                    if (change != true) return;
                  }

                  // Proceed to vote/change
                  final success = await service.voteForMatch(
                    matchId: currentMatchId,
                    jornada: m.jornada,
                  );

                  if (!mounted) {
                    return;
                  }

                  if (success) {
                    setState(() {
                      final idx = _selected.indexOf(m);
                      if (idx != -1) _votedSelected.add(idx);
                    });
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vot registrat per ${m.homeName} – ${m.awayName}',
                        ),
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('No s\'ha pogut registrar el vot'),
                      ),
                    );
                  }
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
