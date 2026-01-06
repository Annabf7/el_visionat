# Sistema de Votació i Comentaris per Highlights

Sistema complet de reaccions i comentaris arbitrals per jugades destacades en visionats setmanals.

## 📋 Índex

- [Visió General](#visió-general)
- [Flux del Sistema](#flux-del-sistema)
- [Components Principals](#components-principals)
- [Jerarquia d'Àrbitres](#jerarquia-dàrbitres)
- [Tipus de Reaccions](#tipus-de-reaccions)
- [Estats de Highlights](#estats-de-highlights)
- [Cloud Functions](#cloud-functions)
- [Notificacions](#notificacions)
- [Security Rules](#security-rules)
- [Guia d'Ús](#guia-dús)

---

## 🎯 Visió General

Aquest sistema permet als àrbitres:

1. **Reaccionar** a jugades destacades amb 3 tipus de reaccions
2. **Comentar** jugades amb opcionalitat d'anonimat (sempre amb badge de categoria)
3. **Sol·licitar revisió** quan una jugada arriba a 10 reaccions
4. **Tancar debats** amb veredictes oficials (només ACB/FEB Grup 1)

### Regles Clau

- **Threshold de revisió**: 10 reaccions totals
- **Categories amb autoritat**: ACB i FEB Grup 1 poden tancar debats
- **Anonimat parcial**: L'àrbitre pot triar ser anònim, però el color de categoria sempre es mostra
- **Notificacions in-app**: No s'envien push ni emails

---

## 🔄 Flux del Sistema

```
1. Usuari crea highlight
   └─> Es guarda a matches/{matchId}/highlights/{highlightId}

2. Altres usuaris reaccionen (Like, Important, Controversial)
   └─> HighlightReactionService.toggleReaction()
   └─> Actualitza reactionsSummary automàticament
   └─> Si arriba a 10 reaccions:
       └─> Canvia status a "under_review"
       └─> Trigger Cloud Function: notifyRefereesOnThreshold
           └─> Busca àrbitres ACB, FEB Grup 1, FEB Grup 2
           └─> Crea notificacions in-app per a cadascun

3. Àrbitres comenten la jugada
   └─> RefereeCommentService.addComment()
   └─> Poden triar ser anònims
   └─> El badge de categoria sempre es mostra

4. Àrbitre ACB/FEB Grup 1 dona veredicte oficial
   └─> RefereeCommentService.addComment(isOfficial: true)
   └─> Marca highlight com "resolved"
   └─> Trigger Cloud Function: closeDebateOnOfficialComment
       └─> Obté tots els participants (creador + reactors + comentaristes)
       └─> Crea notificació de debat tancat per a tots
```

---

## 🧩 Components Principals

### Models

#### 1. **RefereeCategory** (`lib/core/constants/referee_category_colors.dart`)
Enum amb 6 categories arbitrals:
- `acb` - Lliga ACB (Or)
- `febGrup1` - FEB Grup 1 (Plata)
- `febGrup2` - FEB Grup 2 (Bronze)
- `febGrup3` - FEB Grup 3 (Blau fosc)
- `fcbqA1` - FCBQ A1 (Verd maragda)
- `fcbqOther` - Altres FCBQ (Lila)

**Mètodes importants:**
- `RefereeCategoryExtension.fromCategoriaRrtt()` - Extreu categoria des del camp `categoriaRrtt` de `referees_registry`
- `RefereeCategoryColors.canCloseDebate()` - Retorna `true` només per ACB i FEB Grup 1

#### 2. **HighlightReaction** (`lib/features/visionat/models/highlight_reaction.dart`)
```dart
class HighlightReaction {
  final String userId;
  final ReactionType type;  // like, important, controversial
  final DateTime timestamp;
}

class ReactionsSummary {
  final int likeCount;
  final int importantCount;
  final int controversialCount;
  final int totalCount;
}
```

#### 3. **RefereeComment** (`lib/features/visionat/models/referee_comment.dart`)
```dart
class RefereeComment {
  final String id;
  final String userId;
  final RefereeCategory category;
  final String comment;  // Mínim 50 caràcters
  final bool isAnonymous;
  final bool isOfficial;  // Veredicte final
  final String? refereeDisplayName;
  final DateTime createdAt;
}
```

#### 4. **HighlightPlay** (`lib/features/visionat/models/highlight_play.dart`)
Extensió de `HighlightEntry` amb:
```dart
class HighlightPlay extends HighlightEntry {
  final List<HighlightReaction> reactions;
  final ReactionsSummary reactionsSummary;
  final int commentCount;
  final HighlightPlayStatus status;  // open, under_review, resolved
  final DateTime? reviewNotifiedAt;
  final DateTime? resolvedAt;
  final String? officialCommentId;
}
```

### Widgets

#### 1. **RefereeCategoryBadge** (`lib/features/visionat/widgets/referee_category_badge.dart`)
Mostra la categoria d'àrbitre amb color de circumferència.
- Si `isAnonymous: true` → "Àrbitre ACB"
- Si `isAnonymous: false` → "Joan Pérez (ACB)"

#### 2. **HighlightReactionsBar** (`lib/features/visionat/widgets/highlight_reactions_bar.dart`)
Barra amb 3 botons de reacció:
- 👍 Like (Verd)
- ⚠️ Important (Taronja)
- 🔥 Controversial (Vermell)

Mostra el comptador de cada tipus i permet toggle.

#### 3. **ReactionThresholdIndicator** (`lib/features/visionat/widgets/highlight_reactions_bar.dart`)
Barra de progrés cap a les 10 reaccions.
Mostra missatge "Àrbitres notificats per revisar" quan s'arriba al threshold.

#### 4. **RefereeCommentsModal** (`lib/features/visionat/widgets/referee_comments_modal.dart`)
Modal complet per:
- Veure comentaris existents ordenats per jerarquia
- Afegir nou comentari (mínim 50 caràcters)
- Checkbox d'anonimat
- Botó "Tancar debat" (només ACB/FEB Grup 1)

### Services

#### 1. **HighlightReactionService** (`lib/features/visionat/services/highlight_reaction_service.dart`)
Gestiona reaccions:
```dart
Future<void> toggleReaction({
  required String matchId,
  required String highlightId,
  required String userId,
  required ReactionType type,
})
```
- Si l'usuari ja té aquesta reacció → l'elimina
- Si l'usuari té una altra reacció → la substitueix
- Màxim 1 reacció per usuari
- Actualitza `reactionsSummary` automàticament
- Detecta threshold i canvia status a `under_review`

#### 2. **RefereeCommentService** (`lib/features/visionat/services/referee_comment_service.dart`)
Gestiona comentaris:
```dart
Future<String> addComment({
  required String matchId,
  required String highlightId,
  required String userId,
  required RefereeCategory category,
  required String comment,
  required bool isAnonymous,
  bool isOfficial = false,
})
```
- Valida mínim 50 caràcters
- Valida autoritat per veredictes oficials
- Si `isOfficial: true` → marca highlight com `resolved`

#### 3. **HighlightPlayService** (`lib/features/visionat/services/highlight_play_service.dart`)
CRUD de jugades amb reaccions:
```dart
Future<List<HighlightPlay>> getPlaysUnderReview({required String matchId})
Future<List<HighlightPlay>> getTrendingPlays({required String matchId})
```

#### 4. **NotificationService** (`lib/core/services/notification_service.dart`)
Gestiona notificacions in-app:
```dart
Stream<List<AppNotification>> watchNotifications({required String userId})
Future<void> markAsRead(String notificationId)
Stream<int> watchUnreadCount(String userId)
```

---

## 🏆 Jerarquia d'Àrbitres

Ordre de màxima a mínima autoritat:

1. **ACB** (Or `#FFD700`) - Pot tancar debats
2. **FEB Grup 1** (Plata `#C0C0C0`) - Pot tancar debats
3. **FEB Grup 2** (Bronze `#CD7F32`)
4. **FEB Grup 3** (Blau fosc `#4A90E2`)
5. **FCBQ A1** (Verd maragda `#50C878`)
6. **FCBQ Other** (Lila `#9B59B6`)

### Permisos per Categoria

| Categoria | Reaccionar | Comentar | Tancar Debat | Rebut Notif. Threshold |
|-----------|------------|----------|--------------|------------------------|
| ACB | ✅ | ✅ | ✅ | ✅ |
| FEB Grup 1 | ✅ | ✅ | ✅ | ✅ |
| FEB Grup 2 | ✅ | ✅ | ❌ | ✅ |
| FEB Grup 3 | ✅ | ✅ | ❌ | ❌ |
| FCBQ A1 | ✅ | ✅ | ❌ | ❌ |
| FCBQ Other | ✅ | ✅ | ❌ | ❌ |

---

## 🎨 Tipus de Reaccions

### 1. Like (👍)
- Color: Verd `#50C878`
- Ús: "M'agrada" / "Ho he vist"
- Pes en prioritat: x2

### 2. Important (⚠️)
- Color: Taronja `#FFA500`
- Ús: "Important per revisar"
- Pes en prioritat: x2

### 3. Controversial (🔥)
- Color: Vermell `#E74C3C`
- Ús: "Genera debat" / "No estic d'acord"
- Pes en prioritat: x5

### Càlcul de Prioritat

```dart
double calculatePriority() {
  final timeDecay = 1.0 / (1 + (hoursOld / 24.0));
  return (reactionCount * 2.0 + controversialCount * 5.0) * timeDecay;
}
```

Les jugades controversials tenen més pes per facilitar la seva visibilitat.

---

## 📊 Estats de Highlights

### 1. **open** (Obert)
- Estat inicial
- Permet reaccions i comentaris
- No s'han arribat a 10 reaccions
- Badge: Cap

### 2. **under_review** (En revisió)
- S'ha arribat a 10 reaccions
- Àrbitres de màxima categoria notificats
- Permet reaccions i comentaris
- Badge: 🔍 "En revisió" (Taronja)

### 3. **resolved** (Resolt)
- Veredicte oficial donat per ACB/FEB Grup 1
- NO permet més reaccions
- NO permet més comentaris
- Badge: ✅ "Resolt" (Verd)

---

## ☁️ Cloud Functions

### 1. **notifyRefereesOnThreshold** (`functions/src/visionat/notify_referees_on_threshold.ts`)

**Trigger**: `onDocumentUpdated` en `matches/{matchId}/highlights/{highlightId}`

**Condicions**:
- `beforeData.reactionsSummary.totalCount < 10`
- `afterData.reactionsSummary.totalCount >= 10`
- `afterData.status === 'under_review'`

**Accions**:
1. Busca àrbitres amb categoria ACB, FEB Grup 1 o FEB Grup 2 a `referees_registry`
2. Per cada àrbitre, obté el `uid` des de `app_users` (matching per `llissenciaId`)
3. Crea notificació in-app a `notifications` collection:
```typescript
{
  type: "highlight_review_requested",
  title: "Nova jugada per revisar",
  message: "La jugada 'X' ha arribat a 10 reaccions i necessita la teva opinió.",
  data: { matchId, highlightId, reactionCount },
  expiresAt: +7 dies
}
```

**Exemple log**:
```
[notifyReferees] 🔔 Threshold assolit! Match: abc123, Highlight: def456, Reaccions: 10
[notifyReferees] Trobats 3 àrbitres de màxima categoria
[notifyReferees] ✅ 3 notificacions creades
[notifyReferees] ✅ Procés completat
```

### 2. **closeDebateOnOfficialComment** (`functions/src/visionat/close_debate_on_official_comment.ts`)

**Trigger**: `onDocumentCreated` en `matches/{matchId}/highlights/{highlightId}/referee_comments/{commentId}`

**Condicions**:
- `commentData.isOfficial === true`
- `canCloseDebate(commentData.category)` retorna `true` (ACB o FEB Grup 1)

**Accions**:
1. Valida autoritat de l'àrbitre
   - Si NO té autoritat → revoca `isOfficial: false` al comentari
2. Actualitza highlight:
```typescript
{
  status: "resolved",
  officialCommentId: commentId,
  resolvedAt: serverTimestamp()
}
```
3. Obté participants:
   - Creador del highlight
   - Usuaris amb reaccions
   - Usuaris amb comentaris
4. Crea notificació per a cada participant (excepte l'àrbitre oficial):
```typescript
{
  type: "debate_closed",
  title: "Debat tancat amb veredicte oficial",
  message: "Un àrbitre ACB ha donat el veredicte final sobre 'X'.",
  data: { matchId, highlightId, refereeCategory },
  expiresAt: +7 dies
}
```

**Exemple log**:
```
[closeDebate] 🔒 Comentari oficial detectat! Match: abc123, Highlight: def456
[closeDebate] ✅ Highlight marcat com resolt
[closeDebate] Trobats 8 participants
[closeDebate] ✅ 7 notificacions creades
[closeDebate] ✅ Procés completat
```

**Validació d'autoritat**:
```typescript
function canCloseDebate(category: string): boolean {
  return category === "ACB" || category === "FEB_GRUP_1";
}
```

---

## 🔔 Notificacions

### Tipus de Notificacions

#### 1. **highlight_review_requested**
- **Quan**: Jugada arriba a 10 reaccions
- **Destinataris**: Àrbitres ACB, FEB Grup 1, FEB Grup 2
- **Títol**: "Nova jugada per revisar"
- **Missatge**: "La jugada '{title}' ha arribat a {count} reaccions i necessita la teva opinió."

#### 2. **debate_closed**
- **Quan**: Àrbitre ACB/FEB Grup 1 dona veredicte oficial
- **Destinataris**: Creador + reactors + comentaristes (excepte l'àrbitre oficial)
- **Títol**: "Debat tancat amb veredicte oficial"
- **Missatge**: "Un àrbitre {category} ha donat el veredicte final sobre '{title}'."

#### 3. **new_reaction**
- **Quan**: Algú reacciona a la teva jugada
- **Destinataris**: Creador del highlight
- **Títol**: "Nova reacció a la teva jugada"
- *(Futura implementació)*

#### 4. **comment_reply**
- **Quan**: Algú respon al teu comentari
- **Destinataris**: Autor del comentari original
- **Títol**: "Resposta al teu comentari"
- *(Futura implementació)*

### Model AppNotification

```dart
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;  // 7 dies per defecte
}
```

### Ús al Client

```dart
// Stream de notificacions
final notificationsStream = NotificationService().watchNotifications(
  userId: currentUser.uid,
  onlyUnread: true,
);

// Marcar com llegida
await NotificationService().markAsRead(notificationId);

// Comptador no llegides
final unreadCountStream = NotificationService().watchUnreadCount(
  userId: currentUser.uid,
);
```

---

## 🔒 Security Rules

### Highlights amb Reaccions

```javascript
match /highlights/{matchId}/entries/{highlightId} {
  // Lectura: qualsevol autenticat
  allow read: if request.auth != null;

  // Creació: qualsevol autenticat (com a creador)
  allow create: if request.auth != null
    && request.auth.uid == request.resource.data.createdBy;

  // Actualització: 3 casos
  allow update: if request.auth != null && (
    // 1. Toggle reaccions (qualsevol usuari)
    isValidReactionToggle(request.resource.data, resource.data, request.auth.uid)
    ||
    // 2. Modificar contingut (només creador)
    (request.auth.uid == resource.data.createdBy)
    ||
    // 3. Canvi de status (Cloud Functions amb Admin SDK)
    isServerSideStatusUpdate(request.resource.data, resource.data)
  );

  // Eliminació: només creador
  allow delete: if request.auth != null
    && request.auth.uid == resource.data.createdBy;
}
```

### Comentaris d'Àrbitres

```javascript
match /highlights/{matchId}/entries/{highlightId}/referee_comments/{commentId} {
  // Lectura: qualsevol autenticat
  allow read: if request.auth != null;

  // Creació: només àrbitres registrats
  allow create: if request.auth != null
    && request.auth.uid == request.resource.data.userId
    && isValidRefereeComment(request.resource.data, commentId);

  // Actualització: només creador, si no és oficial
  allow update: if request.auth != null
    && request.auth.uid == resource.data.userId
    && !resource.data.isOfficial;

  // Eliminació: només creador, si no és oficial
  allow delete: if request.auth != null
    && request.auth.uid == resource.data.userId
    && !resource.data.isOfficial;
}
```

### Notificacions

```javascript
match /notifications/{notificationId} {
  // Lectura: només destinatari
  allow read: if request.auth != null
    && request.auth.uid == resource.data.userId;

  // Creació: NOMÉS Cloud Functions
  allow create: if false;

  // Actualització: només destinatari (marcar com llegida)
  allow update: if request.auth != null
    && request.auth.uid == resource.data.userId
    && isValidNotificationUpdate(request.resource.data, resource.data);

  // Eliminació: només destinatari
  allow delete: if request.auth != null
    && request.auth.uid == resource.data.userId;
}
```

---

## 📖 Guia d'Ús

### Per Usuaris (Àrbitres)

#### 1. Reaccionar a una Jugada

```dart
// Al widget HighlightReactionsBar
onReactionTap: (type) async {
  await provider.toggleReaction(highlightId, type);
}
```

**UX**:
- Clic al botó Like/Important/Controversial
- Si ja tens aquesta reacció → es treu
- Si tens una altra reacció → es substitueix
- El comptador s'actualitza en temps real

#### 2. Veure Comentaris

```dart
// Obrir modal
showDialog(
  context: context,
  builder: (context) => RefereeCommentsModal(
    play: highlightPlay,
    comments: commentsStream,
    currentUserCategory: userCategory,
  ),
);
```

**UX**:
- Modal amb llista de comentaris ordenats per jerarquia
- Comentaris oficials apareixen primer
- Després comentaris per categoria (ACB → FEB Grup 1 → ...)

#### 3. Afegir Comentari

```dart
// Al formulari del modal
await provider.addRefereeComment(
  highlightId: highlightId,
  comment: commentController.text,
  isAnonymous: _isAnonymous,
  isOfficial: false,
);
```

**Validacions**:
- Mínim 50 caràcters
- Checkbox d'anonimat (opcional)
- El badge de categoria sempre es mostra

#### 4. Tancar Debat (ACB/FEB Grup 1 només)

```dart
// Botó "Tancar debat" visible només si canCloseDebate(category)
await provider.addRefereeComment(
  highlightId: highlightId,
  comment: commentController.text,
  isAnonymous: _isAnonymous,
  isOfficial: true,  // ← Veredicte final
);
```

**UX**:
- Apareix diàleg de confirmació
- Si confirma → comentari marcat com oficial
- Highlight passa a status "resolved"
- Tots els participants reben notificació

#### 5. Veure Notificacions

```dart
// Stream de notificacions
StreamBuilder<List<AppNotification>>(
  stream: NotificationService().watchNotifications(
    userId: currentUser.uid,
    onlyUnread: true,
  ),
  builder: (context, snapshot) {
    // Mostrar llista de notificacions
  },
)
```

**UX**:
- Badge amb comptador de no llegides
- Tap a notificació → navega al highlight
- Marcar com llegida automàticament

### Per Desenvolupadors

#### Integrar Highlights amb Reaccions

```dart
// 1. Inicialitzar provider
final provider = Provider.of<VisionatHighlightProvider>(context);
await provider.setMatch(matchId);

// 2. Mostrar timeline amb reaccions
HighlightsTimeline(
  highlights: provider.highlights,
  onReactionTap: (highlightId, type) {
    provider.toggleReaction(highlightId, type);
  },
  onCommentTap: (highlightId) {
    _showCommentsModal(highlightId);
  },
)

// 3. Mostrar modal de comentaris
void _showCommentsModal(String highlightId) {
  final play = provider.highlights
    .firstWhere((h) => h.id == highlightId) as HighlightPlay;

  showDialog(
    context: context,
    builder: (context) => StreamBuilder<List<RefereeComment>>(
      stream: provider.watchComments(highlightId),
      builder: (context, snapshot) {
        return RefereeCommentsModal(
          play: play,
          comments: snapshot.data ?? [],
          currentUserCategory: await provider.getCurrentUserCategory(),
          onCommentAdded: (comment, isAnonymous, isOfficial) {
            provider.addRefereeComment(
              highlightId: highlightId,
              comment: comment,
              isAnonymous: isAnonymous,
              isOfficial: isOfficial,
            );
          },
        );
      },
    ),
  );
}
```

#### Testejar Cloud Functions Localment

```bash
# 1. Compilar TypeScript
cd functions
npm run build

# 2. Executar emulador
firebase emulators:start --only functions,firestore

# 3. Simular trigger (exemple)
curl -X POST http://localhost:5001/el-visionat/europe-west1/notifyRefereesOnThreshold
```

#### Desplegar a Producció

```bash
# 1. Build functions
cd functions && npm run build

# 2. Deploy funcions específiques
firebase deploy --only functions:notifyRefereesOnThreshold,functions:closeDebateOnOfficialComment

# 3. Deploy security rules
firebase deploy --only firestore:rules
```

---

## 🐛 Debugging i Logs

### Client (Flutter)

```dart
// Activar logs de debug
debugPrint('[HighlightProvider] Loading highlights for match: $matchId');
```

### Cloud Functions

```typescript
// Logs apareixen a Firebase Console > Functions > Logs
console.log('[notifyReferees] 🔔 Threshold assolit!');
console.error('[closeDebate] ❌ Error:', error);
```

**Veure logs en temps real**:
```bash
firebase functions:log --only notifyRefereesOnThreshold
```

### Firestore Security Rules

Si una operació falla per security rules, el missatge d'error indica la regla que ha fallat:

```
PERMISSION_DENIED: Missing or insufficient permissions.
```

**Testejar rules localment**:
```bash
firebase emulators:start --only firestore
# Usa el Firestore Emulator UI: http://localhost:4000
```

---

## ✅ Checklist de Verificació

### Desenvolupament

- [x] Models creats i testejats
- [x] Widgets integrats a la UI
- [x] Services amb gestió d'errors
- [x] Provider amb mounted checks
- [x] Cloud Functions desplegades
- [x] Security Rules configurades
- [x] Notificacions funcionant

### Testing

- [ ] Test unitaris de models
- [ ] Test unitaris de services
- [ ] Test d'integració del provider
- [ ] Test de Cloud Functions amb emulador
- [ ] Test de Security Rules
- [ ] Test E2E del flux complet

### Producció

- [x] Functions desplegades a `europe-west1`
- [x] Security Rules desplegades
- [ ] Índexs compostos creats a Firestore
- [ ] Monitorització de Cloud Functions activada
- [ ] Alertes configurades (errors, latència)

---

## 📚 Referències

### Firestore Collections

```
/highlights/{matchId}/entries/{highlightId}
  - reactions: List<HighlightReaction>
  - reactionsSummary: ReactionsSummary
  - status: 'open' | 'under_review' | 'resolved'
  - commentCount: number
  - officialCommentId?: string
  - reviewNotifiedAt?: Timestamp
  - resolvedAt?: Timestamp

/highlights/{matchId}/entries/{highlightId}/referee_comments/{commentId}
  - userId: string
  - category: string (ACB, FEB_GRUP_1, etc.)
  - comment: string (mínim 50 chars)
  - isAnonymous: boolean
  - isOfficial: boolean
  - createdAt: Timestamp

/notifications/{notificationId}
  - userId: string
  - type: 'highlight_review_requested' | 'debate_closed' | ...
  - title: string
  - message: string
  - data: { matchId, highlightId, ... }
  - isRead: boolean
  - createdAt: Timestamp
  - expiresAt: Timestamp
```

### Índexs Necessaris

Crear manualment a [Firebase Console](https://console.firebase.google.com/project/el-visionat/firestore/indexes):

```
Collection: matches/{matchId}/highlights
  - status ASC, reviewNotifiedAt DESC

Collection: notifications
  - userId ASC, isRead ASC, createdAt DESC
  - userId ASC, createdAt DESC
```

---

## 🎓 FAQ

### P: Què passa si un àrbitre FEB Grup 2 intenta tancar un debat?

R: El `RefereeCommentService` valida l'autoritat abans d'acceptar `isOfficial: true`. Si no té autoritat, llança una excepció. Addicionalment, la Cloud Function `closeDebateOnOfficialComment` reverteix el flag `isOfficial` a `false` si detecta que la categoria no pot tancar debats.

### P: Es poden editar comentaris oficials?

R: No. Les Security Rules i el `RefereeCommentService` impedeixen editar o eliminar comentaris amb `isOfficial: true`.

### P: Què passa si s'elimina un highlight amb comentaris?

R: Els comentaris estan a una subcol·lecció, així que s'eliminaran en cascada quan s'elimini el document pare. Això és segur perquè els highlights només poden ser eliminats pel creador (Security Rule).

### P: Com es calcula la categoria d'un àrbitre?

R:
1. Es busca l'usuari a `app_users` per obtenir el `llissenciaId`
2. Es busca aquest `llissenciaId` a `referees_registry` per obtenir `categoriaRrtt`
3. `RefereeCategoryExtension.fromCategoriaRrtt()` extreu la categoria des del string (exemple: "ÀRBITRE FEB (GRUP 1) Barcelona" → `febGrup1`)

### P: Les notificacions expiren?

R: Sí, per defecte tenen `expiresAt` de 7 dies des de la creació. El `NotificationService` té un mètode `cleanExpiredNotifications()` per netejar-les.

---

**Última actualització**: 2026-01-05
**Versió**: 1.0.0
**Autor**: Claude Sonnet 4.5 (Assistant)
