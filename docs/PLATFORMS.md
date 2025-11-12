# Plataformes i serveis externs

Aquest document recull les plataformes externes i serveis que utilitza el projecte i com s'integren en el flux de desenvolupament i producció.

## Serveis externs

- **Cloudflare** — https://dash.cloudflare.com/

  - Gestió de dominis, DNS i certificats TLS per al domini públic del projecte.

- **Resend** — https://resend.com/

  - Servei d'enviament d'emails utilitzat per connexions HTTP per enviar missatges de benvinguda i codis d'activació des de les Cloud Functions.

- **Google Cloud Console** — https://console.cloud.google.com/

  - Consola general de Google Cloud per:
    - Configurar comptes de facturació i permisos (IAM)
    - Gestionar APIs i credencials
    - Visualitzar logs i alertes amb Cloud Monitoring / Logging

- **Firebase Console** — https://console.firebase.google.com/
  - Panell per administrar l'instància Firebase del projecte:
    - Configuració d'Autenticació, Firestore, Storage i Functions
    - Gestió d'indexos i regles per a Firestore
    - Desplegament i inspecció de funcions

## Firebase Emulator Suite

Per al desenvolupament local utilitzem la Firebase Emulator Suite per emular Auth, Firestore, Functions i altres serveis.

Punts clau:

- Iniciar els emuladors:

```powershell
firebase emulators:start
```

- Ports per defecte (poden variar segons `firebase.json`):

  - Functions: 5001
  - Firestore: 8088 (o 8185 en configuracions locals específiques)
  - Auth: 9198 / 9199

- Notes d'ús:
  - En Android emulator, per accedir al host local cal usar `10.0.2.2`; en iOS simulator o web/desktop usar `127.0.0.1`.
  - Si necessites logs detallats de Functions a local, activa:

```text
FUNCTIONS_VERBOSE=true
```

## On trobar configuracions

- `firebase.json` — configuració d'emuladors i ports.
- `.env.local` — variables d'entorn locals (opcional) per a la màquina de desenvolupament.

---

Si cal que afegeixi instruccions addicionals (per exemple, com sincronitzar dades d'exemple a l'emulador), ho puc fer aquí.
