// ============================================================================
// Process PDF - Processa PDFs d'informes i tests amb IA
// ============================================================================
// Aquesta funció s'activa quan es puja un PDF a Firebase Storage.
// Utilitza l'API de Claude (Anthropic) per extreure les dades del PDF
// i crear automàticament els documents corresponents a Firestore.
// ============================================================================

import {onObjectFinalized} from "firebase-functions/v2/storage";
import {defineString} from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import Anthropic from "@anthropic-ai/sdk";

// Definir la clau API com a paràmetre secret
const anthropicApiKey = defineString("ANTHROPIC_API_KEY");

/**
 * Funció que es dispara quan es puja un PDF a Storage
 *
 * Ruta esperada: pdfs/{userId}/{fileName}
 * Metadata esperada:
 *   - type: "report" o "test"
 *   - userId: UID de l'usuari
 *   - uploadedAt: timestamp ISO
 */
export const processPdfOnUpload = onObjectFinalized(
  {
    region: "europe-west1",
    memory: "1GiB",
    timeoutSeconds: 540, // 9 minuts (màxim per Cloud Functions)
    maxInstances: 10,
    // Només per arxius PDF dins la carpeta pdfs/
    bucket: undefined, // Bucket per defecte
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // Validar que és un PDF dins la carpeta pdfs/
    if (!filePath.startsWith("pdfs/") || contentType !== "application/pdf") {
      logger.info(`Fitxer ignorat: ${filePath} (tipus: ${contentType})`);
      return null;
    }

    // Validar metadata
    const metadata = event.data.metadata || {};
    const type = metadata.type as "report" | "test";
    const userId = metadata.userId;

    if (!type || !userId) {
      logger.error(`Metadata invàlida per ${filePath}:`, metadata);
      return null;
    }

    logger.info(`Processant PDF: ${filePath}`, {type, userId});

    try {
      // 1. Descarregar el PDF de Storage
      const bucket = admin.storage().bucket(event.data.bucket);
      const file = bucket.file(filePath);
      const [fileBuffer] = await file.download();
      const base64Pdf = fileBuffer.toString("base64");

      logger.info(`PDF descarregat: ${fileBuffer.length} bytes`);

      // 2. Cridar l'API de Claude per processar el PDF
      const extractedData = await extractDataWithClaude(
        base64Pdf,
        type,
        anthropicApiKey.value()
      );

      logger.info("Dades extretes amb èxit:", extractedData);

      // 3. Guardar les dades a Firestore
      if (type === "report") {
        await saveReportToFirestore(userId, extractedData);
      } else if (type === "test") {
        await saveTestToFirestore(userId, extractedData);
      }

      // 4. Actualitzar tracking de la temporada
      await updateSeasonTracking(userId);

      logger.info(`PDF processat correctament: ${filePath}`);

      // 5. Opcional: Marcar el fitxer com a processat
      await file.setMetadata({
        metadata: {
          ...metadata,
          processed: "true",
          processedAt: new Date().toISOString(),
        },
      });

      return {success: true, type, userId};
    } catch (error) {
      logger.error(`Error processant PDF ${filePath}:`, error);

      // Marcar com a error
      const file = admin.storage().bucket(event.data.bucket).file(filePath);
      await file.setMetadata({
        metadata: {
          ...metadata,
          processed: "false",
          error: String(error),
          errorAt: new Date().toISOString(),
        },
      });

      throw error;
    }
  }
);

/**
 * Extreu dades del PDF utilitzant Claude API
 */
async function extractDataWithClaude(
  base64Pdf: string,
  type: "report" | "test",
  apiKey: string
): Promise<any> {
  const anthropic = new Anthropic({
    apiKey: apiKey,
  });

  const prompt = type === "report"
    ? getReportExtractionPrompt()
    : getTestExtractionPrompt();

  logger.info("Cridant API de Claude...");

  const message = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    max_tokens: 4096,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "document",
            source: {
              type: "base64",
              media_type: "application/pdf",
              data: base64Pdf,
            },
          },
          {
            type: "text",
            text: prompt,
          },
        ],
      },
    ],
  });

  // Extreure el contingut de text
  const textContent = message.content.find((block) => block.type === "text");
  if (!textContent || textContent.type !== "text") {
    throw new Error("No s'ha rebut resposta de text de Claude");
  }

  // Parsejar JSON de la resposta
  const jsonText = textContent.text;

  // Extreure JSON del markdown code block si cal
  let cleanJson = jsonText.trim();
  if (cleanJson.startsWith("```json")) {
    cleanJson = cleanJson.replace(/^```json\n/, "").replace(/\n```$/, "");
  } else if (cleanJson.startsWith("```")) {
    cleanJson = cleanJson.replace(/^```\n/, "").replace(/\n```$/, "");
  }

  const extractedData = JSON.parse(cleanJson);

  logger.info("Dades parseades amb èxit");

  return extractedData;
}

/**
 * Prompt per extreure dades d'un informe d'arbitratge
 */
function getReportExtractionPrompt(): string {
  return `Analitza aquest informe d'arbitratge de bàsquet i extreu les següents dades en format JSON.

L'informe conté una avaluació de l'àrbitre amb categories valorades de ÒPTIM a MILLORABLE, i punts de millora identificats.

Retorna un JSON amb aquesta estructura exacta:

{
  "date": "YYYY-MM-DD",
  "competition": "Nom de la competició",
  "teams": "Equip A vs Equip B",
  "evaluator": "Nom de l'informador",
  "finalGrade": "OPTIM" | "SATISFACTORI" | "ACCEPTABLE" | "MILLORABLE" | "NO_VALORABLE",
  "categories": [
    {
      "name": "Nom de la categoria",
      "grade": "OPTIM" | "SATISFACTORI" | "ACCEPTABLE" | "MILLORABLE" | "NO_VALORABLE",
      "comments": "Comentaris o buit si no n'hi ha"
    }
  ],
  "improvementPoints": [
    {
      "categoryName": "Nom de la categoria",
      "description": "Descripció del punt de millora"
    }
  ],
  "comments": "Comentaris generals de l'informe"
}

IMPORTANT:
- La data ha de ser en format YYYY-MM-DD
- El finalGrade és la valoració global final
- Les categories són les diferents àrees avaluades (posicionament, mecànica, comunicació, etc.)
- Els improvementPoints són els aspectes específics a millorar que l'informador ha destacat
- Si alguna dada no està disponible, usa cadena buida "" o array buit []
- NO afegeixis explicacions, només retorna el JSON`;
}

/**
 * Prompt per extreure dades d'un test (teòric o físic)
 */
function getTestExtractionPrompt(): string {
  return `Analitza aquest test d'arbitratge de bàsquet i extreu les següents dades en format JSON.

El test pot ser teòric (preguntes de reglament) o físic (proves de condició física).

Retorna un JSON amb aquesta estructura exacta:

{
  "testName": "Nom del test",
  "date": "YYYY-MM-DD",
  "isTheoretical": true,
  "score": 8.5,
  "timeSpentMinutes": 45,
  "totalQuestions": 25,
  "correctAnswers": 21,
  "allQuestions": [
    {
      "questionNumber": 1,
      "category": "Reglament - Faltes Personals",
      "question": "Enunciat de la pregunta",
      "isCorrect": true,
      "userAnswer": "A",
      "correctAnswer": "A"
    }
  ],
  "conflictiveQuestions": [
    {
      "questionNumber": 3,
      "category": "Reglament - Violacions",
      "reason": "Per què s'ha fallat"
    }
  ]
}

IMPORTANT:
- isTheoretical: true per test teòric, false per físic
- score: nota sobre 10
- La data ha de ser en format YYYY-MM-DD
- allQuestions conté totes les preguntes amb les respostes
- conflictiveQuestions són les preguntes fallades o amb dubte
- Si alguna dada no està disponible, usa valor per defecte raonable
- Per tests físics, adapta la estructura (les "questions" seran proves)
- NO afegeixis explicacions, només retorna el JSON`;
}

/**
 * Guarda un informe a Firestore
 */
async function saveReportToFirestore(
  userId: string,
  data: any
): Promise<void> {
  const db = admin.firestore();

  const reportData = {
    userId: userId,
    date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
    competition: data.competition || "",
    teams: data.teams || "",
    evaluator: data.evaluator || "",
    finalGrade: data.finalGrade || "NO_VALORABLE",
    categories: data.categories || [],
    improvementPoints: data.improvementPoints || [],
    comments: data.comments || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("reports").add(reportData);

  logger.info("Informe guardat a Firestore");
}

/**
 * Guarda un test a Firestore
 */
async function saveTestToFirestore(userId: string, data: any): Promise<void> {
  const db = admin.firestore();

  const testData = {
    userId: userId,
    testName: data.testName || "Test sense nom",
    date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
    isTheoretical: data.isTheoretical ?? true,
    score: data.score || 0,
    timeSpentMinutes: data.timeSpentMinutes || 0,
    totalQuestions: data.totalQuestions || 0,
    correctAnswers: data.correctAnswers || 0,
    allQuestions: data.allQuestions || [],
    conflictiveQuestions: data.conflictiveQuestions || [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("tests").add(testData);

  logger.info("Test guardat a Firestore");
}

/**
 * Actualitza el tracking de millores de la temporada actual
 */
async function updateSeasonTracking(userId: string): Promise<void> {
  const db = admin.firestore();

  // Determinar temporada actual
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1; // 1-12
  const season = month >= 9 ? `${year}-${year + 1}` : `${year - 1}-${year}`;

  const trackingId = `${userId}_${season}`;

  logger.info(`Actualitzant tracking per temporada ${season}`);

  // Obtenir tots els informes i tests de la temporada
  const [reportsSnapshot, testsSnapshot] = await Promise.all([
    db.collection("reports")
      .where("userId", "==", userId)
      .get(),
    db.collection("tests")
      .where("userId", "==", userId)
      .get(),
  ]);

  // Processar punts de millora dels informes
  const improvementMap = new Map<string, {
    occurrences: number;
    descriptions: Set<string>;
    lastOccurrence: Date;
  }>();

  reportsSnapshot.forEach((doc) => {
    const report = doc.data();
    const reportDate = report.date.toDate();

    // Només comptar si és de la temporada actual
    const reportYear = reportDate.getFullYear();
    const reportMonth = reportDate.getMonth() + 1;
    const reportSeason = reportMonth >= 9 ?
      `${reportYear}-${reportYear + 1}` :
      `${reportYear - 1}-${reportYear}`;

    if (reportSeason !== season) return;

    (report.improvementPoints || []).forEach((point: any) => {
      const existing = improvementMap.get(point.categoryName);
      if (existing) {
        existing.occurrences++;
        existing.descriptions.add(point.description);
        if (reportDate > existing.lastOccurrence) {
          existing.lastOccurrence = reportDate;
        }
      } else {
        improvementMap.set(point.categoryName, {
          occurrences: 1,
          descriptions: new Set([point.description]),
          lastOccurrence: reportDate,
        });
      }
    });
  });

  const reportImprovements = Array.from(improvementMap.entries()).map(
    ([categoryName, data]) => ({
      categoryName,
      occurrences: data.occurrences,
      descriptions: Array.from(data.descriptions),
      lastOccurrence: admin.firestore.Timestamp.fromDate(data.lastOccurrence),
      isImproving: false, // Caldria comparar amb períodes anteriors
    })
  );

  // Processar àrees febles dels tests
  const weakAreasMap = new Map<string, {
    totalQuestions: number;
    incorrectAnswers: number;
    topics: Set<string>;
  }>();

  testsSnapshot.forEach((doc) => {
    const test = doc.data();
    const testDate = test.date.toDate();

    // Només comptar si és de la temporada actual
    const testYear = testDate.getFullYear();
    const testMonth = testDate.getMonth() + 1;
    const testSeason = testMonth >= 9 ?
      `${testYear}-${testYear + 1}` :
      `${testYear - 1}-${testYear}`;

    if (testSeason !== season) return;

    (test.conflictiveQuestions || []).forEach((q: any) => {
      const existing = weakAreasMap.get(q.category);
      if (existing) {
        existing.totalQuestions++;
        existing.incorrectAnswers++;
        existing.topics.add(q.reason || "Error sense especificar");
      } else {
        weakAreasMap.set(q.category, {
          totalQuestions: 1,
          incorrectAnswers: 1,
          topics: new Set([q.reason || "Error sense especificar"]),
        });
      }
    });
  });

  const testWeakAreas = Array.from(weakAreasMap.entries()).map(
    ([category, data]) => ({
      category,
      totalQuestions: data.totalQuestions,
      incorrectAnswers: data.incorrectAnswers,
      errorRate: (data.incorrectAnswers / data.totalQuestions) * 100,
      conflictiveTopics: Array.from(data.topics),
    })
  );

  // Guardar o actualitzar el document de tracking
  const trackingData = {
    userId,
    season,
    reportImprovements,
    testWeakAreas,
    studyMaterials: [], // Es generarà en una funció separada
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("improvement_tracking").doc(trackingId).set(
    trackingData,
    {merge: true}
  );

  logger.info(`Tracking actualitzat per ${trackingId}`);
}
