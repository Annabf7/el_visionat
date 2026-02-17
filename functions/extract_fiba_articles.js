const fs = require('fs');
const pdf = require('pdf-parse');
const path = require('path');

const pdfPath = path.join(__dirname, '../assets/archivos/INTERPRETACIONS OFICIALS 2024.pdf');

if (!fs.existsSync(pdfPath)) {
    console.error('PDF file not found at:', pdfPath);
    process.exit(1);
}

const dataBuffer = fs.readFileSync(pdfPath);

pdf(dataBuffer).then(function(data) {
    const text = data.text;
    const lines = text.split('\n');

    const structuredArticles = [];
    const seenNumbers = new Set();

    // Regex explanation:
    // ^Article\s+           => Starts with "Article" and whitespace
    // ([0-9]+(?:\/[0-9]+)?) => Captures number, optionally with "/" and another number (e.g., "29/50")
    // (?:\s+-\s*|\s+)       => Separator: either " - " or just whitespace
    // (.+)$                 => Captures the rest as title
    const articleRegex = /^Article\s+([0-9]+(?:\/[0-9]+)?)\s+(?:-\s*)?(.+)$/i;

    lines.forEach(line => {
        const trimmedLine = line.trim();
        const match = trimmedLine.match(articleRegex);
        
        if (match) {
            const articleNum = match[1];
            let articleTitle = match[2].trim();

            // Simple cleanup: remove trailing periods if present
            if (articleTitle.endsWith('.')) {
                articleTitle = articleTitle.slice(0, -1);
            }

            if (!seenNumbers.has(articleNum) && articleTitle.length > 2) {
                seenNumbers.add(articleNum);
                structuredArticles.push({
                    number: articleNum,
                    title: articleTitle
                });
            }
        }
    });

    console.log(JSON.stringify(structuredArticles, null, 2));

}).catch(err => {
    console.error('Error:', err);
});
