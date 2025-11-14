🇨🇦 1. Objectiu del Document (CAT)

Aquest document descriu totes les plataformes i serveis externs utilitzats pel projecte EL VISIONAT, incloent infraestructura, integracions, protocols i estàndards d’ús. Serveix com a document d’autoritat per a desenvolupadors i per a GitHub Copilot.

✨ Què defineix?

Plataformes principals del projecte

Integració amb Firebase, Cloud Functions, Cloudflare i Resend

Configuració de desenvolupament (emuladors)

Configuració de producció

Regles que Copilot ha de seguir quan genera codi d’integració

🇬🇧 1. Purpose of Document (ENG)

This document defines the platforms and external services used by EL VISIONAT, including infrastructure, integrations, and operational standards. It acts as the single source of truth for developers and GitHub Copilot.

Covers:

Core platform providers

Firebase components

Cloud Functions and external APIs

Development vs production differences

Mandatory integration rules for Copilot

🇨🇦 2. Plataformes Principals (CAT)
Plataforma Rol Notes
Flutter Client UI/UX Android, iOS, Web
Firebase Auth Autenticació Email+Password + Tokens
Firestore Base de dades Normalitzada per features
Firebase Functions Lògica backend TypeScript + callable
Firebase Hosting Hosting frontend Opcional per a web
Cloudflare DNS + TLS Domini + proxy
Resend Emails d’activació Tokens, benvingudes
Google Cloud Console IAM + Logs Control d’accessos
🇬🇧 2. Main Platforms (ENG)
Platform Purpose Notes
Flutter Frontend UI Android · iOS · Web
Firebase Auth Identity layer Email/password + custom token flow
Firestore NoSQL DB Normalized collections
Cloud Functions Backend logic TypeScript · atomic operations
Hosting Web deployment Optional
Cloudflare DNS/TLS Domain management
Resend Transactional emails Activation + welcome
Google Cloud IAM · Logs · Billing Centralized admin
🇨🇦 3. Infraestructura i Topologia (CAT)
Flutter App (Android+iOS+Web)
│ HTTPS / Callable
▼
┌────────────────────────────┐
│ Firebase Hosting (opcional)│
└──────────────┬─────────────┘
▼
┌──────────────────────┐
│ Firebase Functions │
│ TypeScript Back-End │
└───────┬──────────────┘
▼
┌──────────────────────┐
│ Firestore Database │
└───────┬──────────────┘
▼
┌──────────────────────┐
│ External APIs │
│ Resend / Future FCBQ │
└──────────────────────┘

🇬🇧 3. Infrastructure & Topology (ENG)

Same diagram included above.

🇨🇦 4. Integracions Crítiques (CAT)
🔐 Firebase Auth

Login, logout

Flux complet de registre amb token d’activació

Detecta estats: approved/pending/needs_password

🗄️ Firestore

Col·leccions normalitzades segons feature

Indexos requerits

Lectures en temps real per votació i comentaris

⚙️ Cloud Functions

Funcions callable:

lookupLicense

requestRegistration

validateActivationToken

completeRegistration

Funcions trigger:

onVoteWrite (comptadors)

🌐 Cloudflare

Proxy SSL complet

DNS del domini oficial

✉️ Resend

Enviament d’emails d’activació

Plantilles d’email definides

🇬🇧 4. Critical Integrations (ENG)

(Same content as above, English version, Copilot-ready)

🇨🇦 5. Entorns (CAT)
Entorn Backend Frontend Notes
Dev Firebase Emulators Flutter run Utilitza 10.0.2.2 a Android
Prod Firebase Cloud Hosting / APK Variables gestionades per Secret Manager
🇬🇧 5. Environments (ENG)

(Same table translated)

🇨🇦 6. Seguretat i IAM (CAT)

Les Functions només s’executen amb service accounts dedicades

Firestore Rules estrictes per feature

Cap funció retorna dades sensibles

Tokens d’activació expiren

🇬🇧 6. Security & IAM (ENG)

(Same content, English version)

🇨🇦 7. Instruccions per Copilot (CAT)

Copilot HA DE SEGUIR aquestes regles quan genera codi:

Utilitza arquitectures feature-first.

Els services no contenen estat.

Els providers no contenen lògica pesada.

Qualsevol accés a Firebase → via services, no directament des de widgets.

Per a Android emulator → sempre usar 10.0.2.2.

Callable functions sempre via FirebaseFunctions.instance.httpsCallable().

Firestore: un sol CollectionReference per service.

Models sempre immutables (final fields + copyWith).

Zero lògica a widgets. Només UI.

🇬🇧 7. Copilot Instructions (ENG)

(Full English version mirroring the same list)

🇨🇦 8. Annex — Referències del Projecte (CAT)

Architecture.md (document principal)

Security Rules

Firebase Functions index

Cloudflare DNS config
