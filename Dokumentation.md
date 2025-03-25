# Csv2Json-Service Dokumentation

## 1. Einführung

### 1.1 Projektziel
Ziel dieses Projekts ist es, einen Cloud-Service zu entwickeln, der CSV-Dateien automatisch in JSON-Dateien konvertiert. Der Service nutzt AWS S3-Buckets und AWS Lambda-Funktionen und wird vollständig im AWS Learner-Lab bereitgestellt.

### 1.2 Technische Anforderungen
- **CSV zu JSON Konvertierung:** Ein Service, der CSV-Dateien in JSON umwandelt, sobald sie in das S3-In-Bucket hochgeladen werden.
- **Automatisierte Bereitstellung:** Bereitstellung und Inbetriebnahme über ein CLI-Script.
- **Versionierung:** Alle Konfigurationsdateien und der Code sind versioniert und in einem Git-Repository abgelegt.

---

## 2. Systemübersicht

### 2.1 Architektur
Die Architektur des Systems besteht aus den folgenden Komponenten:
- **AWS S3 Buckets:** Ein Input-Bucket für CSV-Dateien und ein Output-Bucket für die JSON-Dateien.
- **AWS Lambda:** Eine Lambda-Funktion, die ausgelöst wird, sobald eine Datei in das Input-Bucket hochgeladen wird und die CSV in JSON konvertiert.
- **Versionierung:** Alle Skripte und Konfigurationsdateien sind in einem Git-Repository gespeichert.

### 2.2 Ablauf der Konvertierung
- Der Benutzer lädt eine CSV-Datei in das Input-Bucket hoch.
- Dies löst eine AWS Lambda-Funktion aus, die die Datei konvertiert und die JSON-Datei im Output-Bucket speichert.

---

## 3. Inbetriebnahme

### 3.1 Vorbereitung
- **AWS-Konto und S3-Buckets:** Erstellen Sie ein AWS-Konto und konfigurieren Sie die notwendigen S3-Buckets.
- **Lambda-Funktion:** Stellen Sie sicher, dass die Lambda-Funktion richtig konfiguriert ist.

### 3.2 Installation
Führen Sie das folgende Skript aus, um alle notwendigen AWS-Komponenten zu erstellen und den Dienst zu installieren:

```bash
./init.sh
```

Dieses Skript:
1. Erstellt die S3-Buckets.
2. Setzt die Lambda-Funktion und deren Berechtigungen auf.
3. Testet die gesamte Konvertierung.

### 3.3 Konfiguration
Ändern Sie die Parameter in der Datei `config.json`, um Anpassungen wie das Delimiter-Zeichen oder spezifische Bucket-Namen vorzunehmen.

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
