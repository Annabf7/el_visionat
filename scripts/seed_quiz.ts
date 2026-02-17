
import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// -----------------------------------------------------------------------------
// 🧩 Construcció de __dirname en ESM
// -----------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// -----------------------------------------------------------------------------
// ⚙️ Inicialització de Firebase Admin
// -----------------------------------------------------------------------------
// Si existeix la variable d'entorn FIRESTORE_EMULATOR_HOST, l'SDK la farà servir automàticament.
// Sinó, caldrà la clau de servei per producció.

const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log(`🔧 Usant Firestore Emulator a ${process.env.FIRESTORE_EMULATOR_HOST}`);
  admin.initializeApp({ projectId: 'el-visionat' });
} else {
  if (fs.existsSync(serviceAccountPath)) {
    console.log('🔑 Usant serviceAccountKey.json per a connexió real.');
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else {
    console.log('⚠️ No s\'ha trobat serviceAccountKey.json ni l\'emulador.');
    console.log('   Intentant utilitzar Default Application Credentials...');
    admin.initializeApp({ projectId: 'el-visionat' });
  }
}

const db = admin.firestore();

// -----------------------------------------------------------------------------
// 📂 Lectura de l'arxiu JSON Normalitzat
// -----------------------------------------------------------------------------
const JSON_FILE_PATH = path.join(__dirname, 'normalized_questions.json');

interface QuizQuestion {
  id: string;
  category?: string; // Legacy
  question: string;
  explanation?: string;
  options: string[];
  correctOptionIndex: number; // Renamed to map to correctIndex in normalized but kept consistent
  correctIndex?: number;      // Normalized field
  reference?: string;
  active: boolean;
  difficulty?: number;
  tags?: string[];
  
  // New fields
  source?: string;
  ruleNumber?: number;
  articleNumber?: number;
  articleTitle?: string;
  caseNumber?: string | null;
}

function normalizeCategory(cat: string): string {
  // ... existing function ...
  return 'general';
}

async function seedQuiz() {
  if (!fs.existsSync(JSON_FILE_PATH)) {
    console.error(`❌ No s'ha trobat l'arxiu: ${JSON_FILE_PATH}`);
    process.exit(1);
  }


  const rawData = fs.readFileSync(JSON_FILE_PATH, 'utf-8');
  const questions: QuizQuestion[] = JSON.parse(rawData);

  console.log(`📦 S'han llegit ${questions.length} preguntes del fitxer JSON.`);
  console.log(`🚀 Iniciant càrrega a la col·lecció 'quiz_questions'...`);

  const batchSize = 500; // Firestore batch limit
  let batch = db.batch();
  let count = 0;
  let totalUploaded = 0;

  for (const q of questions) {
    // Usem l'ID del JSON com a ID del document si existeix, sinó un de nou
    const docRef = q.id 
      ? db.collection('quiz_questions').doc(q.id) 
      : db.collection('quiz_questions').doc(); // Auto-ID

    // Validació i normalització de dades
    // Si no hi ha opcions, posem l'explicació com a única opció (la correcta) - Mode Edició
    const validOptions = (q.options && q.options.length > 0) ? q.options : [q.explanation || "Sense resposta"];
    
    // Determinar categoria (prioritzar source si existeix, sinó category legacy)
    let categoryString = q.category || q.source || 'general';
    const normalizedCategory = normalizeCategory(categoryString);

    // Mapeig de camps normalitzats
    const correctIdx = (typeof q.correctIndex === 'number') 
        ? q.correctIndex 
        : ((typeof q.correctOptionIndex === 'number') ? q.correctOptionIndex : 0);

    // Preparem l'objecte data assegurant tipus correctes
    const data = {
      ...q,
      category: normalizedCategory, // Legacy support for Flutter enum
      source: q.source || 'general',
      options: validOptions,
      correctOptionIndex: correctIdx,
      active: q.active ?? true, 
      difficulty: q.difficulty ?? 1,
      tags: q.tags ?? [],
      
      // Nous camps normalitzats (si venen del JSON)
      ruleNumber: q.ruleNumber ?? 0,
      articleNumber: q.articleNumber ?? 0,
      articleTitle: q.articleTitle ?? '',
      caseNumber: q.caseNumber || null,
      
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp() 
    };

    batch.set(docRef, data, { merge: true });
    count++;

    if (count >= batchSize) {
      await batch.commit();
      totalUploaded += count;
      console.log(`   ✅ Lot de ${count} preguntes pujat.`);
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
    totalUploaded += count;
    console.log(`   ✅ Últim lot de ${count} preguntes pujat.`);
  }

  console.log(`🎉 Procés finalitzat! Total preguntes processades: ${totalUploaded}`);
}

seedQuiz().catch(console.error);
