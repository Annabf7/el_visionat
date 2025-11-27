import '../models/activity_model.dart';
import '../models/question_model.dart';

/// Mock activities for training module (including real FCBQ activity)
final List<ActivityModel> mockActivities = [
  // ACTIVITAT 1 REAL FCBQ
  ActivityModel(
    id: 'act1',
    title: 'Activitat 1 – Situacions de joc i aplicació del reglament',
    youtubeVideoId: 's4QjYs2Wk0s', // vídeo inicial (introducció)
    availableFrom: null,
    questions: [
      QuestionModel(
        enunciat: 'Jugada 1',
        opcions: [
          'És una situació de servei estàndard',
          'És una situació de servei ràpid',
        ],
        respostaCorrectaIndex: 0,
        youtubeVideoId: 's4QjYs2Wk0s',
        comment:
            'La cistella ha estat cancel·lada, per tant correspon realitzar un servei estàndard.',
      ),
      QuestionModel(
        enunciat: 'Jugada 2',
        opcions: [
          'Cal concedir 2 tirs per acció contínua',
          'Cal concedir banda de fons',
          'Cal concedir banda de lateral',
        ],
        respostaCorrectaIndex: 0,
        youtubeVideoId: 'eH-iEw-z-WM',
        comment:
            'El jugador no pot llançar a causa del contacte rebut; no està passant la pilota.',
      ),
      QuestionModel(
        enunciat: 'Jugada 3',
        opcions: [
          'Falta tècnica immediata per simular de manera flagrant',
          'Incorrectament s\'adverteix per simular',
          'S\'adverteix correctament per simular, en ser la primera del partit',
        ],
        respostaCorrectaIndex: 1,
        youtubeVideoId: 'TuJ--CmR0lg',
        comment:
            'Acció accidental: no advertim coses que no hem vist de manera completa.',
      ),
      QuestionModel(
        enunciat: 'Error d\'anotació de temps mort (3r quart, 1:43)',
        opcions: [
          'L\'error ja no és rectificable',
          'Es pot rectificar fins la signatura de l\'acta',
          'Es pot rectificar fins el final del partit',
        ],
        respostaCorrectaIndex: 0,
        comment:
            'Error de categoria 1 (Art. 44); l\'oportunitat per corregir-lo ja ha finalitzat.',
      ),
      QuestionModel(
        enunciat: 'Violació en el servei d\'inici del segon quart',
        opcions: [
          'La pista del darrere amb 24 segons',
          'Mig camp amb 24 segons',
          'La pista davantera amb 14 segons',
        ],
        respostaCorrectaIndex: 1,
        comment:
            'Les violacions en el servei a la línia de mig camp es serviran des de mig camp. Art. 17.',
      ),
    ],
  ),
  // Dummy activities (mantenim per referència/demo)
  ActivityModel(
    id: 'a1',
    title: 'Sortides de pilota',
    youtubeVideoId: 'dQw4w9WgXcQ',
    questions: [
      QuestionModel(
        enunciat: 'Quina és la millor opció en una sortida pressionada?',
        opcions: ['Passar ràpid', 'Botar fort', 'Esperar company'],
        respostaCorrectaIndex: 0,
      ),
      QuestionModel(
        enunciat: 'Quin error és més comú?',
        opcions: ['Pèrdua de pilota', 'Passar sense mirar', 'No moure’s'],
        respostaCorrectaIndex: 1,
      ),
    ],
  ),
  ActivityModel(
    id: 'a2',
    title: 'Defensa en zona',
    youtubeVideoId: null,
    questions: [
      QuestionModel(
        enunciat: 'Quin avantatge té la defensa en zona?',
        opcions: ['Cobrir espais', 'Pressionar home', 'Atacar ràpid'],
        respostaCorrectaIndex: 0,
      ),
    ],
  ),
];
