# Csv2Json-Service Dokumentation

## 1. Einführung

### 1.1 Projektziel
Es ist Ziel dieses Projekts, einen Cloud-Service zur Verfügung zu stellen, der CSV-Dateien in JSON-Dateien konventiert. Der Service nutzt AWS S3-Buckets und AWS Lambda-Funktionen und wird vollständig im AWS Learner-Lab bereitgestellt.

### 1.2 Technische Anforderungen
- **CSV zu JSON Konvertierung:** Wenn man eine CSV Datei ins Bucket hochlade wird sie in JSON konventiert
- **Automatisierte Bereitstellung:** Bereitstellung über ein CLI-Script.
- **Versionierung:** Versionisierung durch Github
---

## 2. Systemübersicht

### 2.1 Architektur
- **AWS S3 Buckets:** Ein Input-Bucket für CSV-Dateien und ein Output-Bucket für die JSON-Dateien.
- **AWS Lambda:** wird aktiviert wenn man eine CSV-Datei im input bucket hochläd.
- **Versionierung:** versionsverlauf in Github.

### 2.2 Ablauf der Konvertierung
Der Benutzer lädt eine CSV-Datei in das Input-Bucket hoch was wiederum eine AWS Lambda-Funktion aus, die die Datei konvertiert und die JSON-Datei im Output-Bucket speichert.

---

## 3. Inbetriebnahme

### 3.1 Vorbereitung
Wir brauchen Ein Aws Konto und müssen sichergehen ob die Architektur sicher konfiguriert ist

### 3.2 Installation
um die AWS Komponente zu instalieren nussten wir ```./test.sh``` instalieren.

Was macht dieses Skript?

---

### **Variablen definieren**
```bash
AWS_ACCOUNT_ID="577194944584"
LAMBDA_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/LabRole"
REGION="us-east-1"
INPUT_BUCKET="mein-csv-input-bucket"
OUTPUT_BUCKET="mein-json-output-bucket"
LAMBDA_NAME="CsvToJsonConverter"
```
- Speichert folgende werte:
  - **Account-ID** (AWS-Konto)
  - **IAM-Rolle** für Lambda
  - **AWS-Region**
  - **Namen der S3-Buckets**
  - **Lambda-Funktionsname**

---

### **S3-Buckets erstellen**
```bash
aws s3 mb s3://$INPUT_BUCKET || echo "⚠️ Bucket $INPUT_BUCKET existiert bereits."
aws s3 mb s3://$OUTPUT_BUCKET || echo "⚠️ Bucket $OUTPUT_BUCKET existiert bereits."
```
erstellt ein Bucket für Output und einen für input.
Fass es diese schon gibt wird eine warnung ausgegeben

---

### **Test-CSV-Datei erstellen**
```bash
TEST_CSV="test.csv"
echo -e "name,age,city\nAlice,30,New York\nBob,25,San Francisco" > $TEST_CSV
```
Erstellt eine CSV datei als Test

---

### **Lambda ZIP-Datei erstellen**
```bash
zip -r lambda.zip index.js node_modules
```
Zippt den Lambda-Code und die node Module.

---

### ** Lambda-Funktion erstellen oder aktualisieren**
```bash
if aws lambda get-function --function-name $LAMBDA_NAME --region $REGION >/dev/null 2>&1; then
    aws lambda update-function-code --function-name $LAMBDA_NAME --zip-file fileb://lambda.zip --region $REGION
else
    aws lambda create-function --function-name $LAMBDA_NAME \
    --runtime nodejs18.x \
    --role $LAMBDA_ROLE_ARN \
    --handler index.handler \
    --zip-file fileb://lambda.zip \
    --region $REGION
fi
```
Die Lambda Funktion wird je nach dem ob es sie schon gibt aktualisiert oder erstellt

### **Lambda-Funktion für S3-Trigger berechtigen**
```bash
aws lambda add-permission --function-name $LAMBDA_NAME \
--statement-id s3invoke \
--action "lambda:InvokeFunction" \
--principal s3.amazonaws.com \
--source-arn arn:aws:s3:::$INPUT_BUCKET || echo "⚠️ Berechtigung existiert bereits."
```
Der Bucket kriegt hier die Berechtigung, die Lambda-Funktion auszulösen.

---

### **S3-Trigger für Lambda konfigurieren**
```bash
aws s3api put-bucket-notification-configuration --bucket $INPUT_BUCKET \
--notification-configuration "{
     \"LambdaFunctionConfigurations\": [
        {
            \"LambdaFunctionArn\": \"arn:aws:lambda:$REGION:$AWS_ACCOUNT_ID:function:$LAMBDA_NAME\",
            \"Events\": [\"s3:ObjectCreated:*\"]
        }
    ]
}"
```
Sorgt dafür dass wenn eine Datei hochgeladen wird, wird Die Lambda-Funktion ausgelöst.

---

### **Test-CSV-Datei hochladen**
```bash
aws s3 cp $TEST_CSV s3://$INPUT_BUCKET/
```
Lädt die Test-CSV in den Input-Bucket hoch.

---

### **Warten auf die JSON-Datei**
```bash
attempts=0
while [ $attempts -lt 10 ]; do
    if aws s3 ls s3://$OUTPUT_BUCKET/test.json >/dev/null 2>&1; then
        echo "✅ JSON-Datei gefunden!"
        break
    fi
    sleep 3
    ((attempts++))
done
```
Wartet bis zu 30 Sekunden auf die JSON-Datei im Output-Bucket.

---

### **JSON-Datei herunterladen und anzeigen**
```bash
if aws s3 ls s3://$OUTPUT_BUCKET/test.json >/dev/null 2>&1; then
    echo "⬇️ Lade JSON herunter..."
    aws s3 cp s3://$OUTPUT_BUCKET/test.json test.json
    echo "📜 Inhalt der JSON-Datei:"
    cat test.json
else
    echo "❌ Fehler: JSON-Datei wurde nicht erstellt! Überprüfe die Lambda-Funktion."
fi
```
falls es funktioniert hat wird die JSON Datei hochgeladen

---

## 4. Git-Repository

### 4.1 Struktur des Repositories


| **Dateiname**         | **Beschreibung** |
|----------------------|----------------|
| `node_modules/`      | Enthält installierte Node.js-Abhängigkeiten. |
| `Dokumentation.md`   | Dokumentation des Projekts.|
| `README.md`         | Allgemeine Projektbeschreibung mit Nutzungshinweisen. |
| `index.js`          | Extrahier und C¨Konventiert die CSV Datei |
| `init.sh`          | Shell-Skript zur Initialisierung oder Einrichtung der Umgebung. |
| `lambda.zip`       | Bereitstellung einer AWS Lambda-Funktion. |
| `package-lock.json` | Bildet die instalierte npm-Pakete ab. |
| `package.json`      | Enthält Metadaten. |
| `test.csv`         | Testdatei im CSV-Format. |
| `test.json`        | Testdatei im JSON-Format. |
| `test.sh`          | Shell-Skript für Tests oder Automatisierungsprozesse. |



---

## 5. Test und Protokollierung

### 5.1 Testfälle
Der Test stellt stellt sicher das CSV Dateien Wirklich in JSON Konventiert werden

### 5.2 Testprotokolle und Screenshots

![Test-1](./Test_1.jpg)

![Test-2](./Test_2.jpg)

![Test-3](./Test_3A.jpg)

![Test-4](./Test_4.jpg)

![Test-5](./Test_5.jpg)

---

## 6. Konvertierungsfunktion

### 6.1 Funktionsweise der Konvertierung
Die Konventierung wird von einer Javascript Datei `Index.js` durchgeführt.

#### `Index.js`
```js
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
```

#### Beispiel für eine CSV-Datei:
```csv
name,age,city
Alice,30,New York
Bob,25,San Francisco
Charlie,35,Boston
David,40,Los Angeles
Eva,22,Chicago
Frank,29,Miami
Grace,31,Seattle
Hannah,28,Austin
Ivy,24,Denver
Jack,26,Washington
```

#### Beispiel für das JSON-Ergebnis:
```json
[{"name":"Alice","age":"30","city":"New York"},{"name":"Bob","age":"25","city":"San Francisco"},{"name":"Charlie","age":"35","city":"Boston"},{"name":"David","age":"40","city":"Los Angeles"},{"name":"Eva","age":"22","city":"Chicago"},{"name":"Frank","age":"29","city":"Miami"},{"name":"Grace","age":"31","city":"Seattle"},{"name":"Hannah","age":"28","city":"Austin"},{"name":"Ivy","age":"24","city":"Denver"},{"name":"Jack","age":"26","city":"Washington"}]
```

---

## 7. Automatisierung

### 7.1 Automatisierungs-Skripte
- **init.sh:** Installiert alle benötigten AWS-Komponenten.
- **test.sh:** Lädt automatisch eine CSV-Datei hoch und überprüft die Konvertierung.


---

## 8. Reflexion
### Ken
Da ich in den Blöcken in denen wir dieses Projekt gamacht haben krank war konnte habe ich hauptzächlich ausserhalb der Schulzeit daran gearbeitet. Jedoch konnte ich beim zweiten Block mithelfen per Teams-call. Ich habe hauptzächlich beim Bugfixen geholfen per pair programming (entweder durch shared screen in Teams oder durch's physisched mitschauen) und die jeweiligen Tests überprüft. Ich habe daher imernoch mein bestes versucht hilfreich zu sein und beim Projekt etwas beizutragen.

### Stefan

### Burim


---

## 9. Quellen und Referenzen
- **M346-Projekt-CsvToJson-2025 PDF:** [M346-Projekt-CsvToJson-2025](https://moodle4.ksb-web.ch/pluginfile.php/10076/mod_resource/content/1/M346-Projekt-CsvToJson-2025.pdf)

---

## 10. Anhang

### 10.1 Bilder
- In der Shell der Ubuntu Maschiene
- Aws Learner Lab
