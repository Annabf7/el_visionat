# Core Module

## Descripció

El mòdul **Core** conté tota la infraestructura central compartida per totes les features del projecte EL VISIONAT. Representa el nucli de l'aplicació amb components transversals que defineixen el comportament global.

## Responsabilitats

El mòdul Core s'encarrega de:

- **Models globals**: Enums i classes base utilitzades per múltiples features
- **Serveis centrals**: Persistència local (Isar), seeding de dades
- **Navegació**: Gestió d'estat de navegació i menú lateral
- **Tema visual**: Colors, tipografies i estils globals de l'aplicació
- **Utils globals**: Utilitats compartides (futura expansió)

## Arquitectura

Segueix l'arquitectura **feature-first** però amb un enfocament transversal:

```
core/
├── models/          # Models i enums globals
├── services/        # Serveis d'infraestructura central
├── navigation/      # Sistema de navegació global
├── theme/           # Tema visual de l'aplicació
├── utils/           # Utilitats compartides
├── index.dart       # Exportacions públiques
└── README.md        # Aquesta documentació
```

## Components Principals

### Models

- **`assessment_grade.dart`**:
  - Enum `AssessmentGrade` amb nivells d'avaluació arbitral
  - Classe base `RefereeAssessmentDraft` per futurs desenvolupaments
  - Utilitzat per avaluacions i análisis d'arbitratge

### Services

- **`isar_service.dart`**:

  - Export condicional per plataforma (native/web)
  - Gestiona la persistència local amb Isar
  - API unificada per cache local

- **`isar_service_io.dart`**:

  - Implementació completa per Android/iOS
  - Operacions CRUD amb base de dades Isar
  - Gestió de schemas i transaccions

- **`isar_service_stub.dart`**:

  - Implementació buida per web
  - Evita problemes de codegen a web
  - API compatible sense funcionalitat

- **`firestore_seeder.dart`**:
  - Seeding automàtic de dades inicials
  - Població de col·lecció `teams` des d'assets
  - Execució condicional (només si està buida)

### Navigation

- **`navigation_provider.dart`**:

  - `NavigationProvider`: Gestió d'estat de ruta actual
  - `NavigationObserver`: Observer per detectar canvis de ruta
  - Sincronització automàtica amb Material Navigator

- **`side_navigation_menu.dart`**:
  - Menú lateral principal de l'aplicació
  - Navegació entre features principals
  - ProfilePage integrada
  - Estil consistent amb tema visual

### Theme

- **`app_theme.dart`**:
  - Colors corporatius (púrpura, lila, mostassa, gris)
  - Theme Material 3 personalitzat
  - Tipografies (Geist, Inter)
  - Estils de botons i components

## Integració amb Features

### Importació

```dart
// Import complet del core
import 'package:el_visionat/core/index.dart';

// O imports específics
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/services/isar_service.dart';
```

### Ús del Tema

```dart
// En widgets
Container(
  color: AppTheme.porpraFosc,
  child: Text(
    'Text',
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppTheme.grisPistacho,
    ),
  ),
)

// En MaterialApp
MaterialApp(
  theme: AppTheme.theme,
  // ...
)
```

### Ús de Serveis

```dart
// Provider registration
Provider<IsarService>.value(value: IsarService()),

// Seeding
await seedTeamsIfEmpty(FirebaseFirestore.instance);

// Persistència
final isar = context.read<IsarService>();
final teams = await isar.getAllTeams();
```

### Navegació

```dart
// Provider registration
ChangeNotifierProvider(create: (_) => NavigationProvider()),

// Observer
final navProvider = Provider.of<NavigationProvider>(context, listen: false);
final navObserver = NavigationObserver(navProvider);

// Ruta actual
final currentRoute = context.watch<NavigationProvider>().currentRoute;
```

## Configuració i Setup

### 1. Registre de Providers (main.dart)

```dart
MultiProvider(
  providers: [
    // Serveis core
    Provider<IsarService>.value(value: IsarService()),

    // Navegació
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
  ],
  child: MyApp(),
)
```

### 2. Configuració de MaterialApp

```dart
MaterialApp(
  theme: AppTheme.theme,
  navigatorObservers: [NavigationObserver(navProvider)],
  // ...
)
```

### 3. Seeding Inicial

```dart
// Abans de runApp()
if (kIsWeb) {
  await seedTeamsIfEmpty(FirebaseFirestore.instance);
}
```

## Dependències

- `flutter/material.dart`: Components Material 3
- `provider`: Gestió d'estat
- `isar_community`: Persistència local (només native)
- `cloud_firestore`: Seeding de dades
- `flutter_svg`: Logo de l'aplicació
- `path_provider`: Directori de documents (només native)

## Estàndards Seguits

- ✅ **Architecture**: Modular, transversal, single responsibility
- ✅ **Flutter Guidelines**: Separation of concerns, providers
- ✅ **Firebase Patterns**: Seeding controlat, no lògica crítica
- ✅ **UI/UX Guidelines**: Colors corporatius, Material 3
- ✅ **Security Standards**: Cap exposició de dades sensibles
- ✅ **Project Conventions**: Noms consistents, documentació

## Futures Millores

- [ ] **Utils**: Validadors, formatters, extensions
- [ ] **Localització**: Suport multi-idioma (CA/ES/EN)
- [ ] **Logging**: Sistema centralitzat de logs
- [ ] **Cache**: Estratègies avançades de cache
- [ ] **Monitoring**: Metrics i analytics
- [ ] **Offline**: Suport offline-first

## Notes Importants

⚠️ **Web vs Native**:

- Isar només funciona en native (Android/iOS)
- Web utilitza stub sense persistència local
- Seeding només es fa en web per evitar Isar

⚠️ **Tema Global**:

- Tots els widgets han d'usar AppTheme per consistència
- No hardcodejar colors directament

⚠️ **Navegació**:

- NavigationObserver ha d'estar registrat a MaterialApp
- NavigationProvider manté sincronia automàtica
