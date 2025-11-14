class TagCategory {
  final String name;
  final String icon;
  final List<String> tags;

  const TagCategory({
    required this.name,
    required this.icon,
    required this.tags,
  });
}

/// Definicions completes de tags segons el Reglament FIBA
class TagDefinitions {
  static const List<TagCategory> categories = [
    TagCategory(
      name: 'Faltes Personals',
      icon: 'hand_back',
      tags: [
        'Bloqueig il·legal',
        'Càrrega',
        'Mans (ús il·legal de les mans)',
        'Contacte al tirador',
        'Falta en rebot',
        'Pantalla en moviment',
        'Retenir',
        'Empenta',
        'Falta per darrere',
        'Contacte innecessari',
        'Falta flagrant',
        'Contacte excessiu',
        'Obstrucció',
        'Falta d\'atac',
        'Falta defensiva',
      ],
    ),
    TagCategory(
      name: 'Violacions',
      icon: 'rule',
      tags: [
        'Passos',
        'Dobles',
        'Violació 3 segons',
        'Violació 5 segons',
        'Violació 8 segons',
        'Violació 24 segons',
        'Camp enrere',
        'Peus',
        'Fora de banda',
        'Sortida de camp',
        'Tir que no toca l\'anella',
        'Interferència ofensiva',
        'Interferència defensiva',
        'Interposició',
        'Pilota retornada a camp enrere',
        'Violació de salt',
        'Violació substitució',
      ],
    ),
    TagCategory(
      name: 'Faltes Tècniques',
      icon: 'warning',
      tags: [
        'Protesta excessiva',
        'Gesticulacions irrespuetuoses',
        'Simulació (flopping)',
        'Retardar el joc',
        'Entrar al camp sense permís',
        'Aplaudir a la cara',
        'Comunicació irrespectuosa',
        'Expressions ofensives',
        'Tècnica a banqueta',
        'Tècnica per equipament',
        'Tècnica per penjar-se de l\'anella',
        'Conducta antiesportiva lleu',
        'Desacord amb àrbitres',
        'Intimidació',
      ],
    ),
    TagCategory(
      name: 'Faltes Antiesportives i Desqualificants',
      icon: 'dangerous',
      tags: [
        'Antiesportiva C1 - Uo fer un esforç legítim',
        'Antiesportiva C2 - Un contacte excessiu o dur',
        'Antiesportiva C3 - Un contacte innecessari',
        'Antiesportiva C4 - Contacte il·legal pel darrere o lateralment',
        'Desqualificant per agressió',
        'Desqualificant per conducta verbal greu',
        'Desqualificant per acumulació tècniques',
        'Expulsió entrenador',
        'Expulsió jugador banqueta',
        'Conducta violent',
        'Amenaça física',
        'Conducta extrema',
      ],
    ),
    TagCategory(
      name: 'Gestió i Posicionament',
      icon: 'settings',
      tags: [
        'Posicionament incorrecte',
        'Rotació tardana',
        'Falta d\'angle visual',
        'Gestió de banquetes',
        'Control del rebot',
        'Control de conflictes',
        'Comunicació entre àrbitres',
        'Gestió del temps',
        'Control de la zona',
        'Anticipació incorrecta',
        'Mecànica incorrecta',
        'Senyal incorrecte',
        'Cronometratge',
        'Control de possessions',
      ],
    ),
    TagCategory(
      name: 'Situacions Especials',
      icon: 'special_char',
      tags: [
        'Situació de salt',
        'Error en l\'acta',
        'Error fletxa de possessió',
        'Revisió de jugada (IRS)',
        'Revisió de rellotge',
        'Revisió de interferència',
        'Canvi de decisions',
        'Protesta oficial',
        'Timeout tècnic',
        'Timeout oficial',
        'Situació final de partit',
        'Situació final de període',
        'Problema tècnic',
        'Lesió jugador',
        'Incident de públic',
        'Problema d\'equipament',
      ],
    ),
  ];

  /// Obtenir tots els tags en una llista plana per cerca
  static List<String> getAllTags() {
    return categories.expand((category) => category.tags).toList();
  }

  /// Cercar tags que coincideixin amb una consulta
  static List<String> searchTags(String query) {
    if (query.isEmpty) return getAllTags();

    final lowerQuery = query.toLowerCase();
    final allTags = getAllTags();

    return allTags.where((tag) {
      final lowerTag = tag.toLowerCase();

      // Coincidència exacta o conteniment
      if (lowerTag.contains(lowerQuery)) return true;

      // Sinònims i variants per millorar la cerca
      final synonyms = _getSynonyms(lowerTag);
      return synonyms.any((synonym) => synonym.contains(lowerQuery));
    }).toList();
  }

  /// Obtenir sinònims per millorar la cerca
  static List<String> _getSynonyms(String tag) {
    final synonymMap = {
      'passos (travelling)': ['travelling', 'caminar', 'pas'],
      'dobles (dribbling)': ['dribbling', 'bot', 'botar'],
      'violació 3 segons': ['3s', 'tres segons', '3 seg'],
      'violació 5 segons': ['5s', 'cinc segons', '5 seg'],
      'violació 8 segons': ['8s', 'vuit segons', '8 seg'],
      'violació 24 segons': ['24s', 'rellotge', '24 seg', 'possessió'],
      'camp enrere': ['backcourt', 'enrere'],
      'peu (kick ball)': ['kick', 'cop de peu', 'tocar amb peu'],
      'interferència': ['basket interference', 'tocar cistella'],
      'interposició (goaltending)': [
        'goaltending',
        'bloqueig il·legal cistella',
      ],
      'simulació (flopping)': ['flopping', 'teatre', 'simular'],
      'antiesportiva': ['unsportsmanlike', 'falta dura'],
      'desqualificant': ['disqualifying', 'expulsió'],
    };

    return synonymMap[tag] ?? [];
  }
}
