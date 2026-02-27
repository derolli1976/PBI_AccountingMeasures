# PBI AccountingMeasures – P&L Reporting Architecture

> **Skalierbare, wiederverwendbare Architektur für Financial Reporting in
> Power BI / Microsoft Fabric**  
> P&L · Balance Sheet · Cashflow · Working Capital · Statistikkonten

---

## Überblick: Das Zielbild

Dieses Repository liefert eine vollständige Implementierungsbasis für
**Financial Reporting** in Power BI und Microsoft Fabric. Es ist keine
Insellösung für ein einzelnes Reporting-Projekt, sondern ein durchdachtes
**Datenmodell und Architekturmuster**, das sich auf beliebig viele Berichte
und Gesellschaften skalieren lässt.

**Kernprinzip:** Die Berichtslogik steckt in **Daten**, nicht im DAX-Code.
Die Tabelle `Dim_ReportLine` definiert, was jede Zeile eines Berichts ist und
wie sie berechnet wird. Neue Zeilen, neue Berichte und neue Formatierungen
erfordern nur Datenänderungen – kein Code-Update.

**Unterstützte Berichte mit derselben Architektur:**

| ReportType | Bericht |
|---|---|
| `PL` | Profit & Loss Statement |
| `BS` | Balance Sheet / Bilanz |
| `CF` | Cashflow Statement |
| `WC` | Working Capital Report |
| `STAT` | Statistikkonten (FTE, Fläche, Stückzahlen, …) |

---

## Empfohlene Architektur (Schichtenmodell)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 5 – Power BI Frontend                                                │
│   Matrix Visual · Calculation Group · Measures · Slicers                   │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ DAX / Direct Lake
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 4 – Direct Lake Semantic Model                                       │
│   Star Schema · Beziehungen · DAX Measures                                  │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ Delta Tables
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 3 – Fabric Lakehouse / WH  Gold Layer                                │
│   Fakten + Dimensionen als Delta Tables                                     │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ Notebooks / Dataflows / SQL
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 2 – Silver Layer                                                     │
│   Harmonisierung · Währungsumrechnung · Konsolidierung                     │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ ERP-Extrakte
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 1 – Raw / Bronze                                                     │
│   ERP GL-Extrakte · Kontenrahmen · Hierarchien                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

Eine detaillierte Version mit allen Komponenten findet sich in
[`docs/architecture.md`](docs/architecture.md).

---

## Datenmodell (Gold Layer / Semantic Model)

### Star Schema Tabellen

#### `Dim_Entity`

| Spalte | Typ | Beschreibung |
|---|---|---|
| EntityKey | INT | Primärschlüssel |
| EntityName | VARCHAR | Gesellschaftsname |
| Region | VARCHAR | Region / Land |
| Consol_Level | VARCHAR | `LEGAL`, `BU`, `GROUP` |

#### `Dim_Scenario`

| Spalte | Typ | Beschreibung |
|---|---|---|
| ScenarioKey | INT | Primärschlüssel |
| ScenarioName | VARCHAR | `Actual`, `Plan`, `FC`, `LY`, `Budget` |

#### `Fact_Balance`

| Spalte | Typ | Beschreibung |
|---|---|---|
| ScenarioKey | INT | FK → Dim_Scenario |
| EntityKey | INT | FK → Dim_Entity |
| AccountKey | INT | FK → Dim_Account |
| PeriodKey | INT | FK → Dim_Period |
| Amount | DECIMAL | Betrag in Konzernwährung |
| AmountLC | DECIMAL | Betrag in lokaler Währung |

#### `Dim_Account`

| Spalte | Typ | Beschreibung |
|---|---|---|
| AccountKey | INT | Primärschlüssel |
| AccountNo | VARCHAR | Kontonummer |
| AccountName | VARCHAR | Kontobezeichnung |
| L1_Category | VARCHAR | Hierarchiestufe 1 |
| L2_Subcategory | VARCHAR | Hierarchiestufe 2 |
| L3_Detail | VARCHAR | Hierarchiestufe 3 |
| AccountType | VARCHAR | `PL`, `BS`, `STAT` |
| SignConvention | INT | `1` oder `-1` |
| PL_LineItem | VARCHAR | P&L-Zuordnung |
| PL_SortOrder | INT | Reihenfolge im P&L |
| BS_LineItem | VARCHAR | Bilanz-Zuordnung |
| BS_SortOrder | INT | Reihenfolge in der Bilanz |

#### `Dim_Period`

| Spalte | Typ | Beschreibung |
|---|---|---|
| PeriodKey | INT | Primärschlüssel |
| Year | INT | Kalenderjahr |
| Month | INT | Kalendermonat (1–12) |
| Quarter | INT | Quartal (1–4) |
| YearMonth | INT | z. B. `202401` |
| FiscalYear | INT | Geschäftsjahr |
| FiscalPeriod | INT | Buchungsperiode |
| Date | DATE | Erstes Tagesdatum der Periode |

#### `Dim_ReportLine` – **Kern der Lösung**

Steuerungstabelle: beschreibt jede Zeile in jedem Bericht und wie sie
berechnet wird. Details → [`sql/01_Dim_ReportLine.sql`](sql/01_Dim_ReportLine.sql)
und [`docs/architecture.md`](docs/architecture.md).

| Spalte | Beschreibung |
|---|---|
| ReportLineKey | Primärschlüssel |
| ReportType | `PL`, `BS`, `CF`, `WC`, `STAT` |
| LineItem | Anzeigename im Report |
| SortOrder | Zeilenreihenfolge |
| LineType | `DATA`, `CALCULATED`, `PERCENTAGE` |
| CalcFormula | Lesbare Formel (Dokumentation) |
| CalcOperands | JSON: Operanden für Codegenerierung |
| PercentageBase | Bezugsgröße für %-Zeilen |
| IsBold | Fette Schrift (Formatierung) |
| IsSubtotal | Subtotal-Indikator |
| IndentLevel | Einrückungstiefe |
| SignConvention | `1` oder `-1` |
| AccountFilter | Schlüssel für Konto-Mapping |

#### `Map_Account_ReportLine` – Brücke Account → ReportLine

| Spalte | Beschreibung |
|---|---|
| AccountKey | FK → Dim_Account |
| ReportLineKey | FK → Dim_ReportLine |
| MappingWeight | Anteil (Standard: 1.0) |

#### `Fact_ReportLine_Balance` – Voraggregierte Fakten

| Spalte | Beschreibung |
|---|---|
| ReportLineKey | FK → Dim_ReportLine |
| EntityKey | FK → Dim_Entity |
| ScenarioKey | FK → Dim_Scenario |
| PeriodKey | FK → Dim_Period |
| Amount | Voraggregierter Betrag (Konzernwährung) |
| AmountLC | Voraggregierter Betrag (Lokalwährung) |

---

## DAX Measures

### Basis-Measure `[Amount]`

```dax
Amount =
SUMX(
    Fact_ReportLine_Balance,
    Fact_ReportLine_Balance[Amount]
)
```

→ Datei: [`dax/Measures_Base.dax`](dax/Measures_Base.dax)

### Generisches `[LineValue]`-Measure

Das zentrale Measure im Matrix-Visual. Liefert je nach `LineType` den
richtigen Wert:

- **DATA** → direkt aus `Fact_ReportLine_Balance` (via `[Amount]`)
- **CALCULATED** → SWITCH-Block mit expliziten Additionen der Operanden
- **PERCENTAGE** → DIVIDE(Referenzwert, Sales)

```dax
LineValue =
VAR CurrentLine     = SELECTEDVALUE(Dim_ReportLine[LineItem])
VAR CurrentLineType = SELECTEDVALUE(Dim_ReportLine[LineType])
-- ... (vollständige Implementierung in dax/Measures_LineValue.dax)
```

→ Datei: [`dax/Measures_LineValue.dax`](dax/Measures_LineValue.dax)

### Interne Helfer

```dax
_EBIT_internal = Sales + COGS + Selling + G&A + R&D + OtherOpInc + OtherOpExp
_EBT_internal  = _EBIT_internal + InvResult + IntResult
```

→ Datei: [`dax/Measures_Internal_Helpers.dax`](dax/Measures_Internal_Helpers.dax)

### Calculation Group für Zeitvergleiche

Calculation Group **"Variance Analysis"** mit 5 Items:

| Item | Beschreibung |
|---|---|
| Actual | Istwert (SELECTEDMEASURE) |
| Budget | Budget-Szenario |
| Prior Year | Vorjahr (DATEADD −1 YEAR) |
| Δ vs Budget | Absolutabweichung Actual − Budget |
| Δ% vs Budget | Relative Abweichung (Actual − Budget) / \|Budget\| |

→ Datei: [`dax/CalcGroup_TimeIntelligence.dax`](dax/CalcGroup_TimeIntelligence.dax)

---

## Power BI Frontend

### Matrix-Visual Konfiguration

```
Rows:   Dim_ReportLine[LineItem]   (sortiert nach [SortOrder])
Cols:   Calculation Group Items    (Actual · Budget · Δ · Δ%)
Values: [LineValue]                (Absolut- und %-Werte in einer Spalte)
        [Margin %]                 (optional: inline %-Spalte)
```

Visual-Filter: `Dim_ReportLine[ReportType] = "PL"`

### P&L Mockup (Ausschnitt)

```
┌─────────────────────────────┬──────────┬──────────┬──────────┬────────┐
│ P&L Report  Jan–Dec 2024    │  Actual  │  Budget  │    Δ     │   Δ%   │
├─────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ Sales                       │ 100,000  │  95,000  │   5,000  │  5.3%  │
│ Cost of Sales               │  60,000  │  57,000  │   3,000  │  5.3%  │
│ Gross Profit                │  40,000  │  38,000  │   2,000  │  5.3%  │
│ GP %                        │  40.0%   │  40.0%   │          │        │
│   Selling Expenses          │   8,000  │   8,500  │    (500) │ (5.9%) │
│   G&A                       │   5,000  │   5,000  │       -  │  0.0%  │
│   R&D                       │   3,000  │   3,000  │       -  │  0.0%  │
│ SGA                         │  16,000  │  16,500  │    (500) │ (3.0%) │
│ EBIT                        │  25,000  │  22,000  │   3,000  │ 13.6%  │
│ EBIT %                      │  25.0%   │  23.2%   │          │        │
│ D&A                         │   4,000  │   4,000  │       -  │  0.0%  │
│ EBITDA                      │  29,000  │  26,000  │   3,000  │ 11.5%  │
│ Net Income                  │  17,150  │  14,910  │   2,240  │ 15.0%  │
└─────────────────────────────┴──────────┴──────────┴──────────┴────────┘
```

Vollständiges Mockup und Setup-Details → [`docs/visual-setup.md`](docs/visual-setup.md)

---

## Skalierung auf weitere Berichte

| Bericht | ReportType | Vorgehen |
|---|---|---|
| Bilanz | `BS` | `Dim_ReportLine` mit BS-Zeilen befüllen (Seeds in `03_Seed_BS_ReportLines.sql`) |
| Cashflow | `CF` | Neue ReportLines + Konten-Mapping; CALCULATED-Zeilen in `[LineValue]` ergänzen |
| Working Capital | `WC` | Subset der BS-Zeilen oder eigene WC-Zeilen |
| Statistik | `STAT` | Beliebige Kennzahlen (FTE, m², Stück) – gleiche Struktur |

**Entity / Konsolidierung / Szenario-Filter:**

- `Dim_Entity[Consol_Level]`-Slicer → Gesellschaft, Business Unit oder Konzern
- `Dim_Scenario[ScenarioName]`-Slicer → Actual / Plan / FC / Budget
- Calculation Group → Zeitvergleich ohne zusätzliche Measures

---

## Zusammenfassung: Schritt-für-Schritt Vorgehen

| Schritt | Aufgabe | Datei |
|---|---|---|
| 1 | `Dim_Account` pflegen (Kontenrahmen + Mappingflags) | Manuell / ERP-Export |
| 2 | `Dim_ReportLine` anlegen (DDL) | `sql/01_Dim_ReportLine.sql` |
| 3 | P&L-Zeilen einspielen (Seed) | `sql/02_Seed_PL_ReportLines.sql` |
| 4 | BS-Zeilen einspielen (Seed) | `sql/03_Seed_BS_ReportLines.sql` |
| 5 | Konto-Mapping pflegen | `sql/04_Map_Account_ReportLine.sql` |
| 6 | `Fact_ReportLine_Balance` voraggregieren | `sql/05_Fact_ReportLine_Balance.sql` |
| 7 | DAX Measures im Semantic Model anlegen | `dax/Measures_*.dax` |
| 8 | Calculation Group anlegen (Tabular Editor) | `dax/CalcGroup_TimeIntelligence.dax` |
| 9 | Matrix-Visual konfigurieren + Conditional Formatting | `docs/visual-setup.md` |

---

## Dateiübersicht

| Ordner | Datei | Beschreibung |
|---|---|---|
| `/` | `README.md` | Hauptdokumentation (dieses Dokument) |
| `sql/` | `01_Dim_ReportLine.sql` | DDL Steuerungstabelle |
| `sql/` | `02_Seed_PL_ReportLines.sql` | 24 P&L-Berichtszeilen (Seed) |
| `sql/` | `03_Seed_BS_ReportLines.sql` | Bilanz-Berichtszeilen (Seed) |
| `sql/` | `04_Map_Account_ReportLine.sql` | DDL + Beispiel-Mappings Konto → Berichtszeile |
| `sql/` | `05_Fact_ReportLine_Balance.sql` | Voraggregations-Query (Gold Layer) |
| `dax/` | `Measures_Base.dax` | Basis-Measure `[Amount]` |
| `dax/` | `Measures_LineValue.dax` | Generisches `[LineValue]`-Measure (Kern-Measure) |
| `dax/` | `Measures_Internal_Helpers.dax` | Interne Helfer `[_EBIT_internal]`, `[_EBT_internal]` |
| `dax/` | `Measures_SplitColumns.dax` | `[AbsoluteValue]` und `[PercentageValue]` (getrennte Spalten) |
| `dax/` | `Measures_Margin_Pct.dax` | `[Margin %]` (inline %-Spalte für Key-Zeilen) |
| `dax/` | `CalcGroup_TimeIntelligence.dax` | Calculation Group: Actual / Budget / PY / Δ / Δ% |
| `docs/` | `architecture.md` | Detaillierte Architektur-Dokumentation |
| `docs/` | `visual-setup.md` | Power BI Visual Setup Guide |
