# DuckDB Local Demo Environment

Lokale Demo-Umgebung für **PBI_AccountingMeasures** basierend auf [DuckDB](https://duckdb.org/) – keine Cloud, kein Fabric, kein ODBC-Treiber nötig.

## Voraussetzungen

- Python 3.9 oder neuer
- pip

## Installation & Setup

```bash
# 1. In das duckdb-Verzeichnis wechseln
cd duckdb

# 2. Abhängigkeiten installieren
pip install -r requirements.txt

# 3. DuckDB-Datenbank erstellen
python setup_duckdb.py
```

Nach dem Setup liegt die Datei `duckdb/demo.duckdb` im Repository-Ordner.

### Optionaler DB-Pfad

```bash
python setup_duckdb.py --db /pfad/zur/wunsch.duckdb
```

## Parquet-Export (empfohlen für Power BI)

```bash
python export_to_parquet.py
```

Erstellt den Ordner `duckdb/parquet/` mit einer Parquet-Datei pro Tabelle.

## Validierung

```bash
python validate_model.py
```

Prüft:
- Referenzielle Integrität (FK-Checks)
- Bilanz-Gleichgewicht (Aktiva = Passiva)
- P&L-Margen in erwarteten Bereichen

## Tabellenübersicht

| Tabelle                  | Beschreibung                          | Erwartete Zeilen |
|--------------------------|---------------------------------------|-----------------|
| `Dim_Entity`             | Entitäten / Konzernstruktur           | 5               |
| `Dim_Scenario`           | Szenarien (ACT, BUD, FC, PY)          | 4               |
| `Dim_Period`             | Monatliche Perioden (Jan 2024–Dez 2025)| 24             |
| `Dim_Account`            | Kontenplan (P&L + BS)                 | ~70             |
| `Dim_ReportLine`         | Berichtszeilen-Steuertabelle          | 45              |
| `Map_Account_ReportLine` | Konto → Berichtszeile Mapping         | ~120            |
| `Fact_Balance`           | GL-Salden (monatlich)                 | ~15.000         |
| `Fact_ReportLine_Balance`| Voraggregierte Fakten                 | ~3.500          |

## Power BI Desktop anbinden

### Option A: Parquet-Dateien (empfohlen)

1. Parquet-Export ausführen:
   ```bash
   python export_to_parquet.py
   ```
2. Power BI Desktop öffnen
3. **Home → Daten abrufen → Parquet**
4. Für jede der 8 Tabellen die entsprechende `.parquet`-Datei aus `duckdb/parquet/` auswählen
5. Beziehungen im Power BI-Modell prüfen und ggf. manuell erstellen

### Option B: DuckDB ODBC-Treiber

1. DuckDB ODBC-Treiber installieren: <https://duckdb.org/docs/api/odbc/overview>
2. ODBC-Datenquelle einrichten (Windows: ODBC-Datenquellen-Administrator)
   - Treiber: `DuckDB Driver`
   - Datenbank: vollständiger Pfad zu `demo.duckdb`
3. Power BI Desktop: **Home → Daten abrufen → ODBC**
4. Datenquelle auswählen und Tabellen importieren

### Option C: Community Connector

Falls ein offizieller Power BI Connector für DuckDB verfügbar ist, kann dieser direkt verwendet werden. Aktuelle Informationen: <https://duckdb.org/docs/guides/data_viewers/powerbi>

## Beziehungen im Power BI-Modell

Nach dem Import die folgenden Beziehungen prüfen/erstellen:

| Von                             | Nach                        | Kardinalität |
|---------------------------------|-----------------------------|--------------|
| `Fact_Balance[EntityKey]`       | `Dim_Entity[EntityKey]`     | n:1          |
| `Fact_Balance[ScenarioKey]`     | `Dim_Scenario[ScenarioKey]` | n:1          |
| `Fact_Balance[AccountKey]`      | `Dim_Account[AccountKey]`   | n:1          |
| `Fact_Balance[PeriodKey]`       | `Dim_Period[PeriodKey]`     | n:1          |
| `Fact_ReportLine_Balance[EntityKey]`   | `Dim_Entity[EntityKey]`     | n:1 |
| `Fact_ReportLine_Balance[ScenarioKey]` | `Dim_Scenario[ScenarioKey]` | n:1 |
| `Fact_ReportLine_Balance[PeriodKey]`   | `Dim_Period[PeriodKey]`     | n:1 |
| `Fact_ReportLine_Balance[ReportLineKey]` | `Dim_ReportLine[ReportLineKey]` | n:1 |
| `Map_Account_ReportLine[AccountKey]`   | `Dim_Account[AccountKey]`   | n:1 |
| `Map_Account_ReportLine[ReportLineKey]`| `Dim_ReportLine[ReportLineKey]` | n:1 |

## Troubleshooting

| Problem | Lösung |
|---------|--------|
| `ModuleNotFoundError: duckdb` | `pip install -r requirements.txt` ausführen |
| `FileNotFoundError` beim Setup | Script aus dem `duckdb/`-Verzeichnis starten |
| Power BI erkennt Parquet nicht | Power BI Desktop Version ≥ 2.x benötigt; alternativ ODBC verwenden |
| Beziehungen fehlen in Power BI | Beziehungen manuell im Modell erstellen (siehe Tabelle oben) |
| `demo.duckdb` zu groß | Nur `Fact_ReportLine_Balance` in Power BI laden (bereits voraggregiert) |

## Generierte Dateien (nicht im Repo)

Die folgenden Dateien werden zur Laufzeit erstellt und sind in `.gitignore` eingetragen:

- `duckdb/demo.duckdb`
- `duckdb/demo.duckdb.wal`
- `duckdb/parquet/`
