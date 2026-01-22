// ============================================================================
// Process PDF - Processa PDFs d'informes i tests
// ============================================================================
// Aquesta funció s'activa quan es puja un PDF a Firebase Storage.
// Per TESTS: Utilitza pdf-parse per extreure text i parsing determinístic
// Per INFORMES: Utilitza Vertex AI (Gemini) ja que tenen format més complex
// ============================================================================

import {onObjectFinalized} from "firebase-functions/v2/storage";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {VertexAI} from "@google-cloud/vertexai";
// eslint-disable-next-line @typescript-eslint/no-require-imports
const pdfParse = require("pdf-parse");

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
    bucket: "el-visionat.firebasestorage.app",
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

      logger.info(`PDF descarregat: ${fileBuffer.length} bytes`);

      // 2. Processar segons el tipus
      if (type === "test") {
        // TESTS: Parser determinístic sense IA
        const extractedData = await parseTestPdfDeterministic(fileBuffer);
        logger.info("Dades extretes amb parser determinístic:", extractedData);
        await saveTestToFirestore(userId, extractedData);
      } else if (type === "report") {
        // INFORMES: Utilitzar Gemini (format més complex)
        const base64Pdf = fileBuffer.toString("base64");
        const extractedData = await extractDataWithVertexAI(base64Pdf);
        logger.info("Dades extretes amb Gemini:", extractedData);
        await saveReportToFirestore(userId, extractedData);
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

// ============================================================================
// PARSER DETERMINÍSTIC PER TESTS (SENSE IA)
// ============================================================================

interface ParsedQuestion {
  questionNumber: number;
  questionText: string;
  punctuation: string;
  isCorrect: boolean;
  userAnswer: string | null;
  correctAnswer: string;
}

interface ParsedTestData {
  testName: string;
  date: string;
  score: number;
  timeSpentMinutes: number;
  totalQuestions: number;
  correctAnswers: number;
  allQuestions: Array<{
    questionNumber: number;
    category: string;
    questionText: string; // Ha de coincidir amb el model Dart
    isCorrect: boolean;
    userAnswer: string | null;
    correctAnswer: string;
  }>;
  conflictiveQuestions: Array<{
    questionNumber: number;
    questionText: string;
    userAnswer: string;
    correctAnswer: string;
    explanation: string;
    category: string;
    reason: string; // Utilitzat per updateSeasonTracking
  }>;
}

/**
 * Parser determinístic per tests - NO utilitza IA
 * Extreu text del PDF i parseja amb regex
 */
async function parseTestPdfDeterministic(
  pdfBuffer: Buffer
): Promise<ParsedTestData> {
  // Extreure text del PDF
  const pdfData = await pdfParse(pdfBuffer);
  const text = pdfData.text;

  logger.info("Text extret del PDF, longitud:", text.length);

  // Extreure metadades
  const testName = extractTestName(text);
  const date = extractDate(text);
  const score = extractScore(text);
  const timeSpentMinutes = extractTimeSpent(text);

  // Extreure preguntes
  const questions = extractQuestions(text);

  logger.info(`Preguntes extretes: ${questions.length}`);

  // Calcular estadístiques
  const correctAnswers = questions.filter((q) => q.isCorrect).length;
  const totalQuestions = questions.length;

  // Construir allQuestions amb el format esperat
  const allQuestions = questions.map((q) => ({
    questionNumber: q.questionNumber,
    category: "", // Eliminat, ja no s'utilitza
    questionText: q.questionText, // IMPORTANT: ha de coincidir amb el model Dart
    isCorrect: q.isCorrect,
    userAnswer: q.userAnswer,
    correctAnswer: q.correctAnswer,
  }));

  // Construir conflictiveQuestions a partir de les preguntes incorrectes
  // Format esperat per updateSeasonTracking: questionNumber, category, reason
  const conflictiveQuestions = questions
    .filter((q) => !q.isCorrect)
    .map((q) => ({
      questionNumber: q.questionNumber,
      questionText: q.questionText,
      userAnswer: q.userAnswer || "",
      correctAnswer: q.correctAnswer,
      explanation: "", // El PDF no conté explicacions
      category: "Reglament", // Categoria per defecte per tests teòrics
      reason: q.questionText, // Utilitzem el text de la pregunta com a motiu
    }));

  logger.info(`Resultat: ${correctAnswers}/${totalQuestions} correctes`);
  logger.info(`Preguntes incorrectes: ${questions
    .filter((q) => !q.isCorrect)
    .map((q) => q.questionNumber)
    .join(", ")}`);

  return {
    testName,
    date,
    score,
    timeSpentMinutes,
    totalQuestions,
    correctAnswers,
    allQuestions,
    conflictiveQuestions,
  };
}

/**
 * Extreu el nom del test
 */
function extractTestName(text: string): string {
  // Buscar patró "Q2501-Test de Regles..." o similar
  const match = text.match(/Q\d{4}-[^\n]+/);
  if (match) {
    return match[0].trim();
  }
  return "Test sense nom";
}

/**
 * Extreu la data del test
 */
function extractDate(text: string): string {
  // Buscar "Completat el" seguit de la data
  // Format: "dimarts, 14 octubre 2025"
  const match = text.match(
    /Completat el\s+\w+,\s*(\d{1,2})\s+(\w+)\s+(\d{4})/i
  );
  if (match) {
    const day = match[1].padStart(2, "0");
    const monthName = match[2].toLowerCase();
    const year = match[3];

    const months: {[key: string]: string} = {
      "gener": "01", "febrer": "02", "març": "03", "abril": "04",
      "maig": "05", "juny": "06", "juliol": "07", "agost": "08",
      "setembre": "09", "octubre": "10", "novembre": "11", "desembre": "12",
    };

    const month = months[monthName] || "01";
    return `${year}-${month}-${day}`;
  }
  return new Date().toISOString().split("T")[0];
}

/**
 * Extreu la puntuació del test
 */
function extractScore(text: string): number {
  // IMPORTANT: pdf-parse pot eliminar espais entre etiqueta i valor
  // Exemple real: "Qualificació8,8 sobre 10,0 (88%)" (sense espai!)

  // Buscar "Qualificació[espai opcional]X,X sobre 10"
  const match = text.match(/Qualificació\s*(\d+)[,.](\d+)\s+sobre\s+10/i);
  if (match) {
    const score = parseFloat(`${match[1]}.${match[2]}`);
    logger.info(`Score extret de Qualificació: ${score}`);
    return score;
  }

  // Alternativa: buscar "Notes[espai opcional]X,X/Y,Y"
  // Exemple real: "Notes22,0/25,0"
  const altMatch = text.match(/Notes\s*(\d+)[,.](\d+)\/(\d+)[,.]?(\d*)/i);
  if (altMatch) {
    const correct = parseFloat(`${altMatch[1]}.${altMatch[2]}`);
    const totalInt = parseInt(altMatch[3], 10);
    const totalDec = altMatch[4] ? parseInt(altMatch[4], 10) : 0;
    const total = parseFloat(`${totalInt}.${totalDec}`);
    const score = (correct / total) * 10;
    logger.info(`Score calculat des de Notes: ${correct}/${total} = ${score}`);
    return Math.round(score * 10) / 10; // Arrodonir a 1 decimal
  }

  logger.warn("No s'ha pogut extreure la puntuació");
  return 0;
}

/**
 * Extreu el temps emprat
 */
function extractTimeSpent(text: string): number {
  // IMPORTANT: pdf-parse pot eliminar espais entre etiqueta i valor
  // Exemple real: "Temps emprat49 minuts 10 segons" (sense espai abans del número!)

  // Buscar "Temps emprat[espai opcional]XX minuts"
  const match = text.match(/Temps\s+emprat\s*(\d+)\s+minuts?/i);
  if (match) {
    const minutes = parseInt(match[1], 10);
    logger.info(`Temps emprat extret: ${minutes} minuts`);
    return minutes;
  }

  // Alternativa: buscar només el número immediatament després de "Temps emprat"
  const altMatch = text.match(/Temps\s+emprat\s*(\d+)/i);
  if (altMatch) {
    const minutes = parseInt(altMatch[1], 10);
    logger.info(`Temps emprat extret (alt): ${minutes} minuts`);
    return minutes;
  }

  logger.warn("No s'ha pogut extreure el temps emprat");
  return 0;
}

/**
 * Extreu totes les preguntes del text
 */
function extractQuestions(text: string): ParsedQuestion[] {
  const questions: ParsedQuestion[] = [];
  const seenQuestionNumbers = new Set<number>();

  // IMPORTANT: Eliminar la secció de navegació del qüestionari
  // Aquesta secció conté "Pregunta X Aquesta pàgina" i crea duplicats
  const navigationIndex = text.indexOf("Navegació pel qüestionari");
  const cleanText = navigationIndex > 0 ?
    text.substring(0, navigationIndex) : text;

  logger.info(`Text net (sense navegació): ${cleanText.length} chars`);

  // Dividir el text per preguntes
  // Cada pregunta comença amb "Pregunta X" seguit de newline
  // Patró: "Pregunta X\n" on X és un número
  const questionBlocks = cleanText.split(/(?=Pregunta\s+\d+\s*\n)/);

  for (const block of questionBlocks) {
    // Verificar que és un bloc de pregunta vàlid
    const questionNumMatch = block.match(/^Pregunta\s+(\d+)\s*\n/);
    if (!questionNumMatch) continue;

    const questionNumber = parseInt(questionNumMatch[1], 10);

    // Evitar duplicats
    if (seenQuestionNumbers.has(questionNumber)) {
      continue;
    }

    // DETERMINÍSTIC: Buscar "Puntuació X,X sobre 1,0"
    const punctuationMatch = block.match(
      /Puntuació\s+(\d+)[,.](\d+)\s+sobre\s+1[,.]0/i
    );

    // Si no té puntuació, no és un bloc de pregunta vàlid
    if (!punctuationMatch) {
      continue;
    }

    const punctuation = `${punctuationMatch[1]},${punctuationMatch[2]} sobre 1,0`;

    // DETERMINÍSTIC: isCorrect es basa NOMÉS en la puntuació
    const isCorrect = punctuationMatch[1] === "1";

    // Extreure el text de la pregunta
    const questionText = extractQuestionText(block);

    // Extreure la resposta correcta
    const correctAnswer = extractCorrectAnswer(block);

    // Extreure la resposta de l'usuari
    const userAnswer = extractUserAnswer(block);

    // Només afegir si tenim contingut vàlid
    if (questionText || correctAnswer) {
      seenQuestionNumbers.add(questionNumber);
      questions.push({
        questionNumber,
        questionText,
        punctuation,
        isCorrect,
        userAnswer,
        correctAnswer,
      });
    }
  }

  // Ordenar per número de pregunta
  questions.sort((a, b) => a.questionNumber - b.questionNumber);

  logger.info(`Preguntes vàlides trobades: ${questions.length}`);

  return questions;
}

/**
 * Extreu el text de la pregunta
 */
function extractQuestionText(block: string): string {
  // L'estructura és senzilla:
  // "Text de la pregunta\n[ENUNCIAT]\n\n[OPCIONS]" o
  // "Text de la pregunta\n[ENUNCIAT acabat en . o ?]\n[OPCIONS]"

  const match = block.match(
    /Text de la pregunta\s*\n([\s\S]*?)(?=\nRetroacció)/i
  );

  if (!match) {
    logger.warn("No s'ha trobat 'Text de la pregunta' al bloc");
    return "";
  }

  const fullContent = match[1].trim();

  // Estratègia 1: Si hi ha línia buida, l'enunciat és tot abans de la línia buida
  const emptyLineIndex = fullContent.indexOf("\n\n");
  if (emptyLineIndex > 0) {
    const enunciat = fullContent
      .substring(0, emptyLineIndex)
      .replace(/\n/g, " ")
      .replace(/\s+/g, " ")
      .trim();

    logger.info(`QuestionText (línia buida): ${enunciat.substring(0, 60)}...`);
    return enunciat;
  }

  // Estratègia 2: L'enunciat acaba quan trobem una línia que acaba en . o ?
  // i la següent línia és una opció (comença amb majúscula i és una frase diferent)
  const lines = fullContent.split("\n");
  const enunciatLines: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    enunciatLines.push(line);

    // Si la línia acaba en . o ? pot ser el final de l'enunciat
    if (line.endsWith(".") || line.endsWith("?")) {
      // Mirar si la següent línia sembla una opció
      // Les opcions són frases independents que no continuen l'enunciat
      const nextLine = lines[i + 1]?.trim();
      if (nextLine && !nextLine.startsWith("-")) {
        // Hem trobat el final de l'enunciat
        break;
      }
    }
  }

  const enunciat = enunciatLines.join(" ").replace(/\s+/g, " ").trim();
  logger.info(`QuestionText: ${enunciat.substring(0, 60)}...`);
  return enunciat;
}

/**
 * Extreu la resposta correcta
 */
function extractCorrectAnswer(block: string): string {
  // Buscar "La resposta correcta és:" seguit del text
  // Pot ocupar múltiples línies fins a la següent pregunta o final del bloc
  const match = block.match(
    /La resposta correcta [eé]s:\s*([\s\S]*?)(?=\nPregunta\s+\d|\nAcaba la revisió|$)/i
  );
  if (match) {
    // Netejar: unir línies i eliminar espais extra
    return match[1]
      .trim()
      .replace(/\n+/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }
  return "";
}

/**
 * Extreu la resposta de l'usuari (la marcada amb ●)
 */
function extractUserAnswer(block: string): string | null {
  // Buscar el patró: ● seguit del text de la resposta (pot ser multilínia)
  // El cercle ple (●) indica l'opció seleccionada per l'usuari
  const lines = block.split("\n");
  let foundMarker = false;
  const answerParts: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Detectar el marcador de selecció (cercle ple)
    if (line === "●" || line.startsWith("●")) {
      foundMarker = true;
      // Si el marcador té text a la mateixa línia
      const textAfterMarker = line.replace(/^●\s*/, "").trim();
      if (textAfterMarker) {
        answerParts.push(textAfterMarker);
      }
      continue;
    }

    // Si hem trobat el marcador, recollim el text fins al següent cercle o Retroacció
    if (foundMarker) {
      // Aturar si trobem un altre cercle (nova opció) o Retroacció
      if (line === "○" || line.startsWith("○") ||
          line.startsWith("Retroacció") || line.startsWith("Retroaccio")) {
        break;
      }
      if (line) {
        answerParts.push(line);
      }
    }
  }

  if (answerParts.length > 0) {
    return answerParts.join(" ").replace(/\s+/g, " ").trim();
  }

  return null;
}

// ============================================================================
// VERTEX AI PER INFORMES (mantenim per informes que són més complexos)
// ============================================================================

/**
 * Extreu dades d'un INFORME utilitzant Vertex AI (Gemini)
 * Nota: Els tests es processen amb parser determinístic
 */
async function extractDataWithVertexAI(
  base64Pdf: string
// eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any> {
  const vertexAI = new VertexAI({
    project: "el-visionat",
    location: "us-central1",
  });

  const model = vertexAI.getGenerativeModel({
    model: "gemini-2.0-flash-lite-001",
  });

  // Nota: Només s'utilitza per informes, els tests es processen amb parser determinístic
  const prompt = getReportExtractionPrompt();

  logger.info("Cridant Vertex AI (Gemini)...");

  const result = await model.generateContent({
    contents: [
      {
        role: "user",
        parts: [
          {
            inlineData: {
              data: base64Pdf,
              mimeType: "application/pdf",
            },
          },
          {
            text: prompt,
          },
        ],
      },
    ],
  });

  const response = result.response;
  const text = response.candidates?.[0]?.content?.parts?.[0]?.text || "";

  logger.info("Resposta rebuda de Gemini");

  // Extreure JSON del markdown code block si cal
  let cleanJson = text.trim();
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
  "evaluator": "Codi i nom complet de l'informador",
  "finalGrade": "OPTIM" | "ACCEPTABLE" | "MILLORABLE" | "NO_SATISFACTORI",
  "categories": [
    {
      "categoryName": "Nom de la categoria",
      "grade": "OPTIM" | "ACCEPTABLE" | "MILLORABLE" | "NO_SATISFACTORI",
      "description": "Comentaris o buit si no n'hi ha"
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

IMPORTANT - REGLES DE NORMALITZACIÓ DE GRADES:
- El camp "grade" NOMÉS pot tenir aquests valors exactes: "OPTIM", "ACCEPTABLE", "MILLORABLE", "NO_SATISFACTORI"
- Aquestes són les 4 categories de valoració (de millor a pitjor):
  * OPTIM: Coneix el criteri i és consistent amb les seves valoracions
  * ACCEPTABLE: Acostuma a encertar però es detecten alguns errors poc importants
  * MILLORABLE: Alterna encerts i errors
  * NO_SATISFACTORI: És irregular i desconeix el criteri
- Normalitza tots els valors del PDF a aquests formats:
  * "ÒPTIM" o "ÒPTIMA" o "OPTIMA" → "OPTIM"
  * "ACCEPTABLE" → "ACCEPTABLE"
  * "MILLORABLE" → "MILLORABLE"
  * "NO SATISFACTORI" o "NO_SATISFACTORI" o qualsevol altre negatiu → "NO_SATISFACTORI"
- SEMPRE utilitza ASCII normal sense accents ni caràcters especials per als valors de "grade"

ALTRES REGLES:
- La data ha de ser en format YYYY-MM-DD
- El finalGrade és la valoració global que apareix al PDF (normalment al principi)
- Inclou TOTES les categories que apareixen al PDF, no només les que tenen descripció
- Els improvementPoints són només els aspectes amb "MILLORABLE" o "ACCEPTABLE" que necessiten millora
- El camp "evaluator" ha de contenir NOMÉS el camp "Informador" del PDF (exemple: "1302 - ABRAHAM HORMIGO CASELLES"), NO l'àrbitre avaluat
- Si una categoria no té descripció, usa cadena buida ""
- NO afegeixis explicacions, només retorna el JSON`;
}

// Nota: Els tests ara es processen amb parser determinístic (parseTestPdfDeterministic)
// No es necessita prompt de Gemini per tests

/**
 * Normalitza el valor de grade a un dels valors vàlids
 * Categories (de millor a pitjor): OPTIM, ACCEPTABLE, MILLORABLE, NO_SATISFACTORI
 */
function normalizeGrade(grade: string): string {
  const normalized = grade
    .toUpperCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Elimina accents
    .trim();

  if (normalized.includes("OPTIM")) return "OPTIM";
  if (normalized.includes("ACCEPTABLE")) return "ACCEPTABLE";
  if (normalized.includes("MILLORABLE")) return "MILLORABLE";
  if (normalized.includes("NO") && normalized.includes("SATISFACTORI")) return "NO_SATISFACTORI";

  return "NO_SATISFACTORI";
}

/**
 * Guarda un informe a Firestore
 */
async function saveReportToFirestore(
  userId: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  data: any
): Promise<void> {
  const db = admin.firestore();

  // Normalitzar categories
  const categories = (data.categories || []).map(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (cat: any) => ({
      categoryName: cat.categoryName || "",
      grade: normalizeGrade(cat.grade || ""),
      description: cat.description || "",
    })
  );

  const reportData = {
    userId: userId,
    date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
    competition: data.competition || "",
    teams: data.teams || "",
    evaluator: data.evaluator || "",
    finalGrade: normalizeGrade(data.finalGrade || ""),
    categories: categories,
    improvementPoints: data.improvementPoints || [],
    comments: data.comments || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("reports").add(reportData);

  logger.info("Informe guardat a Firestore");
}

/**
 * Guarda un test a Firestore (les dades ja vénen processades del parser determinístic)
 */
async function saveTestToFirestore(
  userId: string,
  data: ParsedTestData
): Promise<void> {
  const db = admin.firestore();

  const testData = {
    userId: userId,
    testName: data.testName,
    date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
    isTheoretical: true,
    score: data.score,
    timeSpentMinutes: data.timeSpentMinutes,
    totalQuestions: data.totalQuestions,
    correctAnswers: data.correctAnswers,
    allQuestions: data.allQuestions,
    conflictiveQuestions: data.conflictiveQuestions,
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

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
  // Acumulem el total de preguntes i les fallades per calcular la taxa d'error real
  const weakAreasMap = new Map<string, {
    totalQuestions: number;
    incorrectAnswers: number;
    topics: Set<string>;
    lastTest: Date;
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

    // Obtenir el total de preguntes del test
    const totalTestQuestions = test.totalQuestions || 0;
    const incorrectCount = (test.conflictiveQuestions || []).length;

    // Si no hi ha preguntes fallades, no afegim àrea feble
    if (incorrectCount === 0) return;

    // Utilitzem "Reglament" com a categoria per defecte per tests teòrics
    const category = "Reglament";
    const existing = weakAreasMap.get(category);

    // Recollir els temes conflictius (textos de les preguntes fallades)
    const topics: string[] = [];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (test.conflictiveQuestions || []).forEach((q: any) => {
      topics.push(q.reason || q.questionText || "Error sense especificar");
    });

    if (existing) {
      existing.totalQuestions += totalTestQuestions;
      existing.incorrectAnswers += incorrectCount;
      topics.forEach((t) => existing.topics.add(t));
      if (testDate > existing.lastTest) {
        existing.lastTest = testDate;
      }
    } else {
      weakAreasMap.set(category, {
        totalQuestions: totalTestQuestions,
        incorrectAnswers: incorrectCount,
        topics: new Set(topics),
        lastTest: testDate,
      });
    }
  });

  const testWeakAreas = Array.from(weakAreasMap.entries()).map(
    ([category, data]) => ({
      category,
      totalQuestions: data.totalQuestions,
      incorrectAnswers: data.incorrectAnswers,
      errorRate: (data.incorrectAnswers / data.totalQuestions) * 100,
      conflictiveTopics: Array.from(data.topics),
      lastTest: admin.firestore.Timestamp.fromDate(data.lastTest),
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

/**
 * Trigger que s'executa quan s'elimina un informe
 * Recalcula el tracking de millores per actualitzar el Material d'Estudi
 */
export const onReportDeleted = onDocumentDeleted(
  {
    document: "reports/{reportId}",
    region: "europe-west1",
  },
  async (event) => {
    const deletedReport = event.data?.data();

    if (!deletedReport) {
      logger.warn("No s'ha pogut obtenir les dades de l'informe eliminat");
      return;
    }

    const userId = deletedReport.userId;

    if (!userId) {
      logger.warn("L'informe eliminat no tenia userId");
      return;
    }

    logger.info(`Informe eliminat per usuari ${userId}, recalculant tracking...`);

    try {
      await updateSeasonTracking(userId);
      logger.info("Tracking recalculat correctament després d'eliminar informe");
    } catch (error) {
      logger.error("Error recalculant tracking després d'eliminar informe:", error);
    }
  }
);

/**
 * Trigger que s'executa quan s'elimina un test
 * Recalcula el tracking per actualitzar les àrees febles
 */
export const onTestDeleted = onDocumentDeleted(
  {
    document: "tests/{testId}",
    region: "europe-west1",
  },
  async (event) => {
    const deletedTest = event.data?.data();

    if (!deletedTest) {
      logger.warn("No s'ha pogut obtenir les dades del test eliminat");
      return;
    }

    const userId = deletedTest.userId;

    if (!userId) {
      logger.warn("El test eliminat no tenia userId");
      return;
    }

    logger.info(`Test eliminat per usuari ${userId}, recalculant tracking...`);

    try {
      await updateSeasonTracking(userId);
      logger.info("Tracking recalculat correctament després d'eliminar test");
    } catch (error) {
      logger.error("Error recalculant tracking després d'eliminar test:", error);
    }
  }
);
