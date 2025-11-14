# Home Feature

Gestiona la funcionalitat principal de la pàgina d'inici de l'aplicació El Visionat.

## Estructura

```
lib/features/home/
├── index.dart                          # Exportacions principals del feature
├── pages/
│   └── home_page.dart                  # Pàgina principal de l'aplicació
├── providers/
│   └── home_provider.dart              # Proveïdor d'estat per dades de l'inici
└── widgets/
    ├── featured_visioning_section.dart # Secció destacada de visionat
    └── user_profile_summary_card.dart  # Targeta resum del perfil d'usuari
```

## Components Principals

### `HomePage`

- **Localització**: `pages/home_page.dart`
- **Propòsit**: Pàgina principal de l'aplicació amb navegació i contingut destacat
- **Responsabilitats**:
  - Mostrar el contingut principal i navegació
  - Integrar seccions de visionat destacat i perfil d'usuari
  - Gestionar l'estat de la interfície d'usuari

### `HomeProvider`

- **Localització**: `providers/home_provider.dart`
- **Propòsit**: Proveïdor d'estat per a les dades de la pàgina d'inici
- **Responsabilitats**:
  - Gestionar dades de contingut destacat
  - Proporcionar informació de partits setmanals
  - Mantenir dades del perfil de l'àrbitre

### Widgets

#### `FeaturedVisioningSection`

- **Localització**: `widgets/featured_visioning_section.dart`
- **Propòsit**: Secció destacada amb contingut de visionat premium
- **Funcionalitat**:
  - Mostra contingut destacat de visionat
  - Integració amb dades del HomeProvider

#### `UserProfileSummaryCard`

- **Localització**: `widgets/user_profile_summary_card.dart`
- **Propòsit**: Targeta amb resum del perfil d'usuari i estadístiques
- **Funcionalitat**:
  - Informació del perfil de l'àrbitre
  - Estadístiques i dades de rendiment

## Ús

```dart
import 'package:el_visionat/features/home/index.dart';

// Accés a la pàgina principal
const HomePage()

// Accés al proveïdor d'estat
HomeProvider()

// Accés a widgets individuals
const FeaturedVisioningSection()
const UserProfileSummaryCard()
```

## Dependències

- **Flutter**: Framework principal
- **Provider**: Gestió d'estat
- **Material Design**: Components UI
- **Theme**: Tema global de l'aplicació
- **Voting Feature**: Integració amb sistema de votacions

## Integració

Aquest feature s'integra amb:

- **Auth Feature**: Autenticació d'usuaris
- **Voting Feature**: Sistema de votacions
- **Navigation**: Sistema de navegació global
- **Theme**: Sistema de temes de l'aplicació
