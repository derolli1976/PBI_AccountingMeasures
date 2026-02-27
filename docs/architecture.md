# Architecture – P&L Reporting in Power BI / Microsoft Fabric

## Schichtenmodell (5-Layer Architecture)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 5 – Power BI Frontend                                                │
│                                                                             │
│   Matrix Visual          Calculation Group        Slicers                  │
│   ─────────────          ────────────────         ───────                  │
│   Rows:  LineItem        Actual                   Entity / Consol_Level    │
│   Cols:  Calc Group      Budget                   Scenario                 │
│   Values:[LineValue]     Prior Year               Year / Month             │
│          [Margin %]      Δ vs Budget              ReportType               │
│                          Δ% vs Budget                                      │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ DAX / Direct Lake
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 4 – Direct Lake Semantic Model (Star Schema)                         │
│                                                                             │
│   Dim_Entity        Dim_Scenario      Dim_Period                            │
│       │                  │                │                                 │
│       └──────────┬───────┘                │                                 │
│                  │                        │                                 │
│            Fact_ReportLine_Balance ◄───────┘                                │
│                  │                                                          │
│       Dim_ReportLine ◄── Map_Account_ReportLine ◄── Dim_Account             │
│                                                                             │
│   DAX Measures: [Amount] [LineValue] [Margin %] [AbsoluteValue] etc.        │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ Delta Tables (Direct Lake)
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 3 – Fabric Lakehouse / Warehouse  Gold Layer                         │
│                                                                             │
│   Fact_Balance              (raw GL postings per account/period/entity)     │
│   Fact_ReportLine_Balance   (pre-aggregated per report line)                │
│   Dim_Account               (chart of accounts + P&L / BS / CF flags)      │
│   Dim_Entity                (legal entities + consolidation hierarchy)      │
│   Dim_Scenario              (Actual, Plan, FC, LY, Budget)                 │
│   Dim_Period                (calendar + fiscal calendar)                   │
│   Dim_ReportLine            (report control table)                         │
│   Map_Account_ReportLine    (account → report line bridge)                 │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ Notebooks / Dataflows / SQL
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 2 – Silver Layer (Cleansed & Harmonised)                             │
│                                                                             │
│   - Account mapping / harmonisation across entities                         │
│   - Period normalisation (fiscal ↔ calendar)                               │
│   - Currency translation (LC → Group currency)                              │
│   - Elimination entries for inter-company transactions                      │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ ERP / Source Extracts
┌────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 1 – Raw / Bronze                                                     │
│                                                                             │
│   - ERP GL extracts (SAP, Dynamics, Oracle, …)                             │
│   - Chart of accounts master data                                           │
│   - Account hierarchy files (CSV / Excel)                                  │
│   - Scenario/Plan data from planning tools                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Star Schema (Gold Layer / Semantic Model)

```
                    ┌─────────────────┐
                    │  Dim_Scenario   │
                    │ ─────────────── │
                    │ ScenarioKey  PK │
                    │ ScenarioName    │
                    └────────┬────────┘
                             │
 ┌──────────────┐            │           ┌─────────────┐
 │  Dim_Entity  │            │           │  Dim_Period  │
 │ ──────────── │            │           │ ─────────── │
 │ EntityKey PK │            │           │ PeriodKey PK│
 │ EntityName   │            │           │ Year        │
 │ Region       │            │           │ Month       │
 │ Consol_Level │            │           │ Quarter     │
 └──────┬───────┘            │           │ YearMonth   │
        │                    │           │ FiscalYear  │
        │      ┌─────────────▼──────────────────────────────┐
        │      │         Fact_ReportLine_Balance             │
        └─────►│ ─────────────────────────────────────────  │◄──────┐
               │ ReportLineKey  FK → Dim_ReportLine          │       │
               │ EntityKey      FK → Dim_Entity              │       │
               │ ScenarioKey    FK → Dim_Scenario            │       │
               │ PeriodKey      FK → Dim_Period              │       │
               │ Amount                                      │       │
               │ AmountLC                                    │       │
               └─────────────────────────────────────────────┘       │
                                                                      │
 ┌────────────────────────┐    ┌──────────────────────────┐          │
 │    Dim_ReportLine      │    │  Map_Account_ReportLine  │          │
 │ ──────────────────── ◄─┼────┤ ──────────────────────── │          │
 │ ReportLineKey       PK │    │ AccountKey    FK         │          │
 │ ReportType             │    │ ReportLineKey FK         │──────────┘
 │ LineItem               │    │ MappingWeight            │
 │ SortOrder              │    └──────────┬───────────────┘
 │ LineType               │               │
 │ CalcFormula            │    ┌──────────▼───────────┐
 │ CalcOperands           │    │    Dim_Account        │
 │ PercentageBase         │    │ ─────────────────── ◄─┼── (optional, for drill)
 │ IsBold                 │    │ AccountKey        PK  │
 │ IsSubtotal             │    │ AccountNo             │
 │ IndentLevel            │    │ AccountName           │
 │ SignConvention         │    │ L1_Category           │
 │ AccountFilter          │    │ L2_Subcategory        │
 └────────────────────────┘    │ L3_Detail             │
                               │ AccountType           │
                               │ SignConvention        │
                               │ PL_LineItem           │
                               │ PL_SortOrder          │
                               │ BS_LineItem           │
                               │ BS_SortOrder          │
                               └───────────────────────┘
```

---

## Dim_ReportLine – Der Kern der Lösung

`Dim_ReportLine` ist die zentrale Steuerungstabelle. Sie beschreibt **was** jede
Zeile im Bericht ist und **wie** sie berechnet wird – ohne dass Berichtslogik im
DAX-Code hardcodiert werden muss.

| Spalte | Zweck |
|---|---|
| `ReportLineKey` | Primärschlüssel |
| `ReportType` | `PL`, `BS`, `CF`, `WC`, `STAT` – eine Tabelle, viele Berichte |
| `LineItem` | Anzeigename im Matrix-Visual |
| `SortOrder` | Reihenfolge der Zeilen (inkl. Lücken für % -Zeilen) |
| `LineType` | `DATA` / `CALCULATED` / `PERCENTAGE` – steuert DAX-Logik |
| `CalcFormula` | Lesbare Formel zur Dokumentation |
| `CalcOperands` | JSON-Struktur für Tool-gestützte Codegenerierung |
| `PercentageBase` | Bezugsgröße für %-Zeilen (z. B. `Sales`) |
| `IsBold` | Conditional Formatting in Power BI |
| `IsSubtotal` | Für bedingte Formatierung / Hintergrundfarbe |
| `IndentLevel` | Einrückungstiefe im Visual |
| `SignConvention` | `1` oder `-1` – Vorzeichen-Normalisierung beim Laden |
| `AccountFilter` | Logischer Schlüssel für Mapping in `Map_Account_ReportLine` |

### Vorteile des datengetriebenen Ansatzes

1. **Neue Berichtszeile hinzufügen** → nur ein INSERT, kein DAX-Code-Update.
2. **Formatierung ändern** → UPDATE in der Tabelle, Power BI übernimmt es.
3. **Neuen Bericht (BS, CF, WC)** → neue Rows mit anderem `ReportType`.
4. **Reihenfolge ändern** → `SortOrder` anpassen.

---

## Datenfluss (ERP → Power BI Visual)

```
ERP-System
    │
    ▼ (täglicher/monatlicher Export)
Bronze Layer  ─── raw GL-Buchungen, Kontenrahmen, Hierarchien
    │
    ▼ (Notebook / Dataflow)
Silver Layer  ─── Harmonisierung, Währungsumrechnung, Konsolidierung
    │
    ▼ (SQL / Notebook)
Gold Layer
    ├── Fact_Balance          (alle Buchungen auf Kontenebene)
    ├── Dim_Account           (Kontenrahmen mit P&L-Mapping-Flags)
    ├── Dim_ReportLine        (Steuerungstabelle, wartbar durch Finance-Team)
    ├── Map_Account_ReportLine (Konto → Berichtszeile)
    │
    ▼ (Aggregations-Notebook / SQL – täglich/stündlich)
    Fact_ReportLine_Balance   (voraggregiert, Direct-Lake-optimiert)
    │
    ▼ (Direct Lake)
Semantic Model
    ├── DAX [Amount]          (SUMX auf Fact_ReportLine_Balance)
    ├── DAX [LineValue]       (SWITCH DATA/CALCULATED/PERCENTAGE)
    ├── DAX [Margin %]        (inline %-Spalte)
    └── Calculation Group     (Actual / Budget / PY / Δ / Δ%)
    │
    ▼
Power BI Matrix Visual
    └── P&L / BS / CF Report
```

---

## Voraggregation – Warum?

Direct Lake liest Delta Tables direkt. Je mehr Zeilen in `Fact_Balance`, desto
mehr DAX-Kontext-Filterungen pro Visual-Render. Mit `Fact_ReportLine_Balance`
wird die Aggregation **einmalig** in der Gold Layer durchgeführt:

| Ohne Voraggregation | Mit Voraggregation |
|---|---|
| Fact_Balance: 50 Mio. Rows | Fact_ReportLine_Balance: ~500k Rows |
| DAX muss SUM + JOIN pro Render | DAX liest bereits aggregierte Werte |
| Langsam bei vielen Entitäten | Skaliert auf 100+ Entitäten |

---

## Erweiterbarkeit

### Neuen Berichtstyp hinzufügen (Beispiel: Cashflow)

1. `Dim_ReportLine`: neue Rows mit `ReportType = 'CF'` einfügen.
2. `Map_Account_ReportLine`: Cashflow-relevante Konten mappen.
3. `Fact_ReportLine_Balance`: Aggregation läuft automatisch für alle LineTypes.
4. Power BI: neue Report-Seite mit Filter `ReportType = 'CF'`.
5. `[LineValue]` Measure: SWITCH um CF-spezifische CALCULATED-Zeilen ergänzen
   (z. B. `Operating Cash Flow`, `Free Cash Flow`).

### Working Capital

Spezialfall: WC = Current Assets − Current Liabilities. Kann als eigene
`Dim_ReportLine`-Zeilen (ReportType = 'WC') oder als separate CALCULATED-Zeilen
in der BS-Seite implementiert werden.

### Statistikkonten

Statistikkonten (z. B. FTE, Fläche, Stückzahlen) werden wie normale DATA-Zeilen
behandelt: `ReportType = 'STAT'`, eigene Konten in `Map_Account_ReportLine`,
eigene Report-Seite in Power BI.

---

## Konsolidierungsebenen

`Dim_Entity` enthält ein Feld `Consol_Level`:

| Consol_Level | Bedeutung |
|---|---|
| `LEGAL` | Einzelgesellschaft (legal entity) |
| `BU` | Business Unit (Zusammenfassung mehrerer Entities) |
| `GROUP` | Konzernebene (alle Entities) |

Der Slicer `Consol_Level` filtert `Dim_Entity`, was automatisch
`Fact_ReportLine_Balance` über die Beziehung filtert. Eliminierungseinträge
werden als eigene Entity (z. B. `EntityKey = 9999, EntityName = 'Eliminations'`)
modelliert.
