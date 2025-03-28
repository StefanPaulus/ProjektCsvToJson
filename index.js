const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const csv = require('csv-parser');
const stream = require('stream');
exports.handler = async (event) => {
    try {
        // 1. Extrahiere Bucket & Datei-Info aus Event
        const bucketName = event.Records[0].s3.bucket.name;
        const fileKey = event.Records[0].s3.object.key;
        const outputBucket = 'mein-json-output-bucket';
        const outputKey = fileKey.replace('.csv', '.json');
        console.log(Empfangenes S3-Event: Bucket=${bucketName}, Datei=${fileKey});
        // 2. CSV-Datei aus S3 abrufen
        const csvData = await s3.getObject({ Bucket: bucketName, Key: fileKey }).promise();
        // 3. CSV in JSON konvertieren
        const jsonData = await parseCsv(csvData.Body);
        // 4. JSON-Daten mit schöner Formatierung (2 Leerzeichen Einrückung) und Zeilenumbrüchen
        const formattedJsonData = JSON.stringify(jsonData, null, 2); // 2 bedeutet 2 Leerzeichen Einrückung
        console.log('Konvertierte JSON-Daten:', formattedJsonData);
        // 5. JSON-Datei in S3 hochladen (mit Formatierung)
        await s3.putObject({
            Bucket: outputBucket,
            Key: outputKey,
            Body: formattedJsonData,  // Formatierte JSON-Daten
            ContentType: 'application/json'
        }).promise();
        console.log(✅ Erfolgreich konvertiert: ${fileKey} -> ${outputKey});
    } catch (error) {
        console.error('❌ Fehler:', error);
    }
};
// ✅ Neue CSV-Parsing-Funktion
function parseCsv(csvBuffer) {
    return new Promise((resolve, reject) => {
        const results = [];
        const readable = new stream.Readable();
        readable._read = () => {}; // Keine neue Datenquelle nötig
        readable.push(csvBuffer);
        readable.push(null); // Stream-Ende signalisieren
        readable
            .pipe(csv())
            .on('data', (data) => results.push(data))
            .on('end', () => resolve(results))
            .on('error', reject);
    });
}
