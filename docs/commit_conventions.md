📝 commit_conventions.md — Estàndards de Commits (Git)

Projecte EL VISIONAT — Format Professional

Aquest document defineix l'estàndard oficial per escriure commits al projecte.
Copilot i qualsevol desenvolupador han de seguir aquestes normes sempre.

1. Objectius

Garantir un historial net i fàcil de llegir

Facilitar debugging i revert de versions

Unificar el format dels commits

Permetre automatitzar changelogs futurs

Donar a Copilot instruccions clares de com escriure commits

2. Format General del Commit
   <tipus>: <resum curt i clar>

<punts clau explicatius>

<detalls opcionals>

✔️ Regles generals:

Màxim 72 caràcters al títol

En imperatiu: “Add”, “Fix”, “Refactor”, “Create”

Sense majúscula després dels dos punts

Sense punt final al títol

En català o en anglès → però a tot el projecte en català

3. Tipus de Commits (oficials)
   🟦 feat

Nova funcionalitat completa

feat: afegeix gestor de highlights al visionat

🟩 fix

Correcció d’errors

fix: resol error de renderitzat en voting_card

🟧 refactor

Canvis interns sense modificar comportament

refactor: neteja lògica de match_details_card

🟪 style

Canvis visuals i format

style: millora espaiat i tipografia del modal col·lectiu

🟨 docs

Canvis a documentació

docs: afegeix guideline de Flutter a docs/flutter_guidelines.md

🟫 chore

Tasques de manteniment (no funcionals)

chore: actualitza dependències i fixa warnings

⬜ test

Afegir o modificar tests

test: afegeix proves unitàries al vote_service

🟥 build

Canvis en el sistema de build o configuració

build: ajusta fitxer firebase.json per a hosting

4. Format del Missatge (detallat)
   ✔️ Títol (obligatori)

Directe, curt, imperatiu:

feat: integra highlights a Firestore amb listeners en temps real

✔️ Cos (opcional però recomanat)

Cada punt ha d’explicar la lògica important:

- afegeix servei highlight_service amb CRUD complet
- incorpora listener per updates en temps real
- prepara estructures per migració al backend

✔️ Notes opcionals

Per deixar clar per què s’han fet canvis:

NOTA: es prepara la integració amb analysis_personal i comments col·lectius

5. Regles d’Or (OBLIGATÒRIES)
   ✔️ 1. Un commit per funcionalitat

Evita “commit gegants” barrejant coses.

✔️ 2. No commitejar codi amb errors

Sempre:

flutter analyze
flutter run

✔️ 3. No commitejar claus, secrets ni fitxers .env

El repositori ha d’estar net de secrets.

✔️ 4. Commits freqüents

No esperar a fer-ho al final d’una feature.

✔️ 5. Missatges explícits

El missatge ha d’explicar què i per què.

6. Plantilles preparades per Copilot
   🟦 Feature
   feat: <descripció breu>

- <punt clau 1>
- <punt clau 2>
- <punt clau 3>

🟩 Fix
fix: <error corregit>

- causa del problema
- solució aplicada
- efectes col·laterals revisats

🟧 Refactor
refactor: <àrea refactoritzada>

- codi simplificat
- lògica reorganitzada

🟪 Style
style: <millora UI UX>

- ajust d’espais
- correcció tipografies

7. Exemples Reals del Projecte
   ✔ Visionat
   feat: integra modal d’anàlisi col·lectiva amb estat local

- crea widget dedicat
- afegeix callback i sincronització
- prepara futur enllaç amb Firestore

✔ Voting
fix: corregeix desincronització de comptadors en vot retransmès

✔ Auth
refactor: millora control d’estats en RegistrationStep

✔ Core
chore: reorganitza serveis globals a lib/core

8. Què NO es pot fer

❌ Commits vagues:

update things
coses noves
arreglo tot

❌ Commits amb 1000 línies sense dividir

❌ Commits sense provar l’app
