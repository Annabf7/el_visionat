📘 project_conventions.md — Estàndards del Projecte EL VISIONAT

Aquest document estableix les normes generals que tot desenvolupador (i Copilot) han de seguir en aquest projecte.
És un document global, aplicable a totes les carpetes i a tot el codi.

1. Principis del projecte

Feature-First Architecture
Tota funcionalitat viu dins /lib/features/<feature_name>/.

Separation of Concerns
Models → Services → Providers → UI
Mai barrejar responsabilitats.

Fonts de veritat

architecture.md → arquitectura

firebase_patterns.md → patrons Firebase

ui_ux_guidelines.md → disseny

security_standards.md → seguretat

Professionalisme
Codi net, comentaris útils, funcions petites.

2. Estàndards d’estil de codi
   2.1 Noms

Classes → PascalCase

Variables i mètodes → camelCase

Carpetes → snake_case

Fitxers → snake_case

Constants → SCREAMING_SNAKE_CASE

2.2 Llargada màxima de línia
100 caràcters

2.3 Comentaris

Explicar per què, no què fa el codi

Documentar decisions arquitectòniques importants

Comentaris breus en parts crítiques (async, transaccions, errors)

2.4 Imports

No imports absoluts

No imports encreuats entre features

Sempre:

import '../../services/...';
import '../models/...';

3. Estàndards d’arquitectura
   3.1 Estructura bàsica de cada feature
   feature/
   models/
   services/
   providers/
   widgets/
   pages/
   utils/
   index.dart
   README.md

3.2 Normes estrictes

Els models no contenen lògica

Els services no contenen estat

Els providers no fan crides directament a Firebase
→ sempre a través dels services

Els widgets no poden fer accions de negoci

4. Normes de Flutter

No setState en pàgines gestionades per Provider

Widgets reutilitzables → a widgets/

Mantenir layout responsiu

Evitar mètodes de més de 40 línies

Evitar classes > 300 línies

Sempre dividir UI en petits widgets

5. Normes de Firebase

Totes les crides s’han de realitzar via services

Prohibició d’accedir a Firebase directament des de la UI

Cloud Functions només envien dades validades

El client mai genera camp “role”, “approved”, etc.

Sempre validar errors crítics:

falta de permisos

timeouts

problemes de connexió

dades nulles

6. Control d’errors
   6.1 Normes

Tota funció async ha de capturar errors

Cap error es pot imprimir en clar

Mostrar feedback a l’usuari quan calgui (SnackBar / dialog)

6.2 Format d’errors

Errors generats:

AuthException(code, message)
FirestoreException(reason, suggestion)

7. Estàndards de Documentació

Cada feature ha d’incloure:

README.md amb:

Flux de dades

Models

Services

Providers

Dependències internes

TODOs pendents

8. Normes per Copilot

Copilot ha de seguir:

No crear carpetes fora de /features o /core

No generar codi duplicat

No crear models sense copyWith

No fer crides Firebase directament des de la UI

Inferir automàticament ubicació correcta segons el patró

Respectar estil del projecte

Respectar arquitectures descrites a architecture.md
