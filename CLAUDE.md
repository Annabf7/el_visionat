# El Visionat - Context per a Claude

## Descripció del Projecte

**El Visionat** és una aplicació mòbil per a àrbitres de bàsquet de la FCBQ (Federació Catalana de Bàsquet). Permet als àrbitres:
- Gestionar informes d'avaluació i tests
- Votar el partit de la setmana
- Consultar designacions i partits
- Seguir el seu progrés formatiu

**Idioma**: Tot el codi, comentaris i UI estan en **català**.

---

## Stack Tecnològic

| Component | Tecnologia |
|-----------|------------|
| Frontend | Flutter (Dart) |
| Backend | Firebase Cloud Functions (TypeScript) |
| Base de dades | Cloud Firestore |
| Autenticació | Firebase Auth |
| Storage | Firebase Storage |
| IA | Vertex AI Gemini (processament PDFs) |

---

## Estructura de Carpetes

```
el_visionat/
├── lib/                          # Codi Flutter
│   ├── core/
│   │   ├── models/               # Models de dades (Dart)
│   │   ├── theme/                # AppTheme, colors
│   │   └── utils/                # Utilitats generals
│   └── features/
│       ├── auth/                 # Autenticació i registre
│       │   └── providers/        # AuthProvider
│       ├── home/                 # Pàgina principal
│       ├── profile/              # Perfil d'usuari
│       ├── reports/              # Informes i tests
│       │   ├── models/
│       │   ├── pages/            # reports_page.dart, report_detail_page.dart
│       │   ├── providers/        # ReportsProvider
│       │   └── widgets/          # pdf_upload_button.dart, report_card.dart
│       ├── voting/               # Sistema de votacions
│       │   └── providers/        # VotingProvider
│       └── designations/         # Designacions de partits
│
├── functions/                    # Cloud Functions (TypeScript)
│   └── src/
│       ├── index.ts              # Exportacions de totes les functions
│       ├── auth/                 # Functions d'autenticació
│       ├── fcbq/                 # Integració amb FCBQ
│       │   ├── scraper.ts        # Scraping de basquetcatala.cat
│       │   ├── sync_weekly_voting.ts  # Votacions setmanals
│       │   ├── team_mapper.ts    # Mapping d'equips
│       │   └── types.ts          # Tipus TypeScript
│       ├── reports/
│       │   └── process_pdf.ts    # Processament PDFs amb Gemini
│       └── votes/                # Gestió de vots
│
└── assets/                       # Imatges, fonts, arxius estàtics
```

---

## Models Principals (Flutter)

### `RefereeReport` (lib/core/models/referee_report.dart)
Informe d'avaluació arbitral amb categories valorades.

```dart
// Escales de valoració:
// - Valoració Final: ÒPTIM | SATISFACTORI | MILLORABLE | NO SATISFACTORI
// - Categories: ÒPTIM | ACCEPTABLE | MILLORABLE | NO SATISFACTORI | NO VALORABLE
// - Camps especials: tenen escales pròpies (veure process_pdf.ts)
```

### `AssessmentGrade` (enum)
```dart
optim, satisfactori, acceptable, millorable, noSatisfactori
```

---

## Col·leccions Firestore

| Col·lecció | Descripció |
|------------|------------|
| `users` | Perfils d'usuari (àrbitres) |
| `reports` | Informes d'avaluació processats |
| `tests` | Tests teòrics processats |
| `votes` | Vots individuals per partit |
| `vote_counts` | Comptadors agregats per jornada |
| `voting_jornades` | Configuració de jornades de votació |
| `voting_meta` | Metadades del sistema de votació |
| `weekly_focus` | Document `current` amb el partit guanyador |
| `designations` | Designacions de partits |

### Estructura `weekly_focus/current`
```javascript
{
  jornada: 16,
  winningMatch: { home: "EQUIP A", away: "EQUIP B", ... },
  refereeInfo: {
    principal: "NOM ÀRBITRE",
    auxiliar: "NOM ÀRBITRE",
    anotador: "...",
    cronometrador: "...",
    // ...
  },
  votingClosedAt: Timestamp,
  suggestionsCloseAt: Timestamp
}
```

---

## Cloud Functions Principals

### `processPdfOnUpload` (functions/src/reports/process_pdf.ts)
- **Trigger**: Storage `onObjectFinalized` (quan es puja un PDF)
- **Funció**: Processa PDFs d'informes/tests amb Vertex AI Gemini
- **Escales d'avaluació**:
  - Tipus A (general): ÒPTIM | ACCEPTABLE | MILLORABLE | NO SATISFACTORI
  - Tipus B (opcional): + NO VALORABLE
  - Tipus C (final): ÒPTIM | SATISFACTORI | MILLORABLE | NO SATISFACTORI
  - Especials: CAPACITAT D'AUTOCRÍTICA, VALORACIÓ ACTITUD, DIFICULTAT PARTIT, ERRADES DECISIVES

### `syncWeeklyVoting` (functions/src/fcbq/sync_weekly_voting.ts)
- **Trigger**: Scheduler (dilluns 00:05)
- **Funció**: Processa el guanyador de la votació setmanal
- **Flux**: Detecta jornada → Obté guanyador → Scraping acta → Guarda refereeInfo

### `scrapeJornada` (functions/src/fcbq/scraper.ts)
- Scraping de `basquetcatala.cat/competicions/resultats`
- Extreu partits, resultats, actes i classificació
- Gestiona múltiples estructures HTML (.row, tr, fallback)

---

## Patrons i Convencions

### Providers (Flutter)
- Usem `Provider` + `ChangeNotifier` per a estat
- Exemple: `ReportsProvider`, `VotingProvider`, `AuthProvider`

### Noms de variables i funcions
- **Català** per a tot (variables, funcions, comentaris)
- camelCase per a variables i funcions
- PascalCase per a classes

### Gestió d'errors
- Cloud Functions: `logger.error()` + `throw new HttpsError()`
- Flutter: `try/catch` + `ScaffoldMessenger.showSnackBar()`

---

## Fluxos Importants

### 1. Pujada i processament de PDF
```
1. Usuari selecciona PDF → pdf_upload_button.dart
2. Puja a Firebase Storage → /pdfs/{userId}/{filename}
3. Trigger processPdfOnUpload → Gemini extreu dades
4. Guarda a Firestore → /reports/{id} o /tests/{id}
5. App detecta nou document → Mostra confirmació
```

### 2. Votació setmanal
```
1. Usuari vota partit → VotingProvider.vote()
2. Firestore incrementa comptador → vote_counts/{jornada}
3. Dilluns 00:05 → syncWeeklyVoting executa
4. Scraping acta FCBQ → Obté àrbitres
5. Guarda a weekly_focus/current
6. Home mostra "Equip Arbitral" i "Partit de la setmana"
```

### 3. Scraping FCBQ
```
1. fetchFcbqPage(jornada) → HTML de basquetcatala.cat
2. parseMatches() → Extreu partits amb equips i dates
3. Cerca actaUrl per matching d'equips (no per índex!)
4. fetchActaInfo(url) → Extreu àrbitres i oficials
```

---

## URLs i APIs externes

| Servei | URL Base |
|--------|----------|
| FCBQ Resultats | `https://www.basquetcatala.cat/competicions/resultats/{competitionId}/{jornada}` |
| FCBQ Actes | `https://www.basquetcatala.cat/acta/{actaId}` |
| Competition ID | `19795` (Super Copa Masculina) |

---

## Colors del tema (AppTheme)

| Color | Variable | Ús |
|-------|----------|-----|
| Verd | `verdeEncert` | Èxit, ÒPTIM |
| Lila | `lilaMitja` | SATISFACTORI/ACCEPTABLE |
| Mostassa | `mostassa` | MILLORABLE, warnings |
| Vermell | `Colors.redAccent` | NO SATISFACTORI, errors |
| Porpra fosc | `porpraFosc` | Botons principals |
| Gris | `grisPistacho` | Text secundari |

---

## Coses a tenir en compte

1. **No hi ha tests automàtics** - Verificar manualment
2. **Scraping FCBQ** - L'estructura HTML pot canviar, hi ha fallbacks
3. **Gemini** - El prompt és crític, les escales de valoració són específiques
4. **Firestore indexes** - Alguns queries compostos requereixen índexs
5. **Límits Firebase** - Storage 10MB per PDF, Functions 60s timeout

---

## Comandes útils

```bash
# Flutter
flutter analyze lib/
flutter run

# Firebase Functions
cd functions
npm run build
npm run lint
firebase deploy --only functions
firebase deploy --only functions:processPdfOnUpload

# Logs
firebase functions:log --only processPdfOnUpload
```

---

## Tasques recents / Context actual

- **Informes PDF**: Prompt de Gemini actualitzat amb totes les escales de valoració
- **Votacions**: Scraper arreglat per detectar actes amb matching d'equips
- **UI**: Resum de valoracions mostra SATISFACTORI (no ACCEPTABLE) per a valoració final
- **UX**: Diàleg de processament mentre s'analitza el PDF amb IA
