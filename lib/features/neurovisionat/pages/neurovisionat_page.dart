import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/neurovisionat_models.dart';
import '../widgets/neuro_pillars_section.dart';
import '../widgets/neuro_tip_card.dart';
import '../widgets/neuro_mini_quiz.dart';
import '../widgets/neuro_routines_selector.dart';
import '../widgets/neuro_scientific_framework_section.dart';
import '../widgets/neuro_cta_section.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';

class NeuroVisionatPage extends StatelessWidget {
  const NeuroVisionatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;
        if (isLargeScreen) {
          // Desktop layout: SideNavigationMenu + GlobalHeader + content
          return Scaffold(
            key: _scaffoldKey,
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
                        scaffoldKey: _scaffoldKey,
                        title: 'NeuroVisionat',
                        showMenuButton: false,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _NeuroHeroHeader(),
                              ),
                              // Neuro-tip
                              Card(
                                color: AppTheme.porpraFosc.withValues(
                                  alpha: 0.92,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: const NeuroTipCard(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Mini quiz
                              Card(
                                color: AppTheme.grisBody,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: NeuroMiniQuiz(
                                    questions: neuroQuizQuestions,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Routines selector
                              Card(
                                color: AppTheme.grisBody,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: NeuroRoutinesSelector(
                                    routines: neuroRoutines,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Divider for pillars
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  color: AppTheme.porpraFosc.withValues(
                                    alpha: 0.18,
                                  ),
                                  thickness: 2,
                                ),
                              ),
                              // Pillars section
                              NeuroPillarsSection(sections: neuroPillars),
                              const SizedBox(height: 18),
                              // Divider for scientific framework
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  color: AppTheme.porpraFosc.withValues(
                                    alpha: 0.18,
                                  ),
                                  thickness: 2,
                                ),
                              ),
                              // Scientific framework
                              Card(
                                color: AppTheme.grisBody,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child:
                                      const NeuroScientificFrameworkSection(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // CTA final
                              Card(
                                color: AppTheme.porpraFosc,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 24,
                                  ),
                                  child: const NeuroCTASection(),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout: Drawer + GlobalHeader + content
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.grisBody,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'NeuroVisionat',
                  showMenuButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child: _NeuroHeroHeader(),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: const NeuroTipCard(),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          child: NeuroMiniQuiz(questions: neuroQuizQuestions),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          child: NeuroRoutinesSelector(routines: neuroRoutines),
                        ),
                        const SizedBox(height: 8),
                        NeuroPillarsSection(sections: neuroPillars),
                        const SizedBox(height: 8),
                        const NeuroScientificFrameworkSection(),
                        const SizedBox(height: 8),
                        const NeuroCTASection(),
                        const SizedBox(height: 16),
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

class _NeuroHeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.porpraFosc, AppTheme.grisBody],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NeuroVisionat',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Neurociència aplicada a l’arbitratge de bàsquet',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.grisPistacho,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'La ment també s’entrena. Entrena el cervell que decideix.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.white.withValues(alpha: 0.85),
              letterSpacing: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
