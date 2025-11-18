📘 firebase_patterns.md — Estàndards Firebase

Aquest document defineix tots els patrons, normes i bones pràctiques per treballar amb Firebase Auth, Firestore, Cloud Functions i Firebase Emulators dins del projecte EL VISIONAT.

És un document crític: Copilot el farà servir per entendre com han de funcionar tots els serveis del backend des del frontend.

1. Principis generals

Mai accedir directament a Firestore des del widget

Només els services tenen accés a Firebase

Providers serveixen per estat, no per lògica

Atomicitat sempre (transactions o batch)

Emuladors obligatoris en desenvolupament

Escalabilitat: col·leccions normalitzades, sense nested complexity

Seguretat: cada escriptura validada per regles i/o Cloud Functions

2. Regla Fonamental del Projecte

🔥 “Cap lògica crítica es fa al client.”

Sempre:

Flutter → crida service

Service → crida Cloud Function (si cal)

Cloud Function → valida, escriu, controla seguretat

Firestore → actualitza

UI → només llegeix en temps real

Això garanteix:

consistència

seguretat

escalabilitat

prevenció de manipulacions

3. Firebase Auth — Patrons
   3.1 Mai exposar dades sensibles al client

Tot control de registre passa per Cloud Functions:

lookupLicense

requestRegistration

validateActivationToken

completeRegistration

checkRegistrationStatus

resendActivationToken

warmFunctions

### 3.1.1 Patrons Avançats de Cloud Functions

**Verificació Segura de Tokens (`validateActivationToken`):**

```typescript
// Configuració optimitzada per robustesa i escalabilitat
export const validateActivationTokenCallable = functionsV1.https.onCall(
  {
    timeoutSeconds: 60, // Evita deadline_exceeded
    memory: "256MiB", // Memòria adequada per processament
    maxInstances: 10, // Gestió de peticions concurrents
  },
  async (data, context) => {
    await validateActivationTokenCore(email, token);
  }
);
```

**Optimització d'Emulador (`warmFunctions`):**

```typescript
// functions/src/utils/warm_functions.ts - Prevé cold starts
export const warmFunctions = onCall(
  {
    timeoutSeconds: 10,
    memory: "128MiB",
  },
  async (request) => {
    return { success: true, message: "Functions emulator warmed!" };
  }
);
```

3.2 Maneig d'estat

El AuthProvider controla:

login/logout

flux de registre

loading i errors

estàticament via authStateChanges

3.3 Reglas

El client mai crea usuaris directament via createUserWithEmailAndPassword.

Tot passa per la Cloud Function completeRegistration.

4. Firestore — Arquitectura i Patrons
   4.1 Normalització de col·leccions (standard)

Firestore no es pot utilitzar com una base SQL.

Patró oficial del projecte:

users/{uid}
teams/{teamId}
matches/{matchId}
votes/{jornadaId_userId}
vote_counts/{jornada_matchId}
highlights/{matchId}/{highlightId}
collective_comments/{matchId}/{commentId}
analysis_personal/{userId_matchId}

4.2 Regles de disseny

IDs predictibles → millor queries

Estructures planes → millor performance

Documents petits → evitar límits de firestore (1MB)

4.3 Denormalització controlada

Només quan:

estalvia queries costoses

és llegit 100x més que escrit

Exemple correcte: vote_counts (contador agregat)

5. Cloud Functions — Patrons
   5.1 Estructura Enterprise
   functions/src/
   auth/
   votes/
   email/
   models/
   types/
   utils/
   index.ts

5.2 Tipus de Functions
Callable (flutter ←→ server)

lookupLicense

requestRegistration

completeRegistration

checkRegistrationStatus

resendActivationToken

validateActivationToken

Trigger-based

onVoteWrite → recalcula vote_counts

(futur) onHighlightCreate → analítica o moderació

(futur) onCommentCreate → notificació o moderació

5.3 Patrons d’Implementació

Always validate input (schema)

Atomic transactions quan hi ha increments

Never trust client

Never expose Firestore schema to Flutter

6. Transaccions i Atomicitat

Sempre que hi hagi:

increments/decrements

comptadors

canvis relacionats entre 2 col·leccions

→ utilitzar runTransaction.

Patró:

await db.runTransaction(async (tx) => {
const snap = await tx.get(ref);
const prev = snap.data()?.count ?? 0;
tx.update(ref, { count: prev + 1 });
});

Mai fer:

await ref.update({ count: count + 1 });

7. Firebase Emulators — Estàndards
   7.1 Regla d’or

⚠️ Tot desenvolupament es fa contra emuladors.

7.2 Hosts per plataforma

Android emulator → 10.0.2.2

iOS simulator → 127.0.0.1

Web/desktop → localhost o 127.0.0.1

7.3 Configuració al Flutter

Utilitzada ja dins els services:

FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8088);
FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9199);

7.4 Avantatges

debugging complet

sense cost

sense límit d’operacions

logs detallats de Firebase Functions

permet testing local end-to-end

8. Errors i Logging
   8.1 Al client (Flutter)

Mostres:

missatge humà

error tancat (no detalls interns)

Exemple:

❌ Incorrecte:

FirebaseException: invalid-argument

✅ Correcte:

No hem pogut verificar la llicència. Si us plau, revisa el número.

8.2 Al servidor (Functions)

logs clars

mai exposar informació personal

errors tipificats

9. Seguretat — Firestore Rules

Principis:

Usuari només pot escriure els seus propis documents

Validar tipus abans d’escriure

Tot el que és “social” (comentaris) → moderació possible

Administradors → rol via custom claims

10. Estratègies d’escalabilitat
    10.1 Features independents

auth/, voting/, visionat/, teams/ → desacoblats

10.2 Cloud Functions petites i modulars

Millor 10 funcions petites que 1 de gran.

10.3 Firestore indexat correctament

Totes les queries complexes han d’estar indexades.

10.4 Preparat per web-scale

Tot segueix els patrons recomanats per Google / FBL
