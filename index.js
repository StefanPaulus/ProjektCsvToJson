const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const csv = require('csv-parser');

exports.handler = async (event) => {
    const bucketName = event.Records[0].s3.bucket.name;
    const fileKey = event.Records[0].s3.object.key;
    const outputBucket = 'mein-json-output-bucket';
    const outputKey = fileKey.replace('.csv', '.json');

    try {
        const csvData = await s3.getObject({ Bucket: bucketName, Key: fileKey }).promise();
        const jsonData = await parseCsv(csvData.Body);

        await s3.putObject({
            Bucket: outputBucket,
            Key: outputKey,
            Body: JSON.stringify(jsonData),
            ContentType: 'application/json'
        }).promise();

        console.log(`Konvertiert: ${fileKey} -> ${outputKey}`);
    } catch (error) {
        console.error('Fehler:', error);
    }
};

function parseCsv(csvBuffer) {
    return new Promise((resolve, reject) => {
        const results = [];
        require('stream').Readable.from(csvBuffer.toString().split('\n'))
            .pipe(csv())
            .on('data', (data) => results.push(data))
            .on('end', () => resolve(results))
            .on('error', reject);
    });
}
