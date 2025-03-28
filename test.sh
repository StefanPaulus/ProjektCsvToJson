#!/bin/bash

set -e  # Beendet das Skript bei einem Fehler

# AWS Account ID abrufen
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo "❌ Fehler: AWS Account ID konnte nicht abgerufen werden!"
  exit 1
fi

# AWS Variablen
INPUT_BUCKET="mein-csv-input-bucket"
OUTPUT_BUCKET="mein-json-output-bucket"
LAMBDA_NAME="CsvToJsonConverter"
LAMBDA_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/LabRole"
REGION="us-east-1"

echo "📂 Erstelle S3-Buckets..."
aws s3 mb s3://$INPUT_BUCKET || echo "⚠️ Bucket $INPUT_BUCKET existiert bereits."
aws s3 mb s3://$OUTPUT_BUCKET || echo "⚠️ Bucket $OUTPUT_BUCKET existiert bereits."

# Test-CSV-Datei erstellen
TEST_CSV="test.csv"
echo "Erstelle Test-CSV-Datei..."
echo -e "name,age,city\nAlice,30,New York\nBob,25,San Francisco\nCharlie,35,Boston\nDavid,40,Los Angeles\nEva,22,Chicago\nFrank,29,Miami\nGrace,31,Seattle\nHannah,28,Austin\nIvy,24,Denver\nJack,26,Washington" > $TEST_CSV

# Lambda ZIP-Datei erstellen
echo "📦 Erstelle Lambda ZIP..."
zip -r lambda.zip index.js node_modules

# Prüfen, ob die Lambda-Funktion existiert
EXISTING_LAMBDA=$(aws lambda get-function --function-name $LAMBDA_NAME 2>/dev/null || echo "")

if [ -z "$EXISTING_LAMBDA" ]; then
    echo "🚀 Erstelle Lambda-Funktion..."
    aws lambda create-function --function-name $LAMBDA_NAME \
    --runtime nodejs18.x \
    --role $LAMBDA_ROLE_ARN \
    --handler index.handler \
    --zip-file fileb://lambda.zip \
    --region $REGION
else
    echo "⚠️ Lambda-Funktion existiert bereits – aktualisiere Code..."
    aws lambda update-function-code --function-name $LAMBDA_NAME --zip-file fileb://lambda.zip
fi

# Lambda Berechtigung für S3 erteilen
echo "🔑 Prüfe und füge Lambda-Berechtigungen hinzu..."
aws lambda add-permission --function-name $LAMBDA_NAME \
--statement-id s3invoke \
--action lambda:InvokeFunction \
--principal s3.amazonaws.com \
--source-arn arn:aws:s3:::$INPUT_BUCKET || echo "⚠️ Berechtigung existiert bereits."

# Konfiguriere S3-Trigger für Lambda
echo "🔄 Konfiguriere S3-Trigger für Lambda..."
aws s3api put-bucket-notification-configuration --bucket $INPUT_BUCKET \
--notification-configuration "{
     \"LambdaFunctionConfigurations\": [
        {
            \"LambdaFunctionArn\": \"arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_NAME\",
            \"Events\": [\"s3:ObjectCreated:*\"] 
        }
    ]
}" || echo "⚠️ Fehler beim Konfigurieren der S3-Notification."

echo "⬆️ Lade Test-CSV hoch..."
aws s3 cp $TEST_CSV s3://$INPUT_BUCKET/

echo "⏳ Warte 10 Sekunden, bis die Lambda-Funktion das JSON erstellt..."
sleep 10

echo "⬇️ Lade JSON herunter..."
aws s3 cp s3://$OUTPUT_BUCKET/test.json test.json || echo "⚠️ JSON-Datei nicht gefunden."

echo "📜 Inhalt der JSON-Datei:"
cat test.json || echo "⚠️ Fehler: JSON konnte nicht gelesen werden."

echo "✅ Fertig!"

