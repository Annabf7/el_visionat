# Sistema de Processament de PDFs amb IA

Aquest document explica com configurar i utilitzar el sistema de processament automàtic de PDFs d'informes i tests amb Claude AI.

## Configuració

### 1. Obtenir clau API d'Anthropic

1. Ves a [Anthropic Console](https://console.anthropic.com/)
2. Crea un compte o inicia sessió
3. Ves a "API Keys" i crea una nova clau
4. Copia la clau (comença per `sk-ant-...`)

### 2. Configurar la clau a Firebase

Executa aquesta comanda al terminal (substitueix `YOUR_API_KEY` per la teva clau real):

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Quan et demani el valor, enganxa la teva clau API.

**IMPORTANT**: Aquesta clau es guarda de forma segura a Google Secret Manager i no es commiteja mai al repositori.

### 3. Donar permisos a la Cloud Function

La funció necessita accés al secret. Això es configura automàticament quan despleguem, però si tens problemes:

```bash
gcloud secrets add-iam-policy-binding ANTHROPIC_API_KEY \
  --member=serviceAccount:YOUR_PROJECT@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
```

## Com funciona

### 1. Upload de PDF (Frontend)

L'usuari puja un PDF des de la pàgina "Informes + Test":

1. Clica el botó flotant "Pujar PDF"
2. Selecciona el tipus: Informe o Test
3. Selecciona l'arxiu PDF (màxim 10MB)
4. El PDF es puja a Firebase Storage a `pdfs/{userId}/{timestamp}_{filename}`

### 2. Processament Automàtic (Cloud Function)

Quan es detecta un nou PDF:

1. **Trigger**: `processPdfOnUpload` s'executa automàticament
2. **Descàrrega**: La funció descarrega el PDF de Storage
3. **Extracció IA**: Envia el PDF a Claude 3.5 Sonnet amb un prompt específic
4. **Parseig**: Converteix la resposta JSON de Claude a dades estructurades
5. **Guardat**: Crea documents a Firestore:
   - `reports/{docId}` per informes
   - `tests/{docId}` per tests
6. **Tracking**: Actualitza `improvement_tracking/{userId}_{season}` amb estadístiques agregades

### 3. Visualització (Frontend)

Les dades processades es mostren automàticament a la pàgina gràcies a `ReportsProvider` que escolta els canvis de Firestore.

## Estructura de Dades Extretes

### Informes d'Arbitratge

```json
{
  "date": "2025-01-11",
  "competition": "Lliga ACB",
  "teams": "Barça vs Real Madrid",
  "evaluator": "Joan Pérez",
  "finalGrade": "SATISFACTORI",
  "categories": [
    {
      "name": "Posicionament",
      "grade": "OPTIM",
      "comments": "Excel·lent cobertura"
    }
  ],
  "improvementPoints": [
    {
      "categoryName": "Comunicació",
      "description": "Millorar claredat en explicacions"
    }
  ],
  "comments": "Bon partit en general"
}
```

### Tests Teòrics/Físics

```json
{
  "testName": "Test Reglament Gener 2025",
  "date": "2025-01-11",
  "isTheoretical": true,
  "score": 8.5,
  "timeSpentMinutes": 45,
  "totalQuestions": 25,
  "correctAnswers": 21,
  "allQuestions": [...],
  "conflictiveQuestions": [
    {
      "questionNumber": 3,
      "category": "Reglament - Violacions",
      "reason": "Confusió sobre pasos"
    }
  ]
}
```

## Desplegar les Functions

```bash
# Desplegar totes les funcions
npm run deploy

# O només la funció de PDFs
firebase deploy --only functions:processPdfOnUpload
```

## Monitoritzar Logs

```bash
# Veure logs en temps real
firebase functions:log --only processPdfOnUpload

# O des de la consola de Firebase
# https://console.firebase.google.com/project/YOUR_PROJECT/functions/logs
```

## Costos Estimats

### Claude API (Anthropic)

- Model: Claude 3.5 Sonnet
- Cost aproximat per PDF:
  - Input: ~$3 per milió de tokens (~10 pàgines PDF ≈ 4000 tokens = $0.012)
  - Output: ~$15 per milió de tokens (~1000 tokens resposta = $0.015)
  - **Total per PDF: ~$0.027** (menys de 3 cèntims)

### Firebase Cloud Functions

- Invocacions: Primeres 2M gratuïtes/mes
- Temps execució: Primers 400K GB-seg gratuïts/mes
- Networking: Primer 5GB gratuït/mes

**Estimació**: Amb 100 PDFs/mes → ~$2.70 (només API de Claude)

## Troubleshooting

### Error: "Missing ANTHROPIC_API_KEY"

Assegura't d'haver configurat el secret:

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

### Error: "Permission denied on secret"

Dona permisos al compte de servei:

```bash
gcloud secrets add-iam-policy-binding ANTHROPIC_API_KEY \
  --member=serviceAccount:YOUR_PROJECT@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
```

### PDF no es processa

1. Verifica que el PDF s'ha pujat correctament a Storage
2. Revisa els logs: `firebase functions:log --only processPdfOnUpload`
3. Comprova que la metadata conté `type` i `userId`

### Extracció incorrecta

Si Claude no extreu les dades correctament:

1. Revisa el format del PDF (ha de ser text, no imatge escanejada)
2. Ajusta els prompts a `process_pdf.ts` si cal més contexte
3. Considera augmentar `max_tokens` si les respostes queden tallades

## Seguretat

- ✅ La clau API es guarda a Google Secret Manager (encriptada)
- ✅ Només les Cloud Functions poden accedir al secret
- ✅ Els PDFs es guarden per usuari: `pdfs/{userId}/`
- ✅ Les regles de seguretat de Firestore validen ownership
- ✅ No s'exposa mai la clau al client

## Millores Futures

- [ ] Validació OCR per PDFs escanejats (Tesseract.js)
- [ ] Retry automàtic si l'extracció falla
- [ ] Cache de resultats per evitar reprocesar el mateix PDF
- [ ] Notificacions push quan acaba el processament
- [ ] Dashboard d'estadístiques d'ús d'API
