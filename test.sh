#!/bin/bash

set -e  # Beendet das Skript bei einem Fehler

# Variablen für AWS-Konfiguration
AWS_ACCOUNT_ID="577194944584"  # Deine AWS-Account-ID
LAMBDA_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/LabRole"  # Deine LabRole
REGION="us-east-1"
INPUT_BUCKET="mein-csv-input-bucket"
OUTPUT_BUCKET="mein-json-output-bucket"
LAMBDA_NAME="CsvToJsonConverter"

echo "📂 Erstelle S3-Buckets..."
aws s3 mb s3://$INPUT_BUCKET || echo "⚠️ Bucket $INPUT_BUCKET existiert bereits."
aws s3 mb s3://$OUTPUT_BUCKET || echo "⚠️ Bucket $OUTPUT_BUCKET existiert bereits."

# Test-CSV-Datei erstellen
TEST_CSV="test.csv"
echo "Erstelle Test-CSV-Datei..."
echo -e "name,age,city\nAlice,30,New York\nBob,25,San Francisco" > $TEST_CSV

# Lambda ZIP-Datei erstellen
echo "📦 Erstelle Lambda ZIP..."
zip -r lambda.zip index.js node_modules

# Lambda-Funktion erstellen oder aktualisieren
echo "🚀 Erstelle oder aktualisiere Lambda-Funktion..."
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

# Lambda-Berechtigungen für den S3-Trigger hinzufügen
echo "🔑 Füge Berechtigung für den S3-Trigger hinzu..."
aws lambda add-permission --function-name $LAMBDA_NAME \
--statement-id s3invoke \
--action "lambda:InvokeFunction" \
--principal s3.amazonaws.com \
--source-arn arn:aws:s3:::$INPUT_BUCKET || echo "⚠️ Berechtigung existiert bereits."

# S3-Trigger für Lambda konfigurieren
echo "🔄 Konfiguriere S3-Trigger für Lambda..."
aws s3api put-bucket-notification-configuration --bucket $INPUT_BUCKET \
--notification-configuration "{
     \"LambdaFunctionConfigurations\": [
        {
            \"LambdaFunctionArn\": \"arn:aws:lambda:$REGION:$AWS_ACCOUNT_ID:function:$LAMBDA_NAME\",
            \"Events\": [\"s3:ObjectCreated:*\"]
        }
    ]
}"

# Test-CSV hochladen
echo "⬆️ Lade Test-CSV hoch..."
aws s3 cp $TEST_CSV s3://$INPUT_BUCKET/

# Warten auf die JSON-Erstellung
echo "⏳ Warte, bis die JSON-Datei im Output-Bucket erscheint..."
attempts=0
while [ $attempts -lt 10 ]; do
    if aws s3 ls s3://$OUTPUT_BUCKET/test.json >/dev/null 2>&1; then
        echo "✅ JSON-Datei gefunden!"
        break
    fi
    sleep 3
    ((attempts++))
done

# JSON-Datei herunterladen und anzeigen
if aws s3 ls s3://$OUTPUT_BUCKET/test.json >/dev/null 2>&1; then
    echo "⬇️ Lade JSON herunter..."
    aws s3 cp s3://$OUTPUT_BUCKET/test.json test.json
    echo "📜 Inhalt der JSON-Datei:"
    cat test.json
else
    echo "❌ Fehler: JSON-Datei wurde nicht erstellt! Überprüfe die Lambda-Funktion."
fi

echo "✅ Fertig!"
