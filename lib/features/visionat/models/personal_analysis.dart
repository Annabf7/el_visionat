import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enumeració d'origen de l'apunt personal
enum AnalysisSource {
  match('match', 'Partit', Icons.sports_basketball),
  test('test', 'Test', Icons.quiz),
  training('training', 'Formació', Icons.school);

  const AnalysisSource(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static AnalysisSource fromValue(String value) {
    return AnalysisSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => AnalysisSource.match,
    );
  }
}

/// Enumeració de categories d'anàlisi arbitral
enum AnalysisCategory {
  faltes('faltes', 'Faltes'),
  violacions('violacions', 'Violacions'),
  gestioControl('gestio_control', 'Gestió i Control'),
  posicionament('posicionament', 'Posicionament i Mecànica'),
  serveiRapid('servei_rapid', 'Servei ràpid');

  const AnalysisCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static AnalysisCategory fromValue(String value) {
    return AnalysisCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => AnalysisCategory.faltes,
    );
  }
}

/// Enumeració de tags d'anàlisi arbitral per categoria
enum AnalysisTag {
  // 1) Faltes
  faltaPersonal('falta_personal', 'Falta personal', AnalysisCategory.faltes),
  faltaEnRebot('falta_en_rebot', 'Falta en rebot', AnalysisCategory.faltes),
  faltaEnPantalla(
    'falta_en_pantalla',
    'Falta en pantalla',
    AnalysisCategory.faltes,
  ),
  faltaOfensivaCarregar(
    'falta_ofensiva_carregar',
    'Falta ofensiva per carregar',
    AnalysisCategory.faltes,
  ),
  faltaOfensivaBloqueig(
    'falta_ofensiva_bloqueig',
    'Falta ofensiva per bloqueig',
    AnalysisCategory.faltes,
  ),
  usIllegalMans(
    'us_illegal_mans',
    'Ús il·legal de mans',
    AnalysisCategory.faltes,
  ),
  faltaTecnica('falta_tecnica', 'Falta tècnica', AnalysisCategory.faltes),
  faltaAntiesportiva(
    'falta_antiesportiva',
    'Falta antiesportiva (C1, C2, C3, C4)',
    AnalysisCategory.faltes,
  ),
  faltaDesqualificant(
    'falta_desqualificant',
    'Falta desqualificant',
    AnalysisCategory.faltes,
  ),
  faltaServei(
    'falta_servei',
    'Falta de servei (últims 2 min)',
    AnalysisCategory.faltes,
  ),
  semicercleNoCarrega(
    'semicercle_no_carrega',
    'Semicercle de no càrrega',
    AnalysisCategory.faltes,
  ),
  contacteIllegalAmbAvantatge(
    'contacte_illegal_amb_avantatge',
    'Contacte il·legal amb avantatge guanyat',
    AnalysisCategory.faltes,
  ),
  // NOUS TAGS AFEGITS A FALTES
  rvbdConcepte(
    'rvbd_concepte',
    'RVBD (Ritme, Velocitat, Balanç i Direcció)',
    AnalysisCategory.faltes,
  ),
  simulacioFaltes('simulacio_faltes', 'Simulacions', AnalysisCategory.faltes),

  // 2) Violacions
  passos('passos', 'Passos', AnalysisCategory.violacions),
  dobles('dobles', 'Dobles', AnalysisCategory.violacions),
  peu('peu', 'Peu', AnalysisCategory.violacions),
  violacio3Segons(
    'violacio_3_segons',
    'Violació 3 segons',
    AnalysisCategory.violacions,
  ),
  violacio5Segons(
    'violacio_5_segons',
    'Violació 5 segons',
    AnalysisCategory.violacions,
  ),
  violacio8Segons(
    'violacio_8_segons',
    'Violació 8 segons',
    AnalysisCategory.violacions,
  ),
  violacio24Segons(
    'violacio_24_segons',
    'Violació 24 segons',
    AnalysisCategory.violacions,
  ),
  campEnrere('camp_enrere', 'Camp enrere', AnalysisCategory.violacions),
  interposicio(
    'interposicio',
    'Interposició (goaltending)',
    AnalysisCategory.violacions,
  ),
  interferencia('interferencia', 'Interferència', AnalysisCategory.violacions),
  violacioTirLliure(
    'violacio_tir_lliure',
    'Violació tir lliure (equip atacant / defensor / ambdós)',
    AnalysisCategory.violacions,
  ),
  tocarRetardarServei(
    'tocar_retardar_servei',
    'Tocar o retardar el servei (retoc il·legal + retard del servei)',
    AnalysisCategory.violacions,
  ),

  // 3) Gestió i Control
  comunicacioBanquetes(
    'comunicacio_banquetes',
    'Comunicació amb banquetes',
    AnalysisCategory.gestioControl,
  ),
  comunicacioArbitres(
    'comunicacio_arbitres',
    'Comunicació entre àrbitres',
    AnalysisCategory.gestioControl,
  ),
  seguretatControl(
    'seguretat_control',
    'Seguretat i control del joc',
    AnalysisCategory.gestioControl,
  ),
  protocolAvisos(
    'protocol_avisos',
    'Protocol d\'avisos (previ a tècnica)',
    AnalysisCategory.gestioControl,
  ),
  gestioConflictes(
    'gestio_conflictes',
    'Gestió de conflictes',
    AnalysisCategory.gestioControl,
  ),
  gestioPressioAmbiental(
    'gestio_pressio_ambiental',
    'Gestió de pressió ambiental',
    AnalysisCategory.gestioControl,
  ),
  gestioSituacionsFinalsPartit(
    'gestio_situacions_finals_partit',
    'Gestió de situacions finals de partit',
    AnalysisCategory.gestioControl,
  ),
  gestioPossessioAlternanca(
    'gestio_possessio_alternanca',
    'Gestió possessió d\'alternança',
    AnalysisCategory.gestioControl,
  ),
  controlRellotge(
    'control_rellotge',
    'Control del rellotge de partit i rellotge de tir',
    AnalysisCategory.gestioControl,
  ),
  gestioErrorsAdministratius(
    'gestio_errors_administratius',
    'Gestió d\'errors administratius',
    AnalysisCategory.gestioControl,
  ),
  // NOUS TAGS AFEGITS A GESTIÓ I CONTROL
  gestioEntrenadorLocal(
    'gestio_entrenador_local',
    'Gestió entrenador local',
    AnalysisCategory.gestioControl,
  ),
  gestioEntrenadorVisitant(
    'gestio_entrenador_visitant',
    'Gestió entrenador visitant',
    AnalysisCategory.gestioControl,
  ),

  // 4) Posicionament i Mecànica
  cap('cap', 'Cap', AnalysisCategory.posicionament),
  cua('cua', 'Cua', AnalysisCategory.posicionament),
  posicionamentFinestra(
    'posicionament_finestra',
    'Posicionament finestra',
    AnalysisCategory.posicionament,
  ),
  rotacions('rotacions', 'Rotacions', AnalysisCategory.posicionament),
  closeDown('close_down', 'Close down', AnalysisCategory.posicionament),
  crossStep('cross_step', 'Cross step', AnalysisCategory.posicionament),
  coberturaCostatDebil(
    'cobertura_costat_debil',
    'Cobertura costat dèbil',
    AnalysisCategory.posicionament,
  ),
  gestioCostatFort(
    'gestio_costat_fort',
    'Gestió costat fort',
    AnalysisCategory.posicionament,
  ),
  controlAngles(
    'control_angles',
    'Control d\'angles',
    AnalysisCategory.posicionament,
  ),
  transicionsRapidesDefensaAtac(
    'transicions_rapides_defensa_atac',
    'Transicions ràpides defensa–atac',
    AnalysisCategory.posicionament,
  ),

  // 5) Servei Ràpid
  aplicacioCorrectaServeiRapid(
    'aplicacio_correcta_servei_rapid',
    'Aplicació correcta del servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  aplicacioCorrectaServeiEstandard(
    'aplicacio_correcta_servei_estandard',
    'Aplicació correcta del servei estàndard',
    AnalysisCategory.serveiRapid,
  ),
  determinacioCorrectaPuntServei(
    'determinacio_correcta_punt_servei',
    'Determinació correcta del punt de servei',
    AnalysisCategory.serveiRapid,
  ),
  retardarPosadaJocAvis(
    'retardar_posada_joc_avis',
    'Retardar la posada en joc (avís)',
    AnalysisCategory.serveiRapid,
  ),
  retardarPosadaJocFaltaTecnica(
    'retardar_posada_joc_falta_tecnica',
    'Retardar la posada en joc (falta tècnica)',
    AnalysisCategory.serveiRapid,
  ),
  serveiDespresCostellaAplicacioCorrecta(
    'servei_despres_costella_aplicacio_correcta',
    'Servei després de cistella - aplicació correcta',
    AnalysisCategory.serveiRapid,
  ),
  situacioNoAplicaServeiRapid(
    'situacio_no_aplica_servei_rapid',
    'Situació on NO s\'aplica servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  lliuramentIncorrecteServeiRapid(
    'lliurament_incorrecte_servei_rapid',
    'Lliurament incorrecte de la pilota en servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  gestioCorrectaSubstitucionsServeiRapid(
    'gestio_correcta_substitucions_servei_rapid',
    'Gestió correcta de substitucions en servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  noPermetreTempsIncorrecteServeiRapid(
    'no_permetre_temps_incorrecte_servei_rapid',
    'No permetre temps mort incorrecte en servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  entrenadorCollaborantServeiRapid(
    'entrenador_collaborant_servei_rapid',
    'Entrenador col·laborant en el servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  entrenadorDificultantServeiRapid(
    'entrenador_dificultant_servei_rapid',
    'Entrenador dificultant el servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  violacionsServei5SegonsTrepitjarLinia(
    'violacions_servei_5_segons_trepitjar_linia',
    'Violacions de servei: 5 segons / trepitjar la línia',
    AnalysisCategory.serveiRapid,
  ),
  rectificarPuntServeiRapid(
    'rectificar_punt_servei_rapid',
    'Rectificar punt de servei ràpid',
    AnalysisCategory.serveiRapid,
  ),
  pilotPublicConvertirServeiEstandard(
    'pilot_public_convertir_servei_estandard',
    'Pilot al públic — convertir en servei estàndard',
    AnalysisCategory.serveiRapid,
  ),
  pilotBanquetesTaulaMantindreServeiRapid(
    'pilot_banquetes_taula_mantindre_servei_rapid',
    'Pilot a banquetes/taula — mantenir servei ràpid',
    AnalysisCategory.serveiRapid,
  );

  const AnalysisTag(this.value, this.displayName, this.category);

  final String value;
  final String displayName;
  final AnalysisCategory category;

  static AnalysisTag fromValue(String value) {
    return AnalysisTag.values.firstWhere(
      (tag) => tag.value == value,
      orElse: () => AnalysisTag.faltaPersonal,
    );
  }

  /// Obté tots els tags d'una categoria específica
  static List<AnalysisTag> getTagsByCategory(AnalysisCategory category) {
    return AnalysisTag.values.where((tag) => tag.category == category).toList();
  }
}

/// Model per a l'anàlisi personal d'un partit o test
/// Representa les notes privades d'un usuari sobre el seu arbitratge
class PersonalAnalysis {
  final String id;
  final String matchId;
  final String jornadaId;
  final String userId;
  final String userDisplayName;
  final String text;
  final List<AnalysisTag> tags;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isEdited;

  // Nous camps
  final AnalysisSource source; // Origen: partit o test
  final String ruleArticle; // Article del reglament (obligatori) ex: "Art. 33.10"
  final String? testId; // ID del test (si source == test)
  final String? matchName; // Nom del partit/test per mostrar

  const PersonalAnalysis({
    required this.id,
    required this.matchId,
    required this.jornadaId,
    required this.userId,
    required this.userDisplayName,
    required this.text,
    required this.tags,
    required this.createdAt,
    this.editedAt,
    required this.isEdited,
    this.source = AnalysisSource.match, // Per defecte: partit
    this.ruleArticle = '', // Per compatibilitat amb dades antigues
    this.testId,
    this.matchName,
  });

  /// Validació bàsica del model
  bool get isValid =>
      text.trim().isNotEmpty &&
      userId.isNotEmpty &&
      matchId.isNotEmpty &&
      jornadaId.isNotEmpty;

  /// Text formatat per mostrar les etiquetes
  String get tagsText => tags.map((tag) => tag.displayName).join(', ');

  /// Data formatada per mostrar
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inHours > 0) {
      return 'fa ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'fa ${difference.inMinutes} min';
    } else {
      return 'ara mateix';
    }
  }

  /// Indica si l'apunt ha estat editat
  String get editStatusText {
    if (isEdited && editedAt != null) {
      return 'Editat el ${editedAt!.day}/${editedAt!.month}/${editedAt!.year}';
    }
    return '';
  }

  /// Crea una còpia amb modificacions
  PersonalAnalysis copyWith({
    String? id,
    String? matchId,
    String? jornadaId,
    String? userId,
    String? userDisplayName,
    String? text,
    List<AnalysisTag>? tags,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isEdited,
    AnalysisSource? source,
    String? ruleArticle,
    String? testId,
    String? matchName,
  }) {
    return PersonalAnalysis(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      jornadaId: jornadaId ?? this.jornadaId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      source: source ?? this.source,
      ruleArticle: ruleArticle ?? this.ruleArticle,
      testId: testId ?? this.testId,
      matchName: matchName ?? this.matchName,
    );
  }

  /// Converteix a Map per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'jornadaId': jornadaId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'text': text,
      'tags': tags.map((tag) => tag.value).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isEdited': isEdited,
      'source': source.value,
      'ruleArticle': ruleArticle,
      'testId': testId,
      'matchName': matchName,
    };
  }

  /// Crea des de Map de Firestore
  factory PersonalAnalysis.fromJson(Map<String, dynamic> json) {
    return PersonalAnalysis(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      jornadaId: json['jornadaId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>)
          .map((tag) => AnalysisTag.fromValue(tag as String))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      editedAt: json['editedAt'] != null
          ? (json['editedAt'] as Timestamp).toDate()
          : null,
      isEdited: json['isEdited'] as bool,
      source: json['source'] != null
          ? AnalysisSource.fromValue(json['source'] as String)
          : AnalysisSource.match,
      ruleArticle: json['ruleArticle'] as String? ?? '',
      testId: json['testId'] as String?,
      matchName: json['matchName'] as String?,
    );
  }

  // Helpers per usar amb withConverter() de Firestore
  static Map<String, dynamic> Function(PersonalAnalysis, SetOptions?)
  get toFirestore =>
      (analysis, _) => analysis.toJson();

  static PersonalAnalysis Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  )
  get fromFirestore => (snapshot, _) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('No data found in Firestore document');
    }
    return PersonalAnalysis.fromJson(data);
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAnalysis &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          matchId == other.matchId &&
          jornadaId == other.jornadaId &&
          userId == other.userId &&
          userDisplayName == other.userDisplayName &&
          text == other.text &&
          _listEquals(tags, other.tags) &&
          createdAt == other.createdAt &&
          editedAt == other.editedAt &&
          isEdited == other.isEdited &&
          source == other.source &&
          ruleArticle == other.ruleArticle &&
          testId == other.testId &&
          matchName == other.matchName;

  @override
  int get hashCode =>
      id.hashCode ^
      matchId.hashCode ^
      jornadaId.hashCode ^
      userId.hashCode ^
      userDisplayName.hashCode ^
      text.hashCode ^
      tags.hashCode ^
      createdAt.hashCode ^
      editedAt.hashCode ^
      isEdited.hashCode ^
      source.hashCode ^
      ruleArticle.hashCode ^
      testId.hashCode ^
      matchName.hashCode;

  /// Helper per comparar llistes
  bool _listEquals(List<AnalysisTag> a, List<AnalysisTag> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'PersonalAnalysis{id: $id, matchId: $matchId, text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., tags: ${tags.length}, createdAt: $createdAt}';
  }
}
