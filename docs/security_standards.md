✅ security_standards.md — Estàndards de Seguretat del Projecte

Aquest document defineix les polítiques de seguretat, normes de protecció de dades, regles de Firestore, patrons d’accés, i els principis d’auditoria i control aplicats al projecte EL VISIONAT.

És una referència obligatòria per qualsevol mòdul del projecte que interactuï amb dades sensibles.

1. Principis Generals de Seguretat
   1.1 Política zero-trust

Tot accés a dades s’ha de considerar no fiable fins que:

S’ha confirmat la identitat (Firebase Auth)

S’ha confirmat el permís (Firestore Security Rules)

S’ha validat la lògica (Cloud Functions)

S’ha registrat l’operació (logs)

1.2 Mínim privilegi (Principi least-privilege)

Cap usuari pot tenir més permissos dels estrictament necessaris per fer la seva acció.

1.3 Validació obligatòria en 2 capes

Frontend → validació UX (no suficient)

Backend (Cloud Functions) → validació obligatòria

2. Estàndards d’Autenticació
   2.1 Firebase Auth — Únic mètode permès

Email + password (creat després de validar la llicència).

No es permeten registres automàtics externs.

No es permet modificar l’email un cop creat.

2.2 Sessió d’usuari

Ha de passar sempre per AuthProvider i RequireAuth.

No s’han d’exposar UID ni dades sensibles a logs.

2.3 Tokens i activacions — Sistema de Verificació Segura

**Arquitectura de seguretat dels tokens:**

TTL obligatori: 48 hores màxim per token d'activació.

Validació atòmica: Cloud Function `validateActivationToken` amb transaccions Firestore.

Single-use enforcement: Tokens marcats com utilitzats després de validació exitosa.

Server-side authority: Cap validació crítica es fa al client.

**Propietats de seguretat:**

```typescript
// Validació amb double-check pattern per evitar race conditions
await db.runTransaction(async (tx) => {
  const snap = await tx.get(docRef);
  const cur = snap.data();
  if (cur.activationTokenUsed === true) {
    throw new HttpsError("permission-denied", "Token ja utilitzat");
  }
  tx.update(docRef, {
    activationTokenUsed: true,
    activationTokenUsedAt: FieldValue.serverTimestamp(),
  });
});
```

**Col·leccions de seguretat:**

- `/registration_requests/{id}` → tokens amb TTL i estat d'ús
- `/emails/{email}` → reserva d'unicitat d'email
- Logs de validació per auditoria

3. Estàndards de Firestore
   3.1 Estructura principal protegida

Col·leccions i permisos:

users/ → accessibles només pel propi usuari
votes/ → accessible només pel propi usuari
vote_counts/ → només lectura
highlights/ → lectura global, escriptura limitada
collective_comments/ → lectura global, escriptura autenticada
analysis_personal/ → només el propi usuari
teams/ → lectura global
matches/ → lectura global

3.2 Regles generals

Cap camp pot ser escrit sense validar tipus i valors.

Cap document pot ser sobrescrit completament (update > set).

Camps obligatoris sempre validats.

4. Regles Firestore (Estàndard del Projecte)
   4.1 Escriptura de vots (votes/)

✔️ Permès:

L’usuari autenticat només pot escriure el seu vot de la jornada.

❌ No permès:

Escriure vots d’altres usuaris

Crear múltiples vots a la mateixa jornada

Modificar vote_counts directament

Regla:

allow write: if request.auth != null
&& request.auth.uid == request.resource.data.userId;

4.2 Comptadors de votacions (vote_counts/)

✔️ Permès: Només lectura pública
❌ No permès: Cap escriptura des del client
→ Es gestionen exclusivament per Cloud Functions.

4.3 Highlights (highlights/)

✔️ Lectura pública
✔️ Escriptura només si l’usuari està autenticat
✔️ Validació de camps: timestamp, categoria, tag

❌ Cap delete des del client
→ Eliminacions només via admin.

4.4 Comentaris col·lectius (collective_comments/)

✔️ Lectura pública
✔️ Escriptura autenticada
✔️ Possibilitat d’anonimat (anonymous = true)
✔️ Validació estricta de longitud: 1–2000 chars

❌ Modificar comentaris d’altres usuaris
❌ Camp userId falsificat

4.5 Anàlisi personal (analysis_personal/)

✔️ Accés exclusiu del propi usuari
✔️ Escriptures limitades a 1 document per partit

Regla:

allow read, write: if request.auth.uid == resource.data.userId;

5. Estàndards Cloud Functions
   5.1 Validació obligatòria

TOTES les funcions han de:

Validar tots els paràmetres rebuts

Validar identitat del request.auth

Validar existència de la llicència

Validar duplicats (emails, registres)

5.2 Timeouts i memòria

Per evitar errors:

Timeout recomanat: 30–60s

Memòria: 256MB o 512MB (segons càrrega)

5.3 Logs

Cada operació crítica ha de fer:

Log d’entrada

Log d’error

Log d’èxit

5.4 Errors humans

Errors que arriben al client han de ser textuals i útils.

Incorrecte:

“INTERNAL_ERROR”

Correcte:

“No hem pogut validar la llicència. Revisa que el número sigui correcte.”

6. Estàndards IAM & Secrets
   6.1 IAM

Cap compte de servei té permisos més amplis dels necessaris

Cloud Functions només poden accedir a Firestore i Resend

6.2 Secret Manager

Tots els secrets van dins:

/projects/.../secrets/resend_api_key

/projects/.../secrets/visionat_admins

No es permet:

Cap secret en codi

Cap secret en GitHub

Cap secret en .env.local si es puja accidentalment

7. Protecció contra Abusos
   7.1 Rate-Limiting (recomanat)

3 intents de registre / hora

5 intents d’activació / hora

1 vot per jornada

7.2 Moderació de continguts

Recomanat aplicar:

Bad-words filter

Cloud Function trigger (onCreate comentari col·lectiu)

8. Escalabilitat i Resiliència

Dades crítiques sempre normalitzades

Cloud Functions idempotents

Escriptures atomitzades

Validació de formats JSON al client i servidor
