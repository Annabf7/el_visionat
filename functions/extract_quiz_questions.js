const fs = require('fs');
const pdf = require('pdf-parse');
const path = require('path');

const pdfPath = path.resolve(__dirname, '../assets/archivos/INTERPRETACIONS OFICIALS 2024.pdf');
const outputPath = path.resolve(__dirname, 'extracted_questions.json');

if (!fs.existsSync(pdfPath)) {
    console.error('File not found:', pdfPath);
    process.exit(1);
}

const dataBuffer = fs.readFileSync(pdfPath);

pdf(dataBuffer).then(function(data) {
    // Normalize text: remove excessive newlines and spaces
    let text = data.text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    
    // Pattern to find "X-Y Exemple:" ... "Interpretació:"
    // We look for the start of an Example, capture everything until "Interpretació:", then capture everything until the next Example or Article start.
    
    // Regex explanation:
    // (\d+-\d+)\s+Exemple:\s*  -> Captures "17-2 Exemple:" and the ID "17-2"
    // ([\s\S]*?)               -> Captures the content of the example (non-greedy)
    // Interpretació:\s*        -> Marks the start of interpretation
    // ([\s\S]*?)               -> Captures the interpretation content
    // (?=\n\d+-\d+\s+(?:Exemple|Situació)|$|Article \d+) -> Lookahead for the next item or EOF
    
    const regex = /(\d+-\d+)\s+Exemple:\s*([\s\S]*?)Interpretació:\s*([\s\S]*?)(?=\n\d+-\d+\s+(?:Exemple|Situació)|$|Article \d+)/g;
    
    let match;
    const questions = [];
    
    while ((match = regex.exec(text)) !== null) {
        let id = match[1].trim();
        let scenario = match[2].replace(/\s+/g, ' ').trim();
        let interpretation = match[3].replace(/\s+/g, ' ').trim();
        
        // Basic cleanup of the scenario text
        // Sometimes PDF extraction leaves weird artifacts
        
        questions.push({
            id: id,
            category: "Reglament/Interpretacions", 
            question: scenario,
            explanation: interpretation,
            reference: `Art. ${id.split('-')[0]} - Cas ${id}`,
            // We can't auto-generate wrong options easily without AI, 
            // so we'll leave options empty or placeholder for now.
            options: [], 
            correctOptionIndex: 0,
            active: true
        });
    }

    console.log(`Extracted ${questions.length} questions.`);
    
    fs.writeFileSync(outputPath, JSON.stringify(questions, null, 2));
    console.log(`Saved to ${outputPath}`);
});
