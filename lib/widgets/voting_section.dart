import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

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
                          builder: (_) => const AllMatchesPage(),
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
                  logoSize = 96;
                } else if (w >= 400) {
                  logoSize = 172;
                }
                final compact = w < 420;

                Widget logoWidget(String name, String logo) {
                  final asset = logo.isNotEmpty
                      ? 'assets/images/teams/$logo'
                      : '';
                  // Per design: use lilaMitja circular background for logos (no rectangle)
                  final bg = AppTheme.white;
                  if (asset.isNotEmpty) {
                    return Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: Image(
                          image: ResizeImage(
                            AssetImage(asset),
                            width: (logoSize * 0.8).round(),
                          ),
                          width: logoSize * 0.8,
                          height: logoSize * 0.8,
                          fit: BoxFit.contain,
                          semanticLabel: name,
                          errorBuilder: (c, e, s) => CircleAvatar(
                            radius: (logoSize * 0.4),
                            backgroundColor: bg,
                            child: Text(
                              _initials(name),
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return CircleAvatar(
                    radius: logoSize / 2,
                    backgroundColor: bg,
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
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                color: AppTheme.porpraFosc,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                if (compact) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          logoWidget(m.homeName, m.homeLogo),
                          Text(
                            'vs',
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                color: AppTheme.porpraFosc,
                              ),
                            ),
                          ),
                          logoWidget(m.awayName, m.awayLogo),
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
                onPressed: () =>
                    debugPrint('Voted for ${m.homeName} vs ${m.awayName}'),
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

class AllMatchesPage extends StatelessWidget {
  const AllMatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tots els enfrontaments')),
      body: const Center(child: Text('AllMatchesPage - implementació pendent')),
    );
  }
}
