🪵 branching_strategy.md — Estratègia de Branching (GIT)

Projecte EL VISIONAT — Estàndard Professional

Aquest document defineix com s’ha de treballar amb Git en el projecte, incloent:

Tipus de branques

Flux de treball (workflow)

Normes de creació de branques

Estratègia de merges

Estàndards de review

Versionament

És un document essencial perquè Copilot generi sempre el codi dins el context de la branca correcta i segueixi el flux professional.

1. Objectius de l’estratègia

Evitar conflictes

Treballar amb seguretat

Mantindre el codi net i estable

Facilitar revisions i auditories

Permetre desplegaments segurs

Afavorir un flux de treball ordenat i escalable

2. Estructura de Branques

📌 Branques principals

Branca Ús Normes
main Codi 100% estable i llest per producció No s’hi commiteja directament
develop (opcional) Pre-producció, testing integrat S’hi fa merge de features

⚠️ Com que el projecte és individual, podem treballar directament amb main, però amb disciplina estricta.

📌 Branques secundàries

Tipus Prefix Exemple
Feature feature/ feature/visionat-backend
Fix fix/ fix/login-error
Refactor refactor/ refactor/navigation-logic
Docs docs/ docs/architecture-update
Experiment experiment/ experiment/isar-cache 3. Regles per Crear Branques

Sempre crear branques curtes, clares i descriptives.

✔️ Nom correcte:
feature/visionat-highlights-backend
fix/auth-token-timeout
docs/security-update
refactor/team-data-service

❌ No correcte:
dev1
anna
nou
coses

4. Workflow de Desenvolupament
   🧱 Pas 1 — Crear la branca
   git checkout main
   git pull
   git checkout -b feature/nom-de-la-feature

🛠️ Pas 2 — Desenvolupar la funcionalitat

Commits petits

Missatges clars (seguint commit_conventions.md)

Push freqüent

🧪 Pas 3 — Verificació local

Abans de fer merge:

flutter analyze

flutter test

firebase emulators:start si afecta backend

Compilar en Android Emulator

🔀 Pas 4 — Merge a main

Quan la feature és estable:

git checkout main
git pull
git merge feature/nom-de-la-feature --no-ff

⚠️ Mai fer merge sense revisar el dif.

🧹 Pas 5 — Eliminar la branca
git branch -d feature/nom-de-la-feature

5. Estàndards per a Pull Requests (si n’hi ha)

Tot i que sigui un projecte individual, es segueix disciplina professional:

Descripció clara del que s’ha fet

Captures de pantalla si afecta UI

Enllaços a docs afectats

Check de “Checklist” obligatori:

[ ] Codi net sense warnings
[ ] Flutter analyze OK
[ ] Tests locals passats
[ ] Backend validat si afecta
[ ] Revisat que segueix arquitectura feature-first

6. Gestió de Versions

En aquest projecte s'utilitza Semantic Versioning:

MAJOR.MINOR.PATCH

MAJOR

Trencament d’arquitectura (per ex: migració completa a Riverpod)

MINOR

Nova funcionalitat completa:

backend highlights

anàlisi col·lectiva amb Firestore

nou sistema de perfils

PATCH

Correccions:

bug en votacions

error de navegació

UI fixes

7. Bones Pràctiques Obligatòries
   ✔️ Sempre treballar en una branca
   ✔️ Commits petits i freqüents
   ✔️ Mai pujar codi sense compilar
   ✔️ Commits en anglès (recomanat)
   ✔️ Claus API → mai al repo
   ✔️ Revisar que la branca està actualitzada abans de merge
   git pull origin main

8. Flux Resumit
   main → crear feature/xxx → desenvolupar → commits → test local → merge a main
