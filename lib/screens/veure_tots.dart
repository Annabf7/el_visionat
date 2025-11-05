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
import 'package:el_visionat/services/vote_service.dart';

/// Lightweight Match model used by VeureTotsPage (same shape as jornada_14_matches.json)
class MatchSeedVT {
  final String homeName;
  final String homeLogo;
  final String awayName;
  final String awayLogo;

  /// Número de jornada per aquest enfrontament.
  ///
  /// Català: "jornada" representa el número de la jornada (round/matchday) del
  /// partit. S'espera que es carregui des d
  /// `assets/data/jornada_14_matches.json` i s'utilitza per crear un
  /// identificador únic del partit (per exemple, `j14_0`) i també s'envia al
  /// backend quan l'usuari emet un vot.

  final int jornada;
  final String dateTime;

  MatchSeedVT({
    required this.homeName,
    required this.homeLogo,
    required this.awayName,
    required this.awayLogo,
    required this.jornada,
    required this.dateTime,
  });

  factory MatchSeedVT.fromJson(Map<String, dynamic> json) {
    final home = json['home'] as Map<String, dynamic>?;
    final away = json['away'] as Map<String, dynamic>?;
    // robust parsing for jornada: accept int, num, or numeric string; fallback to 0
    int parseJornada(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        return int.tryParse(v) ?? 0;
      }
      return 0;
    }

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
      jornada: parseJornada(json['jornada']),
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
  final Map<int, int> _voteCounts = {};

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

  String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  String _matchIdFor(MatchSeedVT m) {
    // stable id built from jornada + home + away
    final h = _slug(m.homeName);
    final a = _slug(m.awayName);
    return 'j${m.jornada}_${h}_$a';
  }

  final Set<int> _checkedJornadas =
      {}; // avoid refetching user vote per jornada

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
    // Keep the StreamProvider-based watch here so the UI can react when the
    // user signs in/out. Action handlers below will read the synchronous
    // FirebaseAuth.instance.currentUser to avoid transient provider nulls.
    // Keep the StreamProvider watch to trigger rebuilds on auth changes.
    context.watch<User?>();
    final voteService = VoteService();

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
                    final matchId = _matchIdFor(m);
                    // fetch vote counts lazily if not present
                    if (!_voteCounts.containsKey(index)) {
                      voteService
                          .getVoteCount(matchId: matchId)
                          .then((count) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _voteCounts[index] = count;
                            });
                          })
                          .catchError((_) {});
                    }
                    // fetch user's vote for this jornada once so we can show
                    // which match they previously voted for and allow changing it.
                    // Prefer a synchronous read from FirebaseAuth for background
                    // fetches to avoid races with provider-based watches.
                    final currentUserForFetch =
                        FirebaseAuth.instance.currentUser;
                    if (currentUserForFetch != null &&
                        !_checkedJornadas.contains(m.jornada)) {
                      _checkedJornadas.add(m.jornada);
                      voteService
                          .getUserVoteForJornada(jornada: m.jornada)
                          .then((voteDoc) {
                            if (!mounted) {
                              return;
                            }
                            if (voteDoc == null) {
                              return;
                            }
                            final existingMatchId =
                                voteDoc['matchId'] as String?;
                            if (existingMatchId == null) return;
                            final found = pageMatches.indexWhere(
                              (pm) => _matchIdFor(pm) == existingMatchId,
                            );
                            if (found != -1) {
                              setState(() {
                                _votedIndexes.add(found);
                              });
                            }
                          })
                          .catchError((_) {});
                    }
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
                                    // Capture user synchronously before any awaits.
                                    var firebaseUserLocal =
                                        FirebaseAuth.instance.currentUser;
                                    // Capture ScaffoldMessenger and a local
                                    // BuildContext reference early so we don't
                                    // call State.context after async gaps
                                    // (avoids the use_build_context_synchronously
                                    // analyzer warning).
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final dialogContext = context;
                                    // ignore: avoid_print
                                    print(
                                      'User before VeureTots vote handler (initial): ${firebaseUserLocal?.uid}',
                                    );
                                    final backendLocal = backend;
                                    if (backendLocal == null) {
                                      await showDialog<void>(
                                        context: dialogContext,
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
                                      final auth = context.read<AuthProvider>();
                                      await showDialog<void>(
                                        context: dialogContext,
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
                                                await auth.signOut();
                                              },
                                              child: const Text('Desconnectar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    // Defensive quick-check: if null, wait briefly for any
                                    // authStateChanges propagation (small timeout).
                                    if (firebaseUserLocal == null) {
                                      try {
                                        final ev = await FirebaseAuth.instance
                                            .authStateChanges()
                                            .first
                                            .timeout(
                                              const Duration(milliseconds: 250),
                                            );
                                        // ignore: avoid_print
                                        print(
                                          'Auth quick-check returned: ${ev?.uid}',
                                        );
                                        firebaseUserLocal = ev;
                                      } catch (_) {
                                        // no event — continue
                                      }
                                    }
                                    if (!dialogContext.mounted) {
                                      return; // Ensure dialogContext is still valid after awaits
                                    }

                                    if (firebaseUserLocal == null) {
                                      // User not signed in — show a non-blocking snackbar
                                      // with an action to go to the login screen instead
                                      // of a modal dialog that blocks voting.
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Has d\'iniciar sessió per poder votar.',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Iniciar sessió',
                                            onPressed: () {
                                              if (dialogContext.mounted) {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pushNamed('/login');
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    // Confirm vote for this match (vote is for the match, not a team)
                                    // userId is not required here because VoteService
                                    // reads the current user internally. Keep the
                                    // captured firebaseUserLocal for debug/consistency.

                                    if (!dialogContext.mounted) {
                                      return;
                                    }

                                    final confirm = await showDialog<bool>(
                                      context: dialogContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar vot'),
                                        content: Text(
                                          'Vols votar el partit ${m.homeName} vs ${m.awayName}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Sí'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) {
                                      return;
                                    }

                                    final success = await voteService
                                        .voteForMatch(
                                          matchId: matchId,
                                          jornada: m.jornada,
                                        );

                                    if (!mounted) {
                                      return;
                                    }

                                    if (success) {
                                      // Refresh counts for the visible page matches and update voted index
                                      for (
                                        var i = 0;
                                        i < pageMatches.length;
                                        i++
                                      ) {
                                        final mid = _matchIdFor(pageMatches[i]);
                                        voteService
                                            .getVoteCount(matchId: mid)
                                            .then((c) {
                                              if (!mounted) {
                                                return;
                                              }
                                              setState(() {
                                                _voteCounts[i] = c;
                                              });
                                            })
                                            .catchError((_) {});
                                      }

                                      // Re-fetch user's vote to find which match index is now selected
                                      final updated = await voteService
                                          .getUserVoteForJornada(
                                            jornada: m.jornada,
                                          );
                                      if (!mounted) {
                                        return;
                                      }
                                      if (updated != null) {
                                        final existingMatchId =
                                            updated['matchId'] as String?;
                                        if (existingMatchId != null) {
                                          final found = pageMatches.indexWhere(
                                            (pm) =>
                                                _matchIdFor(pm) ==
                                                existingMatchId,
                                          );
                                          setState(() {
                                            _votedIndexes.clear();
                                            if (found != -1) {
                                              _votedIndexes.add(found);
                                            }
                                          });
                                        }
                                      }

                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Vot registrat pel partit ${m.homeName} vs ${m.awayName}',
                                          ),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No s\'ha pogut registrar el vot (ja existeix o error)',
                                          ),
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
