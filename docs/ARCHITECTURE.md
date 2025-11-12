# Arquitectura del projecte

Aquest document descriu, de manera succinta, els components principals de l'aplicació i el flux de dades entre ells.

## Diagrama ASCII (visió d'alta nivell)

```
               +-----------------+       +------------------+
               |   Frontend      |       |  Cloudflare DNS  |
               |  (Flutter App)  |       |  (domini / TLS)  |
               +--------+--------+       +------------------+
                        |                             |
                        | HTTPS / Callable            |
                        v                             v
               +--------+--------+            (domini públic)
               | Firebase Hosting |  (opcional) / CDN
               +--------+--------+
                        |
               +--------+--------+
               |   Firebase      |
               |   (Auth, Firestore, Functions)
               +---+-----+-------+
                   |     |
                   |     +--> Cloud Functions (TS) --+--> Resend (email)
                   |                                |
                   +--> Firestore (registration_requests, users, etc.)

Local development uses the Firebase Emulator Suite to run Auth, Firestore and Functions locally.
```

## Components i responsabilitats

- **Frontend (Flutter)**

  - Gestió UI, flux de registre, i crides a les Cloud Functions amb `httpsCallable`.
  - Persistència local per a dades estàtiques amb Isar.

- **Cloud Functions (TypeScript)**

  - Lògica de validació i procés de registre, verificacions transaccionals a Firestore i integració amb serveis externs (Resend).

- **Firestore**

  - Emmagatzema `registration_requests`, reserves d'email (`emails/`), perfils d'usuari i altres col·leccions.

- **Resend**
  - Enviament d'emails (activation tokens, benvinguda).

## Flux de registre (detallat)

1. Client envia `lookupLicense(licenseId)` → Functions comprova la llicència.
2. Client envia `requestRegistration(licenseId,email)` → Functions crea `registration_requests` i envia email amb `activationToken`.
3. Administrador aprova la sol·licitud i l'usuari rep el token.
4. Client valida token amb `validateActivationToken` → si OK, pot cridar `completeRegistration` per crear l'usuari i contrasenya.

---
