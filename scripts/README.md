# Scripts de manteniment - El Visionat

## Sistema Weekly Focus (Votació Setmanal)

El sistema de votacions setmanals és **completament automatitzat** mitjançant Cloud Functions scheduled:

### Flux Automàtic

| Dia       | Hora  | Acció                                         | Cloud Function     |
| --------- | ----- | --------------------------------------------- | ------------------ |
| Dilluns   | 8:00  | Publicar jornada + obrir votació              | `syncWeeklyVoting` |
| Dilluns   | 8:00  | Tancar votació anterior + processar guanyador | `syncWeeklyVoting` |
| Dimecres  | 15:00 | Tancar suggeriments i minutatge               | `closeSuggestions` |
| Divendres | 18:00 | Publicar entrevista                           | **Manual**         |

### Col·lecció `weekly_focus`

```
weekly_focus/{jornada}
├── jornada: number
├── matchDate: { start: Timestamp, end: Timestamp }
├── status: 'active' | 'votingClosed' | 'completed'
├── winningMatch: MatchSummary | null
├── interview: InterviewData | null
├── matches: MatchSummary[]
├── votingStartDate: Timestamp
├── votingEndDate: Timestamp
└── pavello: string | null  // Extret automàticament
```

---

## Scripts disponibles

### Operacions manuals (quan cal intervenció)

| Script                     | Descripció                         | Ús                                      |
| -------------------------- | ---------------------------------- | --------------------------------------- |
| `setup_jornada12_focus.js` | Configurar weekly_focus manualment | `node scripts/setup_jornada12_focus.js` |
| `force_winner.js`          | Forçar processament de guanyador   | `node scripts/force_winner.js`          |
| `check_matchids.js`        | Verificar matchIds a Firestore     | `node scripts/check_matchids.js`        |
| `trigger_sync.js`          | Disparar sync manualment           | `node scripts/trigger_sync.js`          |

### Seed de dades

| Comanda               | Descripció                          |
| --------------------- | ----------------------------------- |
| `npm run seed:emu`    | Seed de dades al Firestore emulator |
| `npm run seed:teams`  | Seed d'equips                       |
| `npm run seed:voting` | Seed de votacions                   |

---

## Diccionari d'equips (`supercopa_teams.json`)

📁 **Font única**: `assets/data/supercopa_teams.json`

Aquest fitxer és l'única font de veritat per al diccionari d'equips de la Super Copa.
Tant Flutter com qualsevol script o servei backend han de llegir directament aquest fitxer.

### Format del JSON

```json
{
  "id": "identificador-unic",
  "name": "NOM OFICIAL FCBQ",
  "acronym": "ACR",
  "gender": "Masculina" | "Femenina",
  "colorHex": "#RRGGBB",
  "logoAssetPath": "assets/images/teams/nom-fitxer.webp" | null,
  "aliases": ["VARIANT 1", "VARIANT 2"]
}
```
