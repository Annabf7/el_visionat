# Teams Feature

## Descripció

La feature **Teams** gestiona tots els equips de bàsquet dins l'aplicació EL VISIONAT. Proporciona funcionalitats per carregar, visualitzar i filtrar els equips de la Federació Catalana de Bàsquet.

## Arquitectura

Segueix l'arquitectura **feature-first** del projecte amb separació clara de responsabilitats:

```
teams/
├── models/          # Models de dades i tipologia
├── services/        # Lògica de negoci i accés a dades
├── providers/       # Gestió d'estat reactiu
├── pages/           # Pantalles de la UI
├── widgets/         # Components reutilitzables
├── index.dart       # Exportacions públiques
└── README.md        # Aquesta documentació
```

## Components Principals

### Models

- **`team.dart`**: Model principal amb anotacions Isar per persistència local
- **`team.g.dart`**: Codi generat per Isar (no modificar)
- **`team_platform.dart`**: Export condicional per native/web
- **`team_io.dart`**: Re-export per compatibilitat amb legacy
- **`team_stub.dart`**: Model lleuger per web (sense Isar)

### Services

- **`team_data_service.dart`**:
  - Gestiona la càrrega d'equips des de Firestore
  - Implementa cache local amb Isar (només native)
  - Fallback directe a Firestore en web
  - Sincronització automàtica

### Providers

- **`team_provider.dart`**:
  - Gestió d'estat reactiu per la UI
  - Control de loading i errors
  - Funcionalitats de cerca i filtratge
  - Refresh de dades

### Pages

- **`teams_page.dart`**:
  - Pantalla principal de visualització d'equips
  - Cerca per nom/acrònim
  - Filtre per gènere (masculí/femení)
  - Pull-to-refresh
  - Estats d'error i empty state

### Widgets

- **`team_card.dart`**:
  - Card individual per mostrar informació d'equip
  - Logo (amb fallback)
  - Indicador visual de gènere
  - Segueix les UI guidelines del projecte

## Flux de Dades

```
UI (TeamsPage)
    ↓
TeamProvider
    ↓
TeamDataService
    ↓
Firestore ←→ Isar (cache local)
```

## Models de Dades

```dart
class Team {
  Id id;                    // ID Isar auto-increment
  String firestoreId;       // ID del document Firestore
  String name;              // Nom complet de l'equip
  String acronym;           // Acrònim/sigles
  String gender;            // 'masculí' | 'femení'
  String? logoUrl;          // URL del logo (opcional)
}
```

## Integració amb Firebase

### Col·lecció Firestore: `teams`

```json
{
  "name": "FC Barcelona",
  "acronym": "FCB",
  "gender": "masculí",
  "logoUrl": "https://example.com/logo.png"
}
```

### Regles de Seguretat

- **Lectura**: Pública (tots els usuaris autenticats)
- **Escriptura**: Només administradors via Cloud Functions

## Ús

### 1. Registre del Provider

```dart
// A main.dart
ChangeNotifierProvider(
  create: (context) => TeamProvider(
    teamDataService: context.read<TeamDataService>(),
  ),
),
```

### 2. Navegació a la Pàgina

```dart
Navigator.pushNamed(context, '/teams');
```

### 3. Accés a Dades

```dart
// Dins d'un widget
final teamProvider = context.watch<TeamProvider>();
final teams = teamProvider.teams;
final isLoading = teamProvider.isLoading;
```

## Dependències

- `provider`: Gestió d'estat
- `cloud_firestore`: Accés a dades remotes
- `isar_community`: Persistència local (només native)
- Theme del projecte (`AppTheme`)

## Estàndards Seguits

- ✅ **Architecture**: Feature-first, separation of concerns
- ✅ **Flutter Guidelines**: StatelessWidget preferent, providers per estat
- ✅ **Firebase Patterns**: Services per accés, no Firebase directe a UI
- ✅ **UI/UX Guidelines**: Cards amb radius 16, colors AppTheme
- ✅ **Security Standards**: Només lectura des del client
- ✅ **Project Conventions**: Noms consistents, comentaris útils

## Futures Millores

- [ ] Cache intelligent amb TTL
- [ ] Filtres avançats (categoria, regió)
- [ ] Ordenació personalitzada
- [ ] Sync offline-first
- [ ] Estadístiques d'equips
