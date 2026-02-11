import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:video_player/video_player.dart';
import '../models/neurovisionat_models.dart';
import '../widgets/neuro_pillars_section.dart';
import '../widgets/neuro_tip_card.dart';
import '../widgets/neuro_mini_quiz.dart';
import '../widgets/neuro_routines_selector.dart';
import '../widgets/neuro_scientific_framework_section.dart';
import '../widgets/neuro_cta_section.dart';
import '../widgets/neuro_video_resources_section.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';

class NeuroVisionatPage extends StatelessWidget {
  const NeuroVisionatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;
        if (isLargeScreen) {
          // Desktop layout: SideNavigationMenu + GlobalHeader + content
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppTheme.grisBody,
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
                        scaffoldKey: scaffoldKey,
                        title: 'NeuroVisionat',
                        showMenuButton: false,
                      ),
                      Expanded(child: _NeuroWebLayout()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppTheme.grisBody,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: scaffoldKey,
                  title: 'NeuroVisionat',
                  showMenuButton: true,
                ),
                Expanded(child: _buildMobileLayout(context)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NeuroHeroHeader(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCard(
                  color: AppTheme.porpraFosc.withValues(alpha: 0.95),
                  child: const NeuroTipCard(),
                ),
                const SizedBox(height: 8),
                _buildCard(child: NeuroMiniQuiz(questions: neuroQuizQuestions)),
                const SizedBox(height: 8),
                _buildCard(
                  child: NeuroRoutinesSelector(routines: neuroRoutines),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const NeuroVideoResourcesSection(),
          ),
          const SizedBox(height: 8),
          NeuroPillarsSection(sections: neuroPillars),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCard(
                  color: AppTheme.porpraFosc,
                  child: const NeuroCTASection(),
                ),
                const SizedBox(height: 8),
                _buildCard(child: const NeuroScientificFrameworkSection()),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Consistent Card Builder helper
  Widget _buildCard({required Widget child, Color? color}) {
    return Card(
      color: color ?? AppTheme.grisBody,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

/// Layout web: hero + pilars/sidebar + vídeo
class _NeuroWebLayout extends StatelessWidget {
  static Widget _buildCard({required Widget child, Color? color}) {
    return Card(
      color: color ?? AppTheme.grisBody,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Hero + Pillars + Video)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeuroHeroHeader(),
                const SizedBox(height: 24),
                NeuroPillarsSection(sections: neuroPillars),
                const SizedBox(height: 32),
                const NeuroVideoResourcesSection(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column (Sidebar Tools)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  color: AppTheme.porpraFosc.withValues(alpha: 0.95),
                  child: const NeuroTipCard(),
                ),
                const SizedBox(height: 16),
                _buildCard(child: NeuroMiniQuiz(questions: neuroQuizQuestions)),
                const SizedBox(height: 16),
                _buildCard(
                  child: NeuroRoutinesSelector(routines: neuroRoutines),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  color: AppTheme.porpraFosc,
                  child: const NeuroCTASection(),
                ),
                const SizedBox(height: 16),
                _buildCard(child: const NeuroScientificFrameworkSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Dades locals dels 4 pilars ---
final List<NeuroSection> neuroPillars = [
  NeuroSection(
    titol: 'Presa de decisions sota pressió',
    subtitol: 'Gestió de l’estímul, finestra 1–2s, error perceptiu vs biaix',
    paragrafs: [
      'L’arbitratge requereix prendre decisions ràpides en situacions de pressió. L’estímul activa l’amígdala, però el còrtex prefrontal pot regular la resposta si es gestiona bé la finestra d’1–2 segons.',
      'Diferenciar entre error perceptiu, biaix i estrès és clau per millorar la qualitat de la decisió. El context i la gestió emocional condicionen la percepció.',
    ],
    principiClau:
        'No arbitres malament; a vegades arbitres en mode supervivència.',
    biaixos: [
      'Biaix de confirmació (mateixa jugada, context diferent)',
      'Error per pressió ambiental',
      'Decisió precipitada per estrès',
    ],
    exercicis: [
      NeuroExercise(
        titol: 'Decisió en 1,5s',
        passos: [
          'Observa una jugada i pren una decisió en menys de 2s.',
          'Analitza si la resposta ha estat impulsiva o regulada.',
          'Comparteix el resultat amb un company.',
        ],
      ),
      NeuroExercise(
        titol: 'Detecta el biaix',
        passos: [
          'Revisa la mateixa jugada en dos contextos diferents.',
          'Identifica si el criteri varia segons la situació.',
          'Reflexiona sobre el motiu del canvi.',
        ],
      ),
      NeuroExercise(
        titol: 'Reset post-error',
        passos: [
          'Després d’un error, aplica una rutina de respiració.',
          'Visualitza el següent play com a nova oportunitat.',
          'Evita la cadena d’errors.',
        ],
      ),
    ],
  ),
  NeuroSection(
    titol: 'Gestió emocional i control de l’estrès',
    subtitol: 'Amygdala hijack, acumulació emocional, reset ràpid',
    paragrafs: [
      'L’acumulació d’estrès pot provocar una “amygdala hijack”, on la resposta emocional domina la decisió. Reconèixer triggers i aplicar eines de regulació és fonamental.',
      'La respiració controlada, la paraula clau i la postura corporal ajuden a recuperar el centre i evitar reaccions impulsives.',
    ],
    principiClau: 'Tornar a centre més ràpid que la resta.',
    biaixos: [
      'Reacció impulsiva a provocacions',
      'Pèrdua de criteri per acumulació emocional',
    ],
    exercicis: [
      NeuroExercise(
        titol: 'Identifica el trigger',
        passos: [
          'Detecta el moment en què s’activa l’estrès.',
          'Descriu el trigger i la resposta inicial.',
          'Proposa una resposta regulada alternativa.',
        ],
      ),
      NeuroExercise(
        titol: 'Dues respostes',
        passos: [
          'Simula una situació reactiva i una regulada.',
          'Analitza la diferència en el resultat.',
          'Comparteix la reflexió amb l’equip.',
        ],
      ),
      NeuroExercise(
        titol: 'Rutina post-error',
        passos: [
          'Després d’un error, aplica una rutina de reset.',
          'Utilitza una paraula clau o gest.',
          'Recupera la postura i el focus.',
        ],
      ),
    ],
  ),
  NeuroSection(
    titol: 'Atenció, focus i fatiga mental',
    subtitol: 'Fatiga mental, visió túnel, micro-resets d’atenció',
    paragrafs: [
      'La fatiga mental apareix abans que la física i pot provocar errors, especialment al 3r i 4t quart. El focus selectiu i els micro-resets d’atenció són essencials per mantenir el criteri.',
      'Simplificar la cognició i saber on mirar en cada moment ajuda a evitar la visió túnel i a gestionar finals ajustats.',
    ],
    principiClau: 'Quan el partit s’accelera, el focus simplifica.',
    biaixos: ['Error per fatiga mental', 'Visió túnel en moments clau'],
    exercicis: [
      NeuroExercise(
        titol: 'On mires?',
        passos: [
          'Identifica el punt de focus en cada jugada.',
          'Canvia el focus de manera conscient.',
          'Reflexiona sobre l’impacte en la decisió.',
        ],
      ),
      NeuroExercise(
        titol: 'Fatiga simulada',
        passos: [
          'Simula una situació de fatiga (exercici físic breu).',
          'Pren una decisió arbitral immediatament.',
          'Analitza la qualitat de la decisió.',
        ],
      ),
      NeuroExercise(
        titol: 'Final ajustat',
        passos: [
          'Recrea un final de partit ajustat.',
          'Aplica micro-resets d’atenció.',
          'Comparteix la gestió amb l’equip.',
        ],
      ),
    ],
  ),
  NeuroSection(
    titol: 'Comunicació i autoritat (co-regulació)',
    subtitol: 'Neurocomunicació, to, autoritat percebuda, co-regulació',
    paragrafs: [
      'La comunicació arbitral va més enllà del contingut: el to, la veu ferma i el llenguatge corporal estable són claus per transmetre autoritat i regular el sistema.',
      'La co-regulació amb l’equip i amb entrenadors permet mantenir l’estabilitat en moments de tensió.',
    ],
    principiClau: 'Sigues el punt d’estabilitat.',
    biaixos: [
      'Missatge ambigu per falta d’autoritat',
      'Desconnexió amb l’equip en moments crítics',
    ],
    exercicis: [
      NeuroExercise(
        titol: 'Missatge amb tons',
        passos: [
          'Expressa el mateix missatge amb diferents tons.',
          'Analitza l’impacte en la percepció.',
          'Adapta el to segons el context.',
        ],
      ),
      NeuroExercise(
        titol: 'Clip mut (només cos)',
        passos: [
          'Comunica una decisió només amb el cos.',
          'Observa la reacció de l’entorn.',
          'Reflexiona sobre l’eficàcia.',
        ],
      ),
      NeuroExercise(
        titol: 'Entrenadora insistent',
        passos: [
          'Simula una interacció amb una entrenadora insistent.',
          'Mantén la postura i el to.',
          'Regula la comunicació per evitar escalada.',
        ],
      ),
    ],
  ),
];

class _NeuroHeroHeader extends StatefulWidget {
  @override
  State<_NeuroHeroHeader> createState() => _NeuroHeroHeaderState();
}

class _NeuroHeroHeaderState extends State<_NeuroHeroHeader> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(
              'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/neurovisionat%2Fneurovisionat_header.mp4?alt=media&token=4dfe9f07-51dd-4f08-8815-5604c3fd2340',
            ),
          )
          ..initialize().then((_) {
            setState(() {
              _initialized = true;
            });
            _controller.setLooping(true);
            _controller.setVolume(0);
            _controller.play();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppTheme.porpraFosc,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.mostassa),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 500, // Alçada ajustada a 500 per veure millor el contingut
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FittedBox(
        fit: BoxFit.cover, // Això fa que ocupi tot l'ample sense deformar-se
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
