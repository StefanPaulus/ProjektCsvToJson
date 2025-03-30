# ProjektCsvToJson

Das Repository enthält ein Bashskript das eine Lambdafunktion und alle ihre erforderlichen bestandteile Initialiesiert um eine csv Datei in ein json-Datei umzuwandeln.

### Voraussetzungen

- AWS CLI installiert und konfiguriert (Credentials nicht vergessen)
- Ein AWS-Account mit Berechtigungen für Lambda und S3

### Skript ausführen

Repository klonen:
```bash
git clone "https://github.com/StefanPaulus/ProjektCsvToJson.git"
```

In Verzeichnis wechseln:
```bash
cd "REPOSITORY_PFAD"

# im normalfall:
cd ProjektCsvToJson
```

Skript ausführen:
```bash
./init.sh
```

Wenn fehlermeldung "permission denied: ./init.sh" erscheint, skript ausführbar machen mit:
```bash
chmod +x init.sh
```

**Repository von:** Burim, Ken und Stefan
