// Script to convert normalized_questions.json to CSV for manual editing
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const INPUT_FILE = path.join(__dirname, 'normalized_questions.json');
const OUTPUT_FILE = path.join(__dirname, 'questions_for_review.csv');

interface NormalizedQuestion {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  source: string;
  ruleNumber: number;
  articleNumber: number;
  articleTitle: string;
  caseNumber: string | null;
  active: boolean;
  explanation: string;
}

function escapeCsv(text: string): string {
  if (!text) return '';
  // Replace quotes with double quotes and wrap in quotes if it contains comma, quote or newline
  const content = text.replace(/"/g, '""');
  if (content.includes(',') || content.includes('"') || content.includes('\n')) {
    return `"${content}"`;
  }
  return content;
}

function generateCsv() {
  if (!fs.existsSync(INPUT_FILE)) {
    console.error(`❌ No s'ha trobat l'arxiu: ${INPUT_FILE}`);
    process.exit(1);
  }

  const rawData = fs.readFileSync(INPUT_FILE, 'utf-8');
  const questions: NormalizedQuestion[] = JSON.parse(rawData);

  // CSV Header
  const header = [
    'ID',
    'Article',
    'Question',
    'Option A',
    'Option B',
    'Option C',
    'Option D',
    'Correct Index (0=A, 1=B, 2=C, 3=D)',
    'Explanation'
  ].join(',');

  const rows = questions.map(q => {
    return [
      escapeCsv(q.id),
      escapeCsv(`Art. ${q.articleNumber} - ${q.articleTitle}`),
      escapeCsv(q.question),
      escapeCsv(q.options[0] || ''), // Option A
      escapeCsv(q.options[1] || ''), // Option B
      escapeCsv(q.options[2] || ''), // Option C
      escapeCsv(q.options[3] || ''), // Option D
      q.correctIndex,
      escapeCsv(q.explanation)
    ].join(',');
  });

  const content = [header, ...rows].join('\n');
  fs.writeFileSync(OUTPUT_FILE, content, 'utf-8');

  console.log(`✅ CSV generat correctament: ${OUTPUT_FILE}`);
  console.log(`Total preguntes: ${questions.length}`);
}

generateCsv();
