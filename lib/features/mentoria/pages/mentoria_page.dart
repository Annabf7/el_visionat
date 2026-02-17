import 'package:flutter/material.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

import 'package:el_visionat/features/search/models/search_result.dart';
import 'package:el_visionat/features/mentoria/widgets/mentoria_search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/features/profile/models/profile_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:el_visionat/features/mentoria/widgets/mentoria_topics_panel.dart'; // Importació del panell
import '../widgets/mentoria_calendar.dart';

class MentoriaPage extends StatefulWidget {
  const MentoriaPage({super.key});

  @override
  State<MentoriaPage> createState() => _MentoriaPageState();
}

class _MentoriaPageState extends State<MentoriaPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Llista d'IDs locals. Poden ser UIDs de Firebase o Strings tipus "nom|llicencia|categoria"
  List<String> _mentoredIds = [];
  bool _isLoading = true;
  Set<String> _selectedTopics = {}; // Estat dels temes seleccionats

  @override
  void initState() {
    super.initState();
    _fetchMentoredReferees();
  }

  Future<void> _fetchMentoredReferees() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final profile = ProfileModel.fromMap(doc.data());
        if (mounted) {
          setState(() {
            _mentoredIds = profile.mentoredReferees;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching mentored referees: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMentoredReferee(RefereeSearchResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String refereeId;
    if (result.userId != null) {
      refereeId = result.userId!;
    } else {
      // Sanitize fields to avoid ':' separator issues
      final sanitizedNom = result.nom.replaceAll(':', '');
      final sanitizedCognoms = result.cognoms.replaceAll(':', '');
      final sanitizedCategoria = (result.categoriaRrtt ?? '').replaceAll(
        ':',
        '',
      );
      refereeId =
          'manual:${result.llissenciaId}:$sanitizedNom:$sanitizedCognoms:$sanitizedCategoria';
    }

    if (_mentoredIds.contains(refereeId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.nom} ja està a la teva llista!'),
            backgroundColor: AppTheme.mostassa,
          ),
        );
      }
      return;
    }

    try {
      // Afegir a Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'mentoredReferees': FieldValue.arrayUnion([refereeId]),
        },
      );

      // Actualitzar estat local
      setState(() {
        _mentoredIds.add(refereeId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.nom} afegit/da correctament!'),
            backgroundColor: AppTheme.verdeEncert,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showManualAddDialog() async {
    final nomController = TextEditingController();
    final cognomsController = TextEditingController();
    final categoriaController = TextEditingController();
    final llicenciaController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Afegir àrbitre manualment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Si l\'àrbitre no apareix al cercador, pots afegir-lo aquí.',
                  style: TextStyle(fontSize: 14, color: AppTheme.grisBody),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cognomsController,
                  decoration: const InputDecoration(
                    labelText: 'Cognoms *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex: 1a Catalana',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: llicenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Llicència/ID (Opcional)',
                    hintText: 'Deixa buit si no la saps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final nom = nomController.text.trim();
                final cognoms = cognomsController.text.trim();
                final categoria = categoriaController.text.trim();

                if (nom.isEmpty || cognoms.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nom i Cognoms són obligatoris'),
                      backgroundColor: AppTheme.mostassa,
                    ),
                  );
                  return;
                }

                // Generar ID llicència si no hi és
                // Usem un prefix MAN- i timestamp per evitar col·lisions
                final llicencia = llicenciaController.text.trim().isNotEmpty
                    ? llicenciaController.text.trim()
                    : 'MAN-${DateTime.now().millisecondsSinceEpoch}';

                final result = RefereeSearchResult(
                  nom: nom,
                  cognoms: cognoms,
                  llissenciaId: llicencia,
                  categoriaRrtt: categoria.isEmpty
                      ? 'Sense categoria'
                      : categoria,
                  hasAccount: false,
                );

                Navigator.pop(context);
                _addMentoredReferee(result);
              },
              child: const Text('Afegir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            body: Row(
              children: [
                const SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        showMenuButton: false,
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Estirem verticalment per omplir l'espai
                          children: [
                            // Contingut principal amb scroll
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildBody(),
                              ),
                            ),
                            // Panell lateral (alçada fixa o ampliada)
                            Container(
                              width: 350,
                              padding: const EdgeInsets.only(
                                top: 24,
                                right: 24,
                                bottom: 24,
                              ),
                              child: MentoriaTopicsPanel(
                                selectedTopics: _selectedTopics,
                                onTopicsChanged: (newTopics) {
                                  setState(() {
                                    _selectedTopics = newTopics;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(scaffoldKey: _scaffoldKey, showMenuButton: true),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildBody(),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 400, // Alçada fixa per mòbil
                          child: MentoriaTopicsPanel(
                            selectedTopics: _selectedTopics,
                            onTopicsChanged: (newTopics) {
                              setState(() {
                                _selectedTopics = newTopics;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBody() {
    // Retornem el contingut sense scroll view, ja que el scroll el gestiona el pare
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mentoria',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.porpraFosc,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cerca i afegeix els àrbitres que mentoritzes per fer un seguiment.',
          style: TextStyle(color: AppTheme.grisBody, fontSize: 16),
        ),
        const SizedBox(height: 32),

        // Barra de cerca
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: MentoriaSearchBar(onResultSelected: _addMentoredReferee),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _showManualAddDialog,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('No el trobes? Afegeix-lo manualment'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.porpraFosc),
          ),
        ),

        const SizedBox(height: 32),
        Text(
          'Els meus mentoritzats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.porpraFosc,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _isLoading
            ? const CircularProgressIndicator(color: AppTheme.mostassa)
            : _mentoredIds.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildMentoredList(),
                  const SizedBox(height: 48),
                  MentoriaCalendar(
                    mentoredIds: _mentoredIds,
                    selectedTopics: _selectedTopics,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.person_add_alt_1, size: 48, color: AppTheme.lilaMitja),
            SizedBox(height: 16),
            Text(
              'Encara no tens cap àrbitre assignat.',
              style: TextStyle(color: AppTheme.porpraFosc, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Utilitza el cercador per afegir-los.',
              style: TextStyle(color: AppTheme.grisBody),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentoredList() {
    if (_mentoredIds.isEmpty) return const SizedBox.shrink();

    // Separem els IDs en:
    // 1. UIDs reals de Firebase (sense prefix 'manual:')
    // 2. Dades manuals (comencen per 'manual:')
    final realUserIds = _mentoredIds
        .where((id) => !id.startsWith('manual:'))
        .toList();
    final manualDataStrings = _mentoredIds
        .where((id) => id.startsWith('manual:'))
        .toList();

    // Creem una llista combinada de cards
    return FutureBuilder<QuerySnapshot?>(
      future: realUserIds.isNotEmpty
          ? FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: realUserIds)
                .get()
          : Future.value(
              null,
            ), // Si no hi ha usuaris reals, retornem null immediatament
      builder: (context, snapshot) {
        if (realUserIds.isNotEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Comencem amb les cards manuals
        List<Widget> cards = [];

        for (var dataString in manualDataStrings) {
          // Format manual: "manual:LLissenciaID:Nom:Cognoms:Categoria"
          final parts = dataString.split(':');
          if (parts.length >= 4) {
            final nom = parts[2];
            final cognoms = parts[3];
            final categoria = parts.length > 4 ? parts[4] : 'Sense categoria';

            final profile = ProfileModel(
              displayName: '$nom $cognoms', // Nom + Cognoms
              refereeCategory: categoria,
              isMentor: false,
            );
            cards.add(
              _MentoredCard(
                profile: profile,
                userId: dataString,
                isManual: true,
              ),
            );
          }
        }

        // Afegim les cards de Firebase si n'hi ha
        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final profile = ProfileModel.fromMap(data);
            cards.add(_MentoredCard(profile: profile, userId: doc.id));
          }
        }

        if (cards.isEmpty) return const Text('No s\'han trobat dades.');

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
          children: cards,
        );
      },
    );
  }
}

class _MentoredCard extends StatelessWidget {
  final ProfileModel profile;
  final String userId;
  final bool isManual;

  const _MentoredCard({
    required this.profile,
    required this.userId,
    this.isManual = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (!isManual && profile.hasCustomAvatar)
                    ? CachedNetworkImageProvider(profile.resolvedAvatarUrl)
                    : null,
                backgroundColor: AppTheme.grisPistacho,
                child: (isManual || !profile.hasCustomAvatar)
                    ? const Icon(Icons.person, size: 40, color: AppTheme.white)
                    : null,
              ),
              if (isManual)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.mostassa,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              profile.displayNameSafe,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isManual ? AppTheme.grisPistacho : AppTheme.porpraFosc,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              profile.refereeCategory ?? 'Sense categoria',
              style: const TextStyle(fontSize: 12, color: AppTheme.grisBody),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              if (isManual) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Aquest usuari encara no té perfil a l\'app.',
                    ),
                  ),
                );
                return;
              }
              // Navegar al perfil o dashboard de mentoria
              Navigator.pushNamed(context, '/user-profile', arguments: userId);
            },
            icon: Icon(
              isManual ? Icons.app_registration : Icons.analytics_outlined,
              size: 16,
            ),
            label: Text(isManual ? 'No registrat' : 'Veure Progrés'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isManual
                  ? AppTheme.grisPistacho
                  : AppTheme.porpraFosc,
              side: BorderSide(
                color: isManual ? AppTheme.grisPistacho : AppTheme.porpraFosc,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
