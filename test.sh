#!/bin/bash
echo "Lade Test-CSV hoch..."
aws s3 cp test.csv s3://mein-csv-input-bucket/

echo "Warte 10 Sekunden..."
sleep 10

echo "Lade JSON herunter..."
aws s3 cp s3://mein-json-output-bucket/test.json test.json

echo "Inhalt der JSON-Datei:"
cat test.json
