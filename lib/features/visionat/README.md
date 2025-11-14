# Visionat Feature

Esta feature conté tota la funcionalitat relacionada amb el visionatge de partits d'arbitratge.

## Estructura

```
lib/features/visionat/
├── index.dart              # Exportacions públiques de la feature
├── models/                 # Models de dades específics de visionat
│   ├── highlight_entry.dart
│   ├── collective_comment.dart
│   └── match_models.dart
├── pages/                  # Pàgines principals
│   └── visionat_match_page.dart
├── widgets/                # Components UI reutilitzables
│   ├── analysis_section_card.dart
│   ├── add_highlight_card.dart
│   ├── collective_analysis_modal.dart
│   ├── highlights_timeline.dart
│   ├── match_details_card.dart
│   ├── match_header.dart
│   ├── match_video_section.dart
│   ├── referee_comment_card.dart
│   ├── tag_filter_bar.dart
│   └── tag_selector/
│       ├── index.dart
│       ├── tag_definitions.dart
│       └── tag_selector.dart
├── services/               # Serveis de backend (preparat per futures integracions)
└── providers/              # Gestors d'estat (preparat per futures integracions)
```

## Ús

Per importar qualsevol component de la feature:

```dart
import 'package:el_visionat/features/visionat/index.dart';
```

## Funcionalitats

- **Visionatge de partits**: Pantalla principal per visualitzar partits
- **Sistema de highlights**: Afegir i filtrar moments destacats
- **Anàlisi personal**: Notes i comentaris individuals
- **Anàlisi col·lectiva**: Sistema de comentaris comunitaris
- **Sistema de tags**: 96+ tags professionals FIBA organitzats per categories
- **Responsive design**: Suport per mòbil i desktop

## Futura Integració Backend

La feature està preparada per integrar:

- `services/visionat_service.dart` - CRUD operations amb Firestore
- `providers/visionat_provider.dart` - Gestió d'estat reactiva
- Real-time updates per highlights i comentaris col·lectius
