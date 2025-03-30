/**
 * CSV to JSON Converter (AWS Lambda)
 * -----------------------------------
 * Konvertiert eine hochgeladene CSV-Datei aus einem S3-Bucket in eine JSON-Datei
 * und speichert diese in einem anderen S3-Bucket.
 * 
 * Autor: Stefan, Burim und Ken
 * Quellen: 
 * - AWS SDK: https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html
 * - csv-parser: https://www.npmjs.com/package/csv-parser
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const csv = require('csv-parser');
const stream = require('stream');

const DELIMITER = ','; // Anpassbar: ';' oder '\t' für Tab

exports.handler = async (event) => {
    try {
        // Extrahiere Bucket- und Datei-Info aus Event
        const bucketName = event.Records[0].s3.bucket.name;
        const fileKey = event.Records[0].s3.object.key;
        const outputBucket = 'mein-json-output-bucket';
        const outputKey = fileKey.replace('.csv', '.json');

        console.log(`📥 CSV-Datei empfangen: Bucket=${bucketName}, Datei=${fileKey}`);

        // Lade die CSV-Datei aus dem S3-Bucket
        const csvData = await s3.getObject({ Bucket: bucketName, Key: fileKey }).promise();
        if (!csvData.Body) {
            throw new Error("⚠️ Fehler: CSV-Datei konnte nicht geladen werden oder ist leer.");
        }

        // Konvertiere CSV in JSON
        const jsonData = await parseCsv(csvData.Body);
        const formattedJsonData = JSON.stringify(jsonData, null, 2);

        console.log('✅ Konvertierte JSON-Daten:', formattedJsonData);

        // Lade die JSON-Datei in den Output-Bucket hoch
        await s3.putObject({
            Bucket: outputBucket,
            Key: outputKey,
            Body: formattedJsonData,
            ContentType: 'application/json'
        }).promise();

        console.log(`✅ Erfolgreich gespeichert: ${outputKey} in ${outputBucket}`);
    } catch (error) {
        console.error('❌ Fehler:', error);
    }
};

/**
 * Konvertiert einen CSV-Buffer in ein JSON-Array.
 * @param {Buffer} csvBuffer - Der Inhalt der CSV-Datei
 * @returns {Promise<Array>} JSON-Array der Daten
 */
function parseCsv(csvBuffer) {
    return new Promise((resolve, reject) => {
        const results = [];
        const readable = new stream.Readable();
        readable._read = () => {}; // Keine neue Datenquelle nötig
        readable.push(csvBuffer);
        readable.push(null); // Stream-Ende signalisieren

        readable
            .pipe(csv({ separator: DELIMITER })) // Nutzt die Variable DELIMITER
            .on('data', (data) => results.push(data))
            .on('end', () => resolve(results))
            .on('error', reject);
    });
}













