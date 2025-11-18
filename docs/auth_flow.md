# 🔐 auth_flow.md — Flux d'Autenticació amb Verificació de Token

Aquest document descriu l'arquitectura completa del sistema d'autenticació segura implementat al projecte EL VISIONAT, incloent la gestió d'estat avançada, verificació de tokens server-side i integració UI/backend robusta.

## 1. Visió General del Sistema

### 1.1 Arquitectura del Flux

L'autenticació segueix un model híbrid que combina:

- **Registre manual**: Verificació de llicència oficial + aprovació manual
- **Verificació segura**: Validació de tokens server-side amb Cloud Functions
- **Gestió d'estat centralitzada**: AuthProvider amb control de flux complet
- **UX progressiva**: Diàlegs automàtics i navegació intel·ligent

### 1.2 Components Principals

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUX D'AUTENTICACIÓ                      │
└─────────────────────────────────────────────────────────────┘

Frontend (Flutter)          Backend (Firebase)          Seguretat
─────────────────────────   ────────────────────────   ─────────────────
AuthProvider                Cloud Functions             Firestore Rules
 ├── isWaitingForToken     ├── validateActivationToken  ├── Email uniqueness
 ├── clearTokenWaitingState├── lookupLicense           ├── Token TTL (48h)
 └── submitRegistrationRequest└── requestRegistration     └── Atomic transactions

LoginPage                  Firestore Collections
 ├── _showAutoTokenDialog  ├── /registration_requests
 ├── PopScope(canPop: false)├── /emails
 └── barrierDismissible: false└── /activation_tokens
```

## 2. Arquitectura d'Estat (AuthProvider)

### 2.1 Variables Clau del Flux de Token

```dart
// Gestió específica del token d'activació
bool _isWaitingForToken = false;          // Indica si s'espera un token
String? _pendingLicenseId;                // ID de llicència pendent
String? _pendingEmail;                    // Email pendent de verificació

// Accessors públics
bool get isWaitingForToken => _isWaitingForToken;
void clearTokenWaitingState() {
  if (_isWaitingForToken) {
    _isWaitingForToken = false;
    notifyListeners();
  }
}
```

### 2.2 Activació Automàtica del Token

**Triggering Logic:**

```dart
// Després de submitRegistrationRequest()
await authService.requestRegistration(
  llissenciaId: _pendingLicenseId!,
  email: email,
);
_pendingEmail = email;
_currentStep = RegistrationStep.requestSent;
_isWaitingForToken = true;  // ACTIVACIÓ AUTOMÀTICA
_setLoading(false);
notifyListeners();
```

**UI Detection:**

```dart
// initState() + listener pattern
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && widget.authProvider.isWaitingForToken) {
    _showAutoTokenDialog();
  }
});

void _onAuthProviderChange() {
  if (mounted && widget.authProvider.isWaitingForToken) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAutoTokenDialog(authProvider);
      }
    });
  }
}
```

## 3. Diàleg Modal Segur

### 3.1 Propietats de Seguretat

```dart
await showDialog<void>(
  context: context,
  barrierDismissible: false,        // No es pot tancar clickant fora
  builder: (context) {
    return PopScope(
      canPop: false,                  // Bloqueja navegació enrere
      child: AlertDialog(
        // Implementació del diàleg...
      ),
    );
  },
);
```

### 3.2 Validació Server-Side

**Client Request:**

```dart
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('validateActivationToken');
final res = await callable.call(<String, dynamic>{
  'email': email,
  'token': token,
});
```

**Backend Validation (Cloud Function):**

```typescript
async function validateActivationTokenCore(email: string, token: string) {
  // 1. Query amb condicions atòmiques
  const q = await db
    .collection("registration_requests")
    .where("email", "==", email)
    .where("activationToken", "==", token)
    .where("activationTokenUsed", "==", false)
    .limit(1)
    .get();

  // 2. Verificació TTL (48 hores)
  const createdMs = createdAt.toDate().getTime();
  const ttlMs = 48 * 60 * 60 * 1000;
  if (Date.now() - createdMs > ttlMs) {
    throw new HttpsError("permission-denied", "Token caducat");
  }

  // 3. Transacció atòmica per marcar com usat
  await db.runTransaction(async (tx) => {
    tx.update(docRef, {
      activationTokenUsed: true,
      activationTokenUsedAt: FieldValue.serverTimestamp(),
    });
  });
}
```

## 4. Seqüència Completa del Flux

### 4.1 Diagrama de Seqüència

```
Usuari          LoginPage           AuthProvider        Cloud Functions     Firestore
  │                 │                     │                   │               │
  │ 1. Envia email  │                     │                   │               │
  │────────────────>│                     │                   │               │
  │                 │ 2. submitRegistration()                  │               │
  │                 │────────────────────>│                   │               │
  │                 │                     │ 3. requestRegistration            │
  │                 │                     │──────────────────>│               │
  │                 │                     │                   │ 4. Escriu DB  │
  │                 │                     │                   │──────────────>│
  │                 │                     │ 5. _isWaitingForToken = true      │
  │                 │                     │<──────────────────│               │
  │                 │ 6. notifyListeners()│                   │               │
  │                 │<────────────────────│                   │               │
  │ 7. Diàleg automàtic                   │                   │               │
  │<────────────────│                     │                   │               │
  │                 │                     │                   │               │
  │ 8. Introdueix token                   │                   │               │
  │────────────────>│                     │                   │               │
  │                 │ 9. validateActivationToken              │               │
  │                 │─────────────────────────────────────────>│               │
  │                 │                     │                   │ 10. Validació │
  │                 │                     │                   │──────────────>│
  │                 │                     │                   │ 11. Mark used │
  │                 │                     │                   │──────────────>│
  │                 │ 12. clearTokenWaitingState()            │               │
  │                 │────────────────────>│                   │               │
  │ 13. Navegació a /create-password      │                   │               │
  │<────────────────│                     │                   │               │
```

### 4.2 Punts Crítics de Seguretat

1. **Double-Check Pattern**: Verificació atòmica per evitar race conditions
2. **TTL Enforcement**: Tokens expiren automàticament després de 48h
3. **Single-Use Tokens**: Marcats com utilitzats després de validació exitosa
4. **Server-Side Authority**: Cap validació crítica es fa al client

## 5. Gestió d'Errors i Recuperació

### 5.1 Errors de Xarxa

```dart
try {
  final res = await callable.call({'email': email, 'token': token});
  // Procés èxit...
} on FirebaseFunctionsException catch (e) {
  setState(() {
    errorText = e.message ?? 'Error del servidor';
    isLoading = false;
  });
} catch (e) {
  setState(() {
    errorText = 'Error de connexió. Torna-ho a intentar.';
    isLoading = false;
  });
}
```

### 5.2 Gestió d'Estats d'Error

| Error              | Acció Frontend          | Resposta Backend                  |
| ------------------ | ----------------------- | --------------------------------- |
| Token inexistent   | Mostra missatge d'error | `HttpsError('permission-denied')` |
| Token caducat      | Ofereix reenviar        | `HttpsError('permission-denied')` |
| Token ja utilitzat | Mostra missatge d'error | `HttpsError('permission-denied')` |
| Problemes de xarxa | Retry automàtic         | Timeout després 60s               |

## 6. Optimitzacions de Performance

### 6.1 Cloud Functions Warming

```typescript
// functions/src/utils/warm_functions.ts
export const warmFunctions = onCall(
  {
    timeoutSeconds: 10,
    memory: "128MiB",
  },
  async (request) => {
    return {
      success: true,
      message: "Functions emulator is now warm and ready!",
      timestamp: new Date().toISOString(),
    };
  }
);
```

### 6.2 Timeout Configuration

```typescript
// Configuració optimitzada per evitar deadline_exceeded
export const validateActivationTokenCallable = functionsV1.https.onCall(
  {
    timeoutSeconds: 60,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (data, context) => {
    // Implementació...
  }
);
```

## 7. Multiplataforma i Responsivitat

### 7.1 Detecció Automàtica per Plataforma

```dart
// Mobile Layout
if (constraints.maxWidth < 900) {
  return _LoginPageMobile(authProvider: context.read<AuthProvider>());
} else {
  return const _LoginPageDesktop();
}
```

### 7.2 Consistència Cross-Platform

- **Mobile**: Diàleg modal amb `TabController`
- **Desktop**: Diàleg modal amb layout horitzontal
- **Ambdós**: Mateixa lògica de validació i navegació

## 8. Beneficis de l'Arquitectura

### 8.1 Robustesa

- **Gestió d'estat centralitzada**: Un sol punt de veritat per l'autenticació
- **Recuperació automàtica**: Diàlegs es mostren automàticament quan cal
- **Prevenció d'errors**: Validació exhaustiva en totes les capes

### 8.2 Seguretat

- **Zero-trust**: Cap operació crítica es fa sense validació server-side
- **Atomic operations**: Transaccions Firestore prevenen inconsistències
- **Token lifecycle**: Generació, TTL i invalidació completament controlats

### 8.3 Experiència d'Usuari

- **Navegació intel·ligent**: Detecció automàtica d'estat i acció corresponent
- **Feedback visual**: Loading states i errors contextuals
- **Prevenció d'escapament**: Diàlegs crítics no es poden tancar accidentalment

## 9. Consideracions d'Escalabilitat

### 9.1 Gestió de Concurrència

```typescript
// Configuració per multiple instàncies
export const validateActivationToken = onCall(
  {
    maxInstances: 10, // Màxim 10 instàncies concurrents
    memory: "256MiB", // Memòria suficient per processament
    timeoutSeconds: 60, // Timeout generós per xarxes lentes
  },
  async (data, context) => {
    // Implementació optimitzada...
  }
);
```

### 9.2 Monitoring i Observabilitat

```typescript
// Logging estructurat per diagnosi
console.log("[validateActivationToken] Request for email:", email);
if (VERBOSE_LOG) {
  console.log(
    "[validateActivationToken] Token validation details:",
    JSON.stringify({ email, tokenLength: token.length })
  );
}
```

## 10. Guidelines per Desenvolupadors

### 10.1 Extensió del Flux

Per afegir nous passos al flux d'autenticació:

1. **Actualitzar `RegistrationStep` enum**
2. **Afegir variable d'estat a `AuthProvider`**
3. **Implementar lògica de transició**
4. **Crear UI corresponent**
5. **Afegir Cloud Function si cal validació server-side**

### 10.2 Bones Pràctiques

```dart
// ✅ Bon exemple: Capturar navigator abans d'async
final rootNavigator = Navigator.of(context, rootNavigator: true);
try {
  await someAsyncOperation();
  if (!mounted) return;
  rootNavigator.pushReplacementNamed('/next-page');
} catch (e) {
  // Gestió d'error...
}

// ❌ Mal exemple: Usar context després d'async sense capturar
try {
  await someAsyncOperation();
  Navigator.of(context).pushReplacementNamed('/next-page'); // PERILL!
} catch (e) {
  // ...
}
```

---

**Versió del document**: 1.0  
**Darrera actualització**: 18 novembre 2025  
**Autor**: Sistema d'autenticació EL VISIONAT  
**Revisions**: Arquitectura confirmada amb implementació commit 4356d20
