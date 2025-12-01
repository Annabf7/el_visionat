import '../models/activity_model.dart';
import '../models/question_model.dart';

final List<ActivityModel> mockActivities = [
  // --- ACTIVITAT 1 ---
  ActivityModel(
    id: 'act1',
    title: 'Activitat 1 – Situacions de joc i aplicació del reglament',
    youtubeVideoId: 's4QjYs2Wk0s',
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
        enunciat:
            'Durant el tercer quart s\'anota per error un temps mort a l\'entrenador A en comptes de l\'entrenador B que era qui l\'havia demanat. Els àrbitres reconeixen l\'error quan queda 1:43 per acabar el partit.',
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
        enunciat:
            "A5 fa una violació en el servei d'inici del segon quart, trepitjant dins del camp en la seva pista del darrere. L'equip B servirà des de",
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

  // --- ACTIVITAT 2 ---
  ActivityModel(
    id: 'a2',
    title: 'Activitat 2 – Situacions reals d\'arbitratge',
    youtubeVideoId: null,
    questions: [
      QuestionModel(
        enunciat: "Jugada 1: Si l'àrbitra no fa el senyal de nou compte",
        opcions: [
          'El rellotge no es reiniciarà i cap senyal es farà des de la taula',
          'El rellotge no es reiniciarà immediatament però l\'operador cridarà l\'atenció de l\'àrbitra per confirmar si hi ha o no nou compte',
          'En situacions tan evidents no cal esperar el senyal, l\'operador posarà immediatament 14',
        ],
        respostaCorrectaIndex: 1,
        youtubeVideoId: 'nw9t-lMLfC4',
        comment:
            "Aquesta és una clara situació de nou compte, la pilota va ser jugada amb el peu i l'àrbitra així ho sanciona. Si per error oblida fer el senyal de nou compte, l'operador cridarà la seva atenció i consultarà si ha de reiniciar o no. En cap cas pot prendre la decisió per si sol.",
      ),
      QuestionModel(
        enunciat: 'Jugada 2',
        opcions: ['Falta per càrrega', 'Falta per bloqueig', 'RBVD'],
        respostaCorrectaIndex: 0,
        youtubeVideoId: 'jtDOpBQwt1o',
        comment:
            "El defensor obté una PLD (dos peus a terra, encarat a l'oponent, dins del cilindre) sobre un jugador amb pilota, una fracció de temps abans que aquest el desplaci en el tors. En ser un jugador amb pilota no té dret als elements temps/distància i per tant una falta per carregar s'ha de sancionar.",
      ),
      QuestionModel(
        enunciat: 'Jugada 3',
        opcions: [
          'Falta personal en acció contínua (2 tirs lliures)',
          'Falta personal (banda)',
          'Falta antiesportiva per criteri C1',
        ],
        respostaCorrectaIndex: 2,
        youtubeVideoId: 'ns5hxxwjcLg',
        comment:
            'Clara situació de falta per criteri C1, doncs el jugador no fa cap esforç legítim per jugar la pilota.',
      ),
      QuestionModel(
        enunciat:
            "L'equip A serveix de fons després d'un temps mort i quan passen 3\", tenint la pilota A4 driblant a la pista del darrere, l'àrbitre detecta que l'equip A té 6 jugadors a la pista. Es sanciona falta tècnica a l'entrenador i després del tir lliure.",
        opcions: [
          'L\'equip B servirà de banda a la pista davantera amb 14"  en el rellotge de llançament',
          'L\'equip A servirà de banda a la pista del darrere amb 21" en el rellotge de llançament i 5" per passar de camp',
          'L\'equip A servirà de banda a la pista del darrere amb 21" en el rellotge de llançament i 8" per passar de camp',
        ],
        respostaCorrectaIndex: 1,
        comment:
            "L'equip A té la pilota i és el responsable de la FT. Els comptes de 24 i 8 seguiran.",
      ),
      QuestionModel(
        enunciat:
            "La pilota té una petita fracció dins de la cistella quan un adversari la treu. Els àrbitres sancionen violació d'interferència i concedeixen la cistella.",
        opcions: [
          'Es poden concedir temps morts i substitucions a tots dos equips',
          'Només és oportunitat de temps mort per l\'equip que rep la cistella',
          'Només és oportunitat de temps mort i substituciósi és durant els dos darrers minuts del partit',
        ],
        respostaCorrectaIndex: 0,
        comment:
            "S'ha sancionat una violació de l'equip defensor, per tant aquesta és una oportunitat de temps mort i substitució pels dos equips.",
      ),
    ],
  ),

  // --- ACTIVITAT 3 ---
  ActivityModel(
    id: 'a3',
    title: 'Activitat 3 – Casos pràctics d\'arbitratge',
    youtubeVideoId: null,
    questions: [
      QuestionModel(
        enunciat: 'Jugada 1',
        opcions: [
          'Contacte accidental, no pitar',
          'Falta personal atacant',
          'Falta antiesportiva atacant',
        ],
        respostaCorrectaIndex: 1,
        youtubeVideoId: 'EpuabGUgoaQ',
        comment:
            "Tot i que l'atacant fa un moviment normal del joc i no fa un ús excessiu dels colzes, causa un evident contacte sobre l'adversari que cal penalitzar com a falta personal.",
      ),
      QuestionModel(
        enunciat: 'Jugada 2 (encara no hi ha cap avís per retard)',
        opcions: [
          'Cal donar un avís immediatament',
          'Cal donar un avís a la propera pilota morta i rellotge aturat',
          'No cal donar cap avís',
        ],
        respostaCorrectaIndex: 2,
        youtubeVideoId: 'F99fEIsPzTo',
        comment: 'En aquesta jugada cap retard es produeix.',
      ),
      QuestionModel(
        enunciat: 'Jugada 3',
        opcions: [
          'Falta antiesportiva C1',
          'Falta antiesportiva C4',
          'Falta personal',
        ],
        respostaCorrectaIndex: 2,
        youtubeVideoId: 'PRXwbV_T5xE',
        comment: 'El jugador defensor fa un esforç legítim per jugar la pilota',
      ),
      QuestionModel(
        enunciat:
            "A6 bota la pilota a la pista del darrere amb 6 segons per passar de camp i 22 segons en el rellotge de llançament quan l'àrbitre sanciona FT a A4 i B5 que estan a la pista davantera. Es concedeix pilota de banda a l'equip A a",
        opcions: [
          'Pista del darrere amb 6 segons per passar i 22 per tirar',
          'Pista davantera amb 22 segons per tirar',
          'Pista davantera amb 14 segons',
        ],
        respostaCorrectaIndex: 0,
        comment:
            'Les faltes tècniques es compensen i es concedeix pilota de banda a l\'equip que la tenia des del lloc més proper on estava la pilota amb el que restava per passar de camp i en el rellotge de possessió.',
      ),
      QuestionModel(
        enunciat:
            'La pilota toca un suport de la cistella i correspon als adversaris un servei ràpid que es farà de',
        opcions: ['Lateral', 'Fons', 'El servei ha de ser estàndard'],
        respostaCorrectaIndex: 1,
        comment:
            "Es tracta d'una violació de fora de banda, per tant s'haurà de treure des del lloc més proper on va passar, en aquest cas de fons.",
      ),
    ],
  ),

  // --- ACTIVITAT 4 ---
  ActivityModel(
    id: 'a4',
    title: 'Activitat 4 – Regles i situacions especials',
    youtubeVideoId: null,
    questions: [
      QuestionModel(
        enunciat: "Jugada 1",
        opcions: [
          "Passes a l'inici del driblatge",
          "Passes al final del driblatge",
          "Jugada legal",
        ],
        respostaCorrectaIndex: 1,
        youtubeVideoId: 'qiSj9rNVi7g',
        comment:
            "El jugador finalitza el driblatge i realitza fins a sis recolzaments abans de tirar. Situacions tan evidents no poden quedar sense penalitzar.",
      ),
      QuestionModel(
        enunciat: 'Jugada 2',
        opcions: [
          'Violació de passes',
          'Violació de doble regat',
          'Jugada legal',
        ],
        respostaCorrectaIndex: 0,
        youtubeVideoId: 'VPZlxTulPoE',
        comment:
            "El jugador finalitza el driblatge i s'aixeca amb la pilota a les mans, tornant a terra sense haver passat o tirat a cistella, passes.",
      ),
      QuestionModel(
        enunciat: 'Jugada 3',
        opcions: [
          "El servei es realitza correctament de fons",
          "El servei s'havia de realitzar de lateral a l'alçada de tirs lliures, sempre en la línia oposada a la taula d'auxiliars",
          "El servei s'havia de realitzar de lateral a l'alçada de tirs lliures, en la banda que decideixin els àrbitres per proximitat a l'acció",
        ],
        respostaCorrectaIndex: 2,
        youtubeVideoId: 'Kzdwxcsxxyc',
        comment:
            "L'article 17 no especifica quina línia lateral serà la que han d'escollir els àrbitres, per tant, seguint la pròpia regla, triaran la més propera. Si s'ha aconseguit una cistella no vàlida no es podrà fer el servei de la línia de fons.",
      ),
      QuestionModel(
        enunciat:
            "En un partit de categoria junior, B4 fa una violació de passes a la seva pista davantera, deixa anar la pilota que és agafada ràpidament per A4 per efectuar un servei ràpid. Abans de que A4 estigui en disposició d'efectuar el servei un àrbitre demana aturar el partit per eixugar la pista. En aquell moment es demana una substitució",
        opcions: [
          "Només l'equip A té oportunitat de substitució",
          "Hi ha oportunitat de substitució pels dos equips",
          "No hi ha oportunitat de substitució per cap equip",
        ],
        respostaCorrectaIndex: 2,
        comment:
            "Excepte a SuperCopa, les substitucions o temps mort han de demanar-se abans de que l'àrbitre hagi fet sonar el xiulet en sancionar una violació. En aquesta situació descrita en la pregunta es mantenen les restriccions per servei ràpid.",
      ),
      QuestionModel(
        enunciat:
            "A un partit de 1a Catalana o Supercopa es produeix un servei ràpid a favor de l'equip A, mentre B4 va a buscar la pilota, la qual s'ha allunyat de la pista, la seva entrenadora demana temps mort.",
        opcions: [
          "No es pot concedir en cap categoria",
          "No es pot concedir a 1a Catalana , però sí a SuperCopa",
          "Es pot concedir a 1a Catalana i a SuperCopa",
        ],
        respostaCorrectaIndex: 0,
        comment:
            "Excepte a SuperCopa, les peticions de substitució o temps mort han de realitzar-se abans de que l'àrbitre faci sonar el xiulet. En el cas que fos SuperCopa, es podria concedir el canvi encara, només a l'equip que té dret al servei ràpid.",
      ),
    ],
  ),

  // --- ACTIVITAT 5 ---
  ActivityModel(
    id: 'a5',
    title: 'Activitat 5 – Casos reals d\'arbitratge',
    youtubeVideoId: null,
    questions: [
      QuestionModel(
        enunciat: 'Jugada 1',
        opcions: [
          'Violació per doble driblatge per botar per sobre de l\'espatlla',
          'Violació per doble driblatge per finalitzar el driblatge i iniciar un de nou',
          'Jugada legal',
        ],
        respostaCorrectaIndex: 1,
        youtubeVideoId: '9ohxjvRcAhc',
        comment:
            'La jugadora finalitza el seu driblatge en posar la mà per sota de la pilota i torna a iniciar-ne un de nou.',
      ),
      QuestionModel(
        enunciat: 'Jugada 2',
        opcions: [
          'Falta antiesportiva C4',
          'Falta antiesportiva C1',
          'Falta personal',
        ],
        respostaCorrectaIndex: 2,
        youtubeVideoId: 'EuR3pHvQ1Ow',
        comment:
            'El jugador fa un esforç legítim per jugar la pilota i provoca un contacte quan el jugador ja ha finalitzat el seu contraatac iniciant l\'acció de tirar a cistella.',
      ),
      QuestionModel(
        enunciat: 'Jugada 3',
        opcions: [
          'Falta personal',
          'Falta antiesportiva C1',
          'Contacte legal, res a penalitzar',
        ],
        respostaCorrectaIndex: 0,
        youtubeVideoId: '8ggmE_up1r8',
        comment:
            "El defensor salta a impedir un llançament i en aterrar posa el peu en el lloc on el tirador cau, provocant un contacte que cal penalitzar. Hem de protegir el llançadors d'aquest tipus d'accions que poden provocar greus lesions. En aquest cas el defensor fa un esforç legítim per defensar, però si no el fes i simplement posés el peu, una falta antiesportiva caldria sancionar.",
      ),
      QuestionModel(
        enunciat:
            "En el darrer tir lliure d'un sèrie B5, al passadís, entra dins de l'àrea restringida. Posteriorment el tirador A4 deixa anar la pilota trepitjant la línia de tir lliure però sense tocar l'interior de l'àrea. La cistella entra.",
        opcions: [
          "Cistella vàlida d'A4, el partit continua amb servei de B des de fons.",
          "Violació del tirador preval per sobre de la de B5, cistella no vàlida i pilota per l'equip B.",
          "Cistella no vàlida i situació de possessió alterna.",
        ],
        respostaCorrectaIndex: 2,
        comment:
            "En primer lloc cal recordar que la línia de l'àrea restringida forma part d'ella, pert tant el tirador fa una violació a l'igual que el defensor que entra abans. En segon lloc, aquesta és una interpretació oficial, en haver una violació d'ambdós equips es produeix una situació de salt. La violació del llançador no preval sobre la de cap altre jugador.",
      ),
      QuestionModel(
        enunciat:
            "En el salt inicial l'àrbitre tira la pilota en l'aire quan A5 i B4 salten, tocant la pilota B4. La pilota bota a terra i A5 l'agafa amb les dues mans. El rellotge de joc indica 9:57.",
        opcions: [
          "Violació d'A5, el rellotge es deixarà en 9:57.",
          "Violació d'A5, el rellotge es corregirà indicant 10:00.",
          "Jugada legal.",
        ],
        respostaCorrectaIndex: 2,
        comment:
            "Un cop la pilota després de ser tocada pels saltadors és tocada per qualsevol altre jugador no participant en el salt o bé toca el terra, ja pot ser controlada pels saltadors.",
      ),
    ],
  ),
];
