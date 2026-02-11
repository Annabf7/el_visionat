final List<NeuroRoutine> neuroRoutines = [
  NeuroRoutine(
    nom: 'Respiració controlada',
    descripcio:
        'Rutina de respiració per regular l’estrès i recuperar el focus.',
  ),
  NeuroRoutine(
    nom: 'Visualització positiva',
    descripcio: 'Imagina el play abans d’actuar per millorar la resposta.',
  ),
  NeuroRoutine(
    nom: 'Paraula clau',
    descripcio: 'Utilitza una paraula clau per trencar la cadena d’errors.',
  ),
  NeuroRoutine(
    nom: 'Micro-reset',
    descripcio: 'Aplica un gest o acció breu per recuperar el centre.',
  ),
];

// --- Mini Quiz Questions ---
class NeuroQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  NeuroQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

final List<NeuroQuizQuestion> neuroQuizQuestions = [
  NeuroQuizQuestion(
    question:
        'Quina part del cervell regula la resposta impulsiva en una decisió arbitral?',
    options: ['Amígdala', 'Còrtex prefrontal', 'Hipocamp', 'Cerebel'],
    correctIndex: 1,
  ),
  NeuroQuizQuestion(
    question:
        'Quina tècnica ajuda a trencar la cadena d’errors després d’una decisió incorrecta?',
    options: ['Visualització', 'Micro-reset', 'Fatiga simulada', 'Clip mut'],
    correctIndex: 1,
  ),
  NeuroQuizQuestion(
    question: 'Què pot provocar una “amygdala hijack” en l’arbitratge?',
    options: [
      'Respiració controlada',
      'Acumulació d’estrès',
      'Postura corporal',
      'Co-regulació',
    ],
    correctIndex: 1,
  ),
];
// Models locals per NeuroVisionat
// Modularitzat per feature

class NeuroSection {
  final String titol;
  final String subtitol;
  final List<String> paragrafs;
  final String principiClau;
  final List<String> biaixos;
  final List<NeuroExercise> exercicis;
  const NeuroSection({
    required this.titol,
    required this.subtitol,
    required this.paragrafs,
    required this.principiClau,
    this.biaixos = const [],
    required this.exercicis,
  });
}

class NeuroExercise {
  final String titol;
  final List<String> passos;
  const NeuroExercise({required this.titol, required this.passos});
}

class NeuroTip {
  final String text;
  final String autor;
  const NeuroTip({required this.text, required this.autor});
}

class NeuroRoutine {
  final String nom;
  final String descripcio;
  const NeuroRoutine({required this.nom, required this.descripcio});
}
