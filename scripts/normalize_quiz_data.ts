
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// -----------------------------------------------------------------------------
// 🗺️ Mapa d'Articles (Extret del PDF Oficial)
// -----------------------------------------------------------------------------
const ARTICLE_TITLES: Record<number, string> = {
  4: "Equips",
  5: "Jugadors: Lesió i assistència",
  7: "Entrenador i primer ajudant d'entrenador: drets i obligacions",
  8: "Temps de joc, tempteig empatat i pròrroga",
  9: "Inici i final d'un quart, una pròrroga o del partit",
  10: "Estat de la pilota",
  12: "Salt entre dos i alternança de possessió",
  13: "Com es juga la pilota",
  14: "Control de la pilota",
  15: "Jugador en acció de tir",
  16: "Cistella: Quan es converteix i el seu valor",
  17: "Servei",
  18: "Temps mort",
  19: "Substitucions", // Afegit manualment per completesa si falta
  23: "Jugador fora de banda i pilota fora de banda",
  24: "Regat",
  25: "Avançament il·legal",
  26: "3 segons",
  27: "Jugador estretament marcat",
  28: "8 segons",
  29: "Rellotge de llançament", // Simplificat de 29/50
  30: "Pilota retornada a pista del darrere",
  31: "Interposició i Interferència",
  33: "Contacte: principis generals",
  34: "Falta personal",
  35: "Falta doble",
  36: "Falta tècnica",
  37: "Falta antiesportiva",
  38: "Falta desqualificant",
  39: "Baralles",
  42: "Situacions especials",
  43: "Tirs lliures",
  44: "Errors rectificables"
};

const INPUT_FILE = path.join(__dirname, '../functions/extracted_questions.json');
const OUTPUT_FILE = path.join(__dirname, 'normalized_questions.json');

interface RawQuestion {
  id: string;
  category: string;
  question: string;
  explanation: string;
  reference: string;
  options: string[];
  correctOptionIndex: number;
  active: boolean;
}

interface NormalizedQuestion {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  source: string;
  ruleNumber: number; // Normalment es dedueix de l'Article
  articleNumber: number;
  articleTitle: string;
  caseNumber: string | null;
  active: boolean;
  explanation: string;
}

// -----------------------------------------------------------------------------
// 🧹 Helpers de Neteja
// -----------------------------------------------------------------------------
function cleanText(text: string): string {
  if (!text) return '';
  return text
    .replace(/\s+/g, ' ') // Espais múltiples -> 1
    .replace(/¬\s*/g, '') // Guions de tall de línia
    .replace(/Octubre de 2024 versió 1\.0a? Interpretacions oficials de les Regles de Joc Página \d+ de \d+/gi, '') // Eliminar peu de pàgina
    .trim();
}

function getArticleTitle(num: number): string {
  return ARTICLE_TITLES[num] || `Article ${num}`;
}

// -----------------------------------------------------------------------------
// 🚀 Main Script
// -----------------------------------------------------------------------------
function normalizeData() {
  if (!fs.existsSync(INPUT_FILE)) {
    console.error(`❌ No s'ha trobat l'arxiu d'entrada: ${INPUT_FILE}`);
    process.exit(1);
  }

  const rawData = fs.readFileSync(INPUT_FILE, 'utf-8');
  const rawQuestions: RawQuestion[] = JSON.parse(rawData);
  const normalizedQuestions: NormalizedQuestion[] = [];

  console.log(`📦 Processant ${rawQuestions.length} preguntes...`);

  let skippedCount = 0;

  for (const q of rawQuestions) {
    // 1. Parse ID (e.g., "17-2")
    const parts = q.id.split('-');
    if (parts.length < 2) {
      console.warn(`⚠️ ID invàlid: ${q.id}. Saltant.`);
      skippedCount++;
      continue;
    }

    const articleNumber = parseInt(parts[0], 10);
    const caseNumber = q.id; // Tot l'ID és el número de cas (ex: 17-2)

    if (isNaN(articleNumber)) {
      console.warn(`⚠️ No es pot extreure article de ${q.id}. Saltant.`);
      skippedCount++;
      continue;
    }

    // 2. Normalització
    const title = getArticleTitle(articleNumber);
    const cleanQ = cleanText(q.question);
    const cleanExp = cleanText(q.explanation);

    // 3. Creació d'objecte normalitzat
    const normQ: NormalizedQuestion = {
      id: q.id,
      question: cleanQ,
      options: q.options.length > 0 ? q.options : [], // Mantenim buit si no n'hi ha
      correctIndex: q.correctOptionIndex || 0,
      source: 'interpretacions', // Font fixa per aquest PDF
      ruleNumber: 0, // TODO: Mapar Articles a Regles (ex: Art 4 -> Regla 2) si cal
      articleNumber: articleNumber,
      articleTitle: title,
      caseNumber: caseNumber,
      active: q.active ?? true,
      explanation: cleanExp
    };

    normalizedQuestions.push(normQ);
  }

  // 4. Guardar resultat
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(normalizedQuestions, null, 2));
  
  console.log(`✅ Normalització completada.`);
  console.log(`   Generat: ${OUTPUT_FILE}`);
  console.log(`   Total: ${normalizedQuestions.length} preguntes.`);
  console.log(`   Saltades: ${skippedCount}`);
}

normalizeData();
