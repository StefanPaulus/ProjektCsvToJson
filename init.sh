#!/bin/bash
echo "Erstelle S3-Buckets..."
aws s3 mb s3://mein-csv-input-bucket
aws s3 mb s3://mein-json-output-bucket

echo "Erstelle Lambda-Funktion..."
zip -r lambda.zip index.js node_modules
aws lambda create-function --function-name CsvToJsonConverter \
--runtime nodejs18.x \
--role arn:aws:iam::<AWS_ACCOUNT_ID>:role/<LAMBDA_ROLE> \
--handler index.handler \
--zip-file fileb://lambda.zip

echo "Konfiguriere S3-Trigger für Lambda..."
aws s3api put-bucket-notification-configuration --bucket mein-csv-input-bucket \
--notification-configuration '{
     "LambdaFunctionConfigurations": [
        {
            "LambdaFunctionArn": "arn:aws:lambda:us-east-1:577194944584:function:CsvToJsonConverter",
            "Events": ["s3:ObjectCreated:*"]
        }
    ]
}'

echo "Fertig!"
