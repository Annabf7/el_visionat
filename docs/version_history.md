# 📝 version_history.md — Historial de Versions del Projecte

Aquest document registra els canvis principals del projecte EL VISIONAT organitzats cronològicament per facilitar el seguiment de l'evolució de l'arquitectura i funcionalitats.

## Versió 2.1.0 — Flux d'Autenticació amb Verificació Segura de Tokens

**Data**: 17-18 novembre 2025  
**Commit**: 4356d20

### 🔐 Canvis d'Autenticació

**Noves funcionalitats:**

- Sistema de gestió d'estat avançat per tokens d'activació
- Diàlegs modals automàtics amb detecció d'estat
- Verificació server-side obligatòria amb Cloud Functions
- Navegació intel·ligent cross-platform (mobile/desktop)

**Variables d'estat noves a `AuthProvider`:**

```dart
bool _isWaitingForToken = false;    // Control automàtic de diàlegs
String? _pendingLicenseId;          // Llicència pendent
String? _pendingEmail;              // Email pendent de verificació

// Mètodes nous
void clearTokenWaitingState();      // Neteja estat token
```

**Funcions Cloud noves:**

- `validateActivationToken` - Verificació segura amb TTL i single-use
- `resendActivationToken` - Reenviar tokens amb regeneració
- `warmFunctions` - Optimització per evitar cold starts d'emulador

### 🛡️ Millores de Seguretat

**Validació atòmica de tokens:**

- TTL de 48 hores amb verificació server-side
- Transaccions Firestore per evitar race conditions
- Tokens single-use amb marca d'utilitzat automàtica
- Double-check pattern per prevenir inconsistències

**UI anti-escapament:**

```dart
PopScope(canPop: false)              // Bloqueja navegació enrere
barrierDismissible: false            // Evita tancar accidental
```

### ⚡ Optimitzacions de Performance

**Cloud Functions:**

- Timeout de 60 segons per evitar `deadline_exceeded`
- Memòria de 256MiB per processament adequat
- Màxim 10 instàncies concurrents per escalabilitat
- Warming function per emulador local

### 📱 Millores d'Experiència d'Usuari

**Detecció automàtica d'estat:**

```dart
// Listener pattern per mostrar diàlegs automàticament
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && authProvider.isWaitingForToken) {
    _showAutoTokenDialog();
  }
});
```

**Consistència multiplataforma:**

- Layout responsiu automàtic (mobile < 900px, desktop >= 900px)
- Mateixa lògica de validació en ambdues plataformes
- Navegació consistent amb `rootNavigator`

### 🎨 Millores de Tema

**Colors corporatius aplicats:**

- Labels amb `AppTheme.grisPistacho` per millor visibilitat
- Botons amb estils consistents del tema corporatiu
- Estats desactivats amb colors adequats per accessibilitat

---

## Versió 2.0.0 — Arquitectura Feature-First Completa

**Data**: Octubre-novembre 2025

### 🏗️ Arquitectura

**Estructura de features implementada:**

```
lib/
├── features/
│   ├── auth/           ✔️ Complet
│   ├── voting/         ✔️ Complet
│   ├── visionat/       ✔️ Complet
│   ├── home/           ✔️ Complet
│   └── teams/          🔄 En procés
├── core/
│   ├── theme/          ✔️ AppTheme corporatiu
│   ├── services/       ✔️ Isar + Firebase
│   └── widgets/        ✔️ Components globals
```

**Patrons d'estat:**

- Provider + ChangeNotifier per gestió reactiva
- Services per lògica de negoci
- Models immutables
- Separació clara UI/lògica

### 🔥 Backend Firebase

**Cloud Functions:**

- Sistema complet d'autenticació amb verificació manual
- Gestió de votacions en temps real
- Email notifications via Resend
- Triggers automàtics per actualitzacions d'estat

**Firestore:**

- Col·leccions normalitzades
- Regles de seguretat granulars
- Transaccions atòmiques per consistència
- Emulador complet per desenvolupament

### 📊 Funcionalitats Principals

**Sistema de Votacions:**

- Votació per jornada amb validació
- Comptadors en temps real
- Historial d'usuari persistent
- Prevenció de múltiples vots

**Anàlisi Visionat:**

- Timeline d'highlights interactiva
- Comentaris col·lectius en temps real
- Anàlisi personal amb persistència local
- Navegació temporal avançada

---

## Versió 1.0.0 — Base del Projecte

**Data**: Agost-setembre 2025

### 🎯 Concepte Inicial

**Objectiu:**
Aplicació de visionat d'arbitratge per la Federació Catalana de Bàsquet amb sistema de votacions i anàlisi col·laboratiu.

**Tecnologies base:**

- Flutter multiplataforma
- Firebase Backend-as-a-Service
- Isar per persistència local
- Material Design 3

**Funcionalitats MVP:**

- Autenticació bàsica
- Visualització de partits
- Sistema de comentaris
- Dashboard informatiu

---

## Pròximes Versions Planificades

### Versió 2.2.0 — Gestió Avançada d'Equips

**Previst**: Desembre 2025

**Funcionalitats:**

- CRUD complet d'equips
- Gestió de plantilles i jugadors
- Estadístiques d'equip
- Comparatives històriques

### Versió 2.3.0 — Analytics i Reporting

**Previst**: Gener 2026

**Funcionalitats:**

- Dashboard d'analytics avançat
- Exportació de reports PDF
- Mètriques de participació
- Insights automàtics

### Versió 3.0.0 — Multiplataforma Nativa

**Previst**: Marzo 2026

**Funcionalitats:**

- Apps natives iOS/Android
- Sincronització offline robusta
- Notificacions push
- Widget d'escriptori

---

## Metodologia de Versions

### Numeració Semàntica

**MAJOR.MINOR.PATCH**

- **MAJOR**: Canvis d'arquitectura o breaking changes
- **MINOR**: Noves funcionalitats backwards-compatible
- **PATCH**: Bug fixes i millores menors

### Criteris de Release

**Major (X.0.0):**

- Refactoring complet d'arquitectura
- Canvis en APIs públiques
- Migracions de base de dades

**Minor (X.Y.0):**

- Noves features completes
- Millores significatives d'UX/UI
- Optimitzacions de performance

**Patch (X.Y.Z):**

- Bug fixes
- Ajustos de tema/colors
- Optimitzacions menors

---

**Mantingut per**: Equip de desenvolupament EL VISIONAT  
**Darrera actualització**: 18 novembre 2025  
**Referència**: [Documentació tècnica completa](/docs/)
