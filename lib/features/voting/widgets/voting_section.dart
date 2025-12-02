import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
// Authentication is handled centrally by RequireAuth / AuthProvider.

import '../providers/vote_provider.dart';
import '../../auth/index.dart';
import 'voting_card.dart';
import 'jornada_header.dart';

import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/classificacio/standings_list_mobile.dart';

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

/// Simple video widget for Voting Section
class VotingVideoClip extends StatefulWidget {
  const VotingVideoClip({super.key});

  @override
  State<VotingVideoClip> createState() => _VotingVideoClipState();
}

class _VotingVideoClipState extends State<VotingVideoClip> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  static const String _videoUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/home_page%2Flayout_votingHome.mp4?alt=media&token=4da7388e-9e6b-420a-96a7-b56ca4ccd74c';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0.0);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.grisBody.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, color: AppTheme.grisPistacho),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.grisBody.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.grisPistacho),
        ),
      );
    }

    // Crop verticalment i afegeix overlay gris translúcid
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: 0.5, // mostra només el 50% central del vídeo
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppTheme.grisBody.withAlpha(
                (0.4 * 255).round(),
              ), // gris translúcid
            ),
          ),
        ],
      ),
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

          // Video clip
          const VotingVideoClip(),
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
                _selected.addAll(c.take(min(5, c.length)));
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
                create: (ctx) {
                  final auth = ctx.read<AuthProvider>();
                  final vp = VoteProvider(authProvider: auth);
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/all-matches',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 18,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.list_alt,
                                          color: Colors.grey[300],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Veure tots',
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 7), // espai superior
                          logoWidget(name, logo),
                          if (showName) ...[
                            const SizedBox(height: 8),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.grisPistacho,
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                                height: 1.2,
                                fontFamily: 'Inter',
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Home team - perfectly centered
                              Expanded(
                                child: Center(
                                  child: teamBlock(m.homeName, m.homeLogo),
                                ),
                              ),
                              // VS separator - perfectly centered
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  'vs',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Away team - perfectly centered
                              Expanded(
                                child: Center(
                                  child: teamBlock(m.awayName, m.awayLogo),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Date/time perfectly centered
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  parts[0],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    textStyle: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (parts.length > 1) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    parts[1],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Non-compact layout
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Home team - perfectly centered
                            Expanded(
                              child: Center(
                                child: teamBlock(m.homeName, m.homeLogo),
                              ),
                            ),
                            // VS separator - perfectly centered
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Text(
                                'vs',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ),
                            // Away team - perfectly centered
                            Expanded(
                              child: Center(
                                child: teamBlock(m.awayName, m.awayLogo),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date/time perfectly centered
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                parts[0],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  textStyle: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (parts.length > 1) ...[
                                const SizedBox(height: 4),
                                Text(
                                  parts[1],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    textStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
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
                const SizedBox(height: 16),
                // Vote button and vote count side by side
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 420;
                    final buttonHeight = isMobile ? 36.0 : 40.0;

                    return Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: isMobile ? 8 : 12,
                        runSpacing: isMobile ? 8 : 12,
                        children: [
                          // Vote button
                          SizedBox(
                            height: buttonHeight,
                            child: ElevatedButton.icon(
                              onPressed: () async {
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
                                    const SnackBar(
                                      content: Text('Vot registrat'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error en registrar el vot',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.how_to_vote,
                                size: isMobile ? 16 : 18,
                              ),
                              label: Text(
                                'Votar',
                                style: GoogleFonts.montserrat(
                                  textStyle: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.grisPistacho,
                                foregroundColor: AppTheme.porpraFosc,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 14 : 20,
                                  vertical: 0,
                                ),
                                minimumSize: Size(0, buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 10 : 12,
                                  ),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          // Vote count
                          Container(
                            height: buttonHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(51),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              border: Border.all(
                                color: Colors.grey[700]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(width: isMobile ? 6 : 8),
                                Text(
                                  count == 1 ? '1 vot' : '$count vots',
                                  style: GoogleFonts.montserrat(
                                    textStyle: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: isMobile ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
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
          final allMatches = jornadaMatches;
          if (allMatches.isEmpty) {
            return Center(child: Text('No hi ha enfrontaments'));
          }

          final isWide = MediaQuery.of(context).size.width > 700;

          Widget matchesList(VoteProvider vp) => ListView(
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
                        final isVoted = vp.votedMatchId(jornada) == matchId;
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
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await vp.castVote(
                                jornada: jornada,
                                matchId: matchId,
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Vot registrat')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error votant: $e')),
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

          Widget standingsContent = Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.leaderboard_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Classificació',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta la classificació actual de la lliga.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  StandingsListMobile(standings: mockStandings),
                ],
              ),
            ),
          );

          // Provide a VoteProvider scoped to this page.
          return ChangeNotifierProvider(
            create: (ctx) {
              final auth = ctx.read<AuthProvider>();
              final vp = VoteProvider(authProvider: auth);
              // start listeners
              vp.loadVoteForJornada(jornada);
              vp.listenVotingOpen(jornada);
              return vp;
            },
            child: Consumer<VoteProvider>(
              builder: (context, vp, _) {
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: matchesList(vp)),
                      const SizedBox(width: 24),
                      Expanded(child: standingsContent),
                    ],
                  );
                } else {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      matchesList(vp),
                      const SizedBox(height: 16),
                      standingsContent,
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
