const fs = require('fs');
const pdf = require('pdf-parse');
const path = require('path');

const files = [
    'reglament jurisdiccional 2025_26.pdf',
    'Regles de joc basquet base.pdf'
];

async function peek() {
    for (const file of files) {
        const filePath = path.join(__dirname, '../assets/archivos/', file);
        if (fs.existsSync(filePath)) {
            console.log(`\n--- HEAD of ${file} ---`);
            const buffer = fs.readFileSync(filePath);
            const data = await pdf(buffer);
            console.log(data.text.slice(0, 1000)); // First 1000 chars
        } else {
            console.log(`File not found: ${filePath}`);
        }
    }
}

peek();