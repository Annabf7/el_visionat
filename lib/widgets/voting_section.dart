import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/vote_provider.dart';
import 'voting_card.dart';
import 'jornada_header.dart';

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

// Top-level helpers so multiple widgets can reuse them without duplicating
Future<List<MatchSeed>> loadMatchesFromAssets() async {
  final raw = await rootBundle.loadString(
    'assets/data/jornada_14_matches.json',
  );
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((e) => MatchSeed.fromJson(e as Map<String, dynamic>))
      .toList();
}

String formatDate(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  return DateFormat('dd/MM/yyyy • HH:mm', 'ca_ES').format(dt);
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
    _matchesFuture = loadMatchesFromAssets();
  }

  // Instance helpers removed; use top-level loadMatchesFromAssets and formatDate

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reusable jornada header (shows jornada and voting status)
          const JornadaHeader(jornada: 14),
          const SizedBox(height: 12),

          FutureBuilder<List<MatchSeed>>(
            future: _matchesFuture ??= loadMatchesFromAssets(),
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
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(color: AppTheme.grisPistacho),
                    ),
                  ),
                );
              }

              final all = snap.data ?? <MatchSeed>[];
              if (all.isEmpty) {
                return Center(child: Text('No hi ha enfrontaments'));
              }

              if (_selected.isEmpty) {
                final c = List<MatchSeed>.from(all);
                c.shuffle(Random());
                _selected.addAll(c.take(min(3, c.length)));
              }

              if (!_didPrecache) {
                final ctx = context;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  for (final m in _selected) {
                    if (m.homeLogo.isNotEmpty) {
                      precacheImage(
                        AssetImage('assets/images/teams/${m.homeLogo}'),
                        ctx,
                      ).catchError((_) {});
                    }
                    if (m.awayLogo.isNotEmpty) {
                      precacheImage(
                        AssetImage('assets/images/teams/${m.awayLogo}'),
                        ctx,
                      ).catchError((_) {});
                    }
                  }
                  _didPrecache = true;
                });
              }

              // Provide a VoteProvider scoped to this little section so voting
              // from Home behaves the same as from AllMatchesPage.
              return ChangeNotifierProvider(
                create: (_) {
                  final vp = VoteProvider();
                  vp.loadVoteForJornada(14);
                  vp.listenVotingOpen(14);
                  return vp;
                },
                child: Consumer<VoteProvider>(
                  builder: (context, vp, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header row removed per UX decision — we keep only the compact match cards

                        // Rows
                        for (final m in _selected)
                          Builder(builder: (ctx) => _cardFor(ctx, m, vp)),

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllMatchesPage(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.grisPistacho,
                              foregroundColor: AppTheme.porpraFosc,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Veure tots',
                              style: GoogleFonts.montserrat(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardFor(BuildContext ctx, MatchSeed m, VoteProvider vp) {
    final matchId = m.homeLogo.isNotEmpty
        ? m.homeLogo
        : '${m.homeName}_${m.awayName}';

    return StreamBuilder<int>(
      stream: vp.getVoteCountStream(matchId, m.jornada),
      builder: (context, countSnap) {
        final count = countSnap.data ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.porpraFosc.withAlpha(250),
                  AppTheme.lilaMitja.withAlpha(120),
                  AppTheme.grisBody.withAlpha(220),
                ],
                stops: const [0.0, 0.55, 1.0],
                tileMode: TileMode.clamp,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(89),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    // Make logos larger and responsive (better for small phones)
                    double logoSize = 72; // base for small phones
                    if (w >= 800) {
                      logoSize = 120;
                    } else if (w >= 420) {
                      logoSize = 96;
                    } else if (w >= 360) {
                      logoSize = 80;
                    }
                    final compact = w < 420;

                    Widget logoWidget(String name, String logo) {
                      final asset = logo.isNotEmpty
                          ? 'assets/images/teams/$logo'
                          : '';
                      if (asset.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: ResizeImage(
                              AssetImage(asset),
                              width: logoSize.round(),
                            ),
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            semanticLabel: name,
                            errorBuilder: (c, e, s) => CircleAvatar(
                              radius: logoSize / 2,
                              backgroundColor: Colors.grey[700],
                              child: Text(
                                _initials(name),
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return CircleAvatar(
                        radius: logoSize / 2,
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          _initials(name),
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }

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
                          logoWidget(name, logo),
                          if (showName) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }

                    // Prepare date/time parts for stacked display
                    final parts = formatDate(m.dateTime).contains('•')
                        ? formatDate(
                            m.dateTime,
                          ).split('•').map((s) => s.trim()).toList()
                        : [formatDate(m.dateTime)];

                    if (compact) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              logoWidget(m.homeName, m.homeLogo),
                              Text(
                                'vs',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              logoWidget(m.awayName, m.awayLogo),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  parts[0],
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (parts.length > 1) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    parts[1],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'vs',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
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
                        const SizedBox(height: 8),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                parts[0],
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (parts.length > 1) ...[
                                const SizedBox(height: 4),
                                Text(
                                  parts[1],
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Ensure user is authenticated before voting
                      final current = FirebaseAuth.instance.currentUser;
                      if (current == null) {
                        if (!mounted) return;
                        showDialog<void>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Cal iniciar sessió'),
                            content: const Text(
                              'Cal iniciar sessió per poder votar.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dctx).pop(),
                                child: const Text('D\'acord'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(ctx);
                      try {
                        await vp.castVote(
                          jornada: m.jornada,
                          matchId: m.homeLogo.isNotEmpty
                              ? m.homeLogo
                              : '${m.homeName}_${m.awayName}',
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Vot registrat')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Error en registrar el vot'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.how_to_vote, size: 18),
                    label: Text(
                      'Votar',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppTheme.grisPistacho,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // bottom-right vote count like in VotingCard
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    count == 1 ? '1 vot' : '$count vots',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AllMatchesPage extends StatefulWidget {
  const AllMatchesPage({super.key});

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  Future<List<MatchSeed>>? _matchesFuture;
  final int jornada = 14;

  @override
  void initState() {
    super.initState();
    _matchesFuture = loadMatchesFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tots els enfrontaments')),
      body: FutureBuilder<List<MatchSeed>>(
        future: _matchesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error carregant enfrontaments'));
          }
          final all = snap.data ?? <MatchSeed>[];
          final jornadaMatches = all
              .where((m) => m.jornada == jornada)
              .toList();
          final displayed = jornadaMatches;
          final allMatches = displayed; // keep names friendly below
          if (allMatches.isEmpty) {
            return Center(child: Text('No hi ha enfrontaments'));
          }
          // (handled above)

          // Provide a VoteProvider scoped to this page.
          return ChangeNotifierProvider(
            create: (_) {
              final vp = VoteProvider();
              // start listeners
              vp.loadVoteForJornada(jornada);
              vp.listenVotingOpen(jornada);
              return vp;
            },
            child: Consumer<VoteProvider>(
              builder: (context, vp, _) {
                // Header + list of jornada matches. The header shows jornada and
                // voting status (open/closed) at the top of the page as requested.
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.porpraFosc,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jornada $jornada',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: AppTheme.grisPistacho,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: vp.isClosed(jornada)
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                vp.isClosed(jornada)
                                    ? 'Votació tancada'
                                    : 'Votació oberta',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: AppTheme.grisPistacho,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Matches for this jornada
                    for (var i = 0; i < allMatches.length; i++)
                      (() {
                        final m = allMatches[i];
                        // precache images for smoother UI
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

                        final matchId = m.homeLogo.isNotEmpty
                            ? m.homeLogo
                            : '${m.homeName}_${m.awayName}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: StreamBuilder<int>(
                            stream: vp.getVoteCountStream(matchId, jornada),
                            builder: (context, countSnap) {
                              final count = countSnap.data ?? 0;
                              final isVoted =
                                  vp.votedMatchId(jornada) == matchId;
                              return VotingCard(
                                homeName: m.homeName,
                                homeLogo: m.homeLogo,
                                awayName: m.awayName,
                                awayLogo: m.awayLogo,
                                dateTimeIso: formatDate(m.dateTime),
                                matchId: matchId,
                                jornada: jornada,
                                voteCount: count,
                                isVoted: isVoted,
                                isDisabled: vp.isClosed(jornada),
                                isLoading: vp.isCasting(jornada),
                                onVote: () async {
                                  // Guard: ensure user is signed in before attempting vote.
                                  final current =
                                      FirebaseAuth.instance.currentUser;
                                  if (current == null) {
                                    if (!mounted) return;
                                    showDialog<void>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Cal iniciar sessió'),
                                        content: const Text(
                                          'Has d\'iniciar sessió perquè el teu vot quedi registrat.',
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
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    await vp.castVote(
                                      jornada: jornada,
                                      matchId: matchId,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Vot registrat'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error votant: $e'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      })(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
