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
Das Repository enthält die folgenden Dateien:
- `init.sh` – Skript zur Initialisierung der Umgebung.
- `config.json` – Konfigurationsdatei für den CSV-zu-JSON-Konvertierungsservice.
- `README.md` – Diese Dokumentation.
- `lambda_function.py` – Die AWS Lambda-Funktion zur CSV-zu-JSON-Konvertierung.

### 4.2 Versionsverwaltung
Alle Änderungen werden mit Git versioniert. Dies ermöglicht eine nachvollziehbare Dokumentation der Änderungen und des Fortschritts.

---

## 5. Test und Protokollierung

### 5.1 Testfälle
Die Tests stellen sicher, dass der Service wie erwartet funktioniert. Jede CSV-Datei, die hochgeladen wird, sollte korrekt in eine JSON-Datei umgewandelt werden. 

Testprotokoll:
- **Test 1:** Hochladen einer einfachen CSV-Datei → JSON-Datei wird im Output-Bucket gespeichert.
- **Test 2:** Verwendung unterschiedlicher Delimiter-Zeichen → JSON-Datei wird korrekt konvertiert.

### 5.2 Testprotokolle und Screenshots
Die vollständigen Testergebnisse, einschließlich der verwendeten Testdateien und Screenshots, sind als Teil der Dokumentation im Repository abgelegt.

---

## 6. Konvertierungsfunktion

### 6.1 Funktionsweise der Konvertierung
Die Lambda-Funktion `lambda_function.py` liest die CSV-Datei, verarbeitet sie zeilenweise und speichert das Ergebnis als JSON-Datei im Output-Bucket.

#### Beispiel für eine CSV-Datei:
```csv
name,email,age
John Doe,john@example.com,29
Jane Smith,jane@example.com,34
```

#### Beispiel für das JSON-Ergebnis:
```json
[
  {
    "name": "John Doe",
    "email": "john@example.com",
    "age": 29
  },
  {
    "name": "Jane Smith",
    "email": "jane@example.com",
    "age": 34
  }
]
```

---

## 7. Automatisierung

### 7.1 Automatisierungs-Skripte
- **init.sh:** Installiert alle benötigten AWS-Komponenten.
- **test.sh:** Lädt automatisch eine CSV-Datei hoch und überprüft die Konvertierung.

Beide Skripte arbeiten auch bei mehrfacher Ausführung fehlerfrei.

---

## 8. Reflexion

### 8.1 Positive Aspekte
- **Einfache Installation und Konfiguration:** Der Service kann mit einem einzigen Skript installiert und betrieben werden.
- **Cloud-Integration:** Die Lösung nutzt AWS-Dienste und zeigt, wie leistungsfähig Cloud-Computing sein kann.

### 8.2 Verbesserungspotential
- **Fehlerbehandlung:** Es könnte eine erweiterte Fehlerbehandlung implementiert werden, um verschiedene Fehlerquellen wie fehlerhafte CSV-Dateien oder Berechtigungsprobleme besser zu adressieren.

---

## 9. Quellen und Referenzen
- **AWS Lambda-Dokumentation:** [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- **AWS S3-Dokumentation:** [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- **CSV-zu-JSON-Konvertierung:** [CSV to JSON Converter](https://www.csvjson.com/csv2json)

---

## 10. Anhang

### 10.1 Grafiken und Diagramme
- Diagramm der Systemarchitektur.
- Beispiele für CSV- und JSON-Dateien.
