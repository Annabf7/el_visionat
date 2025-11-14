📘 architecture.md — Arquitectura del Sistema EL VISIONAT
Document d’Arquitectura (versió per desenvolupadors + Copilot)

1. Objectiu del document

Aquest document defineix l’arquitectura global del projecte EL VISIONAT.
És la font de veritat (Source of Truth) per:

estructuració de carpetes

patrons d’arquitectura

fluxos de dades

definició de features

patrons de Firebase

models i estàndards globals

criteris d’escalabilitat i seguretat

Tots els desenvolupadors (i Copilot) han de seguir aquest document.

2. Arquitectura General del Sistema

Representació d’alta nivell:

               ┌────────────────────────────┐
               │        Flutter App          │
               │   (Android · iOS · Web)     │
               └──────────────┬──────────────┘
                              │
                       HTTPS / JSON
                              │
               ┌──────────────▼──────────────┐
               │        Firebase Backend      │
               │ Auth · Firestore · Functions │
               └───────────┬───────┬─────────┘
                           │       │
                           │       └──────────┐
                           │                  │
               ┌───────────▼────────┐   ┌────▼───────────┐
               │   Cloud Functions   │   │   Firestore DB │
               │     (TypeScript)    │   │ (Normalitzat)  │
               └───────────┬────────┘   └────────────────┘
                           │
               ┌───────────▼─────────┐
               │     APIs externes    │
               │    (Resend – email)  │
               └──────────────────────┘

3. Arquitectura Frontend (Flutter)
   3.1 Patró Principal – Feature First Architecture

Estructura base de cada feature:

feature_name/
├── models/
├── services/
├── providers/
├── pages/
├── widgets/
├── utils/
├── index.dart
└── README.md

Features del projecte
Feature Estat Descripció
auth/ ✔️ Complet Registre, login i flux de llicència
voting/ ✔️ Complet Sistema de votacions en temps real
visionat/ ✔️ Complet Anàlisi del partit, highlights, comentaris
home/ ✔️ Complet Dashboard principal
teams/ 🔄 En procés Models i serveis d’equips
core/ ⏳ Pròxim Infraestructura global (tema, navegació, Isar, etc.)
3.2 Patrons d'Estat

S'utilitza Provider + ChangeNotifier:

AuthProvider → estat d’autenticació

VoteProvider → votació i temps real

NavigationProvider → menú i navegació

VisionatState → estat intern de visionat (local)

HomeProvider → dades del dashboard

Normes:

Els providers NO fan lògica de negoci

La lògica sempre va als services

Els models són immutables

Els widgets no contenen lògica, només UI

3.3 Flux de dades al Frontend
UI Widgets
↓
Providers (ChangeNotifier)
↓
Services (operacions pures)
↓
Firebase (Auth · Firestore · Functions)
↘
Isar (persistència local)

4. Arquitectura Backend (Firebase Functions)
   4.1 Estructura
   functions/
   ├── src/
   │ ├── auth/
   │ ├── votes/
   │ ├── email/
   │ ├── models/
   │ ├── types/
   │ └── index.ts
   ├── package.json
   ├── tsconfig.json
   └── ...

4.2 Tipus de Functions
Callable Functions (httpsCallable)

lookupLicense

requestRegistration

completeRegistration

validateActivationToken

resendActivationToken

checkRegistrationStatus

Trigger Functions

onVoteWrite → manté vote_counts actualitzat

Futures ampliacions:

onHighlightCreate

onCollectiveCommentCreate

5. Esquema de Firestore (normalitzat)
   Col·leccions principals
   users/{uid}
   teams/{teamId}
   matches/{matchId}

votes/{jornadaId_userId}
vote_counts/{jornada_matchId}

highlights/{matchId}/{highlightId}
collective_comments/{matchId}/{commentId}
analysis_personal/{userId_matchId}

registration_requests/{id}
approved_registrations/{email}
activation_tokens/{token}
emails/{email}

6. Fluxos de Dades Complets
   6.1 Flux de Registre

lookupLicense

requestRegistration

admin approval

validateActivationToken

completeRegistration

FirebaseAuth login

redirect /home

6.2 Flux de Votació

Carregar JSON local de jornada

Mostrar partida

L'usuari vota

S’escriu document a /votes

Cloud Function recalcula /vote_counts

UI s’actualitza en temps real

6.3 Flux Visionat

Carrega detalls del partit

Mostra Highlights timeline

Comentaris col·lectius (Firestore)

Anàlisi personal (local o Firestore)

7. Seguretat i Regles Firestore

Normes principals:

Cada usuari pot votar 1 vegada per jornada

Dades personals només accessibles per l’usuari

Comentaris col·lectius controlats per regles

Admin amb rols específics per processos de registre

Validacions crítiques es fan al backend (Cloud Functions)

8. Estratègia d’Escalabilitat

Mòduls independents (feature-first)

Firebase Functions atomitzades

Firestore normalitzat

Emulador complet per desenvolupament local

Suport multi-plataforma

9. Notes per Copilot

Sempre respectar l’arquitectura feature-first

Sempre col·locar codi segons models → services → providers → UI

No barrejar lògica entre features

No crear carpetes fora de /features o /core

Respectar noms, patrons i organització
