# Power BI Visual Setup Guide

## Matrix-Visual Konfiguration

### 1. Felder

| Visual-Zone | Feld | Einstellungen |
|---|---|---|
| **Rows** | `Dim_ReportLine[LineItem]` | Sort by `Dim_ReportLine[SortOrder]` (ascending) |
| **Columns** | Calculation Group Item | z. B. Actual / Budget / Δ / Δ% |
| **Values** | `[LineValue]` | Format: `#,##0;(#,##0);-` |
| **Values** (optional) | `[Margin %]` | Format: `0.0%;(0.0%);-` |

> **Tipp:** `SortOrder` in `Dim_ReportLine` muss als Sortierspalte für
> `LineItem` gesetzt sein (Spaltentools → Nach Spalte sortieren).

### 2. Row Subtotals

Matrix → Format → Row subtotals → **Aus** (off).  
Subtotals werden durch CALCULATED-Zeilen in `Dim_ReportLine` gesteuert.

### 3. Visual-Filter

Füge einen **Filter auf dem Visual** (nicht Slicer) hinzu:

```
Dim_ReportLine[ReportType] = "PL"
```

Für eine separate Bilanz-Seite: `ReportType = "BS"`.

---

## Slicer-Setup

| Slicer | Tabelle/Feld | Typ |
|---|---|---|
| Entity | `Dim_Entity[EntityName]` | Dropdown / Liste |
| Consol Level | `Dim_Entity[Consol_Level]` | Dropdown |
| Scenario | `Dim_Scenario[ScenarioName]` | Dropdown |
| Year | `Dim_Period[Year]` | Dropdown |
| Month | `Dim_Period[Month]` | Slider oder Liste |
| Report Type | `Dim_ReportLine[ReportType]` | Nur wenn kein Visual-Filter |

---

## Conditional Formatting

### Fette Schrift für Subtotals

1. Matrix → Format → Cell elements → Font color (oder Background color)
2. Formatierung basierend auf Feldwert → Feld: `Dim_ReportLine[IsBold]`
3. Regel: Wenn `IsBold = 1` → Schrift **fett** (über DAX-Measure und
   bedingte Formatierung oder Power BI Themes)

> **Hinweis:** Echte Fettschrift-Formatierung pro Zelle ist in Power BI
> aktuell nur über ein Measure + bedingte Schriftfarbe (Kontrastfarbe) oder
> via Power BI Paginated Reports möglich. Alternativ: Hintergrundfarbe für
> Subtotal-Zeilen verwenden.

#### Beispiel: Hintergrundfarbe für Subtotal-Zeilen

```dax
// Measure: SubtotalBackground
SubtotalBackground =
IF(
    SELECTEDVALUE(Dim_ReportLine[IsSubtotal]) = 1,
    "#E8E8E8",   // Hellgrau für Subtotals
    "#FFFFFF"    // Weiß für normale Zeilen
)
```

Matrix → Format → Cell elements → Background color → Feldwert → `[SubtotalBackground]`

### Einrückung (IndentLevel)

Power BI unterstützt keine native Einrückung in Matrix-Rows.  
Workaround: Leerzeichen im `LineItem`-Wert voran stellen oder ein berechnetes
Feld mit `REPT(" ", IndentLevel * 4) & LineItem` verwenden.

```dax
// Berechnete Spalte in Dim_ReportLine
LineItemFormatted =
REPT("    ", Dim_ReportLine[IndentLevel]) & Dim_ReportLine[LineItem]
```

### Δ% Spalte: Rot/Grün Formatierung

```dax
// Measure: VariancePctColor
VariancePctColor =
IF(
    [LineValue] >= 0,
    "#107C10",   // Grün (positiv)
    "#D83B01"    // Rot (negativ)
)
```

Matrix → Format → Cell elements → Font color → Feldwert → `[VariancePctColor]`  
(Nur auf die Δ% Spalte der Calculation Group anwenden)

---

## ASCII-Mockup: Fertige P&L

```
┌────────────────────────────────────┬──────────┬──────────┬──────────┬────────┐
│ P&L Report  Jan–Dec 2024           │  Actual  │  Budget  │    Δ     │   Δ%   │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ Sales                              │ 100,000  │  95,000  │   5,000  │  5.3%  │
│ Cost of Sales                      │  60,000  │  57,000  │   3,000  │  5.3%  │
│ **Gross Profit**                   │  40,000  │  38,000  │   2,000  │  5.3%  │
│ GP %                               │  40.0%   │  40.0%   │          │        │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│   Selling Expenses                 │   8,000  │   8,500  │    (500) │ (5.9%) │
│   General and Administration Exp.  │   5,000  │   5,000  │       -  │  0.0%  │
│   Research and Development         │   3,000  │   3,000  │       -  │  0.0%  │
│ **SGA**                            │  16,000  │  16,500  │    (500) │ (3.0%) │
│ SGA %                              │  16.0%   │  17.4%   │          │        │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ Other Operating Income             │   1,500  │   1,000  │     500  │ 50.0%  │
│ Other Operating Expenses           │    (500) │    (500) │       -  │  0.0%  │
│ **EBIT**                           │  25,000  │  22,000  │   3,000  │ 13.6%  │
│ EBIT %                             │  25.0%   │  23.2%   │          │        │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ D&A                                │   4,000  │   4,000  │       -  │  0.0%  │
│ **EBITDA**                         │  29,000  │  26,000  │   3,000  │ 11.5%  │
│ EBITDA %                           │  29.0%   │  27.4%   │          │        │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ Result from Investments            │     500  │     500  │       -  │  0.0%  │
│ Interest Result                    │  (1,000) │  (1,200) │     200  │(16.7%) │
│ **Financial Result**               │    (500) │    (700) │     200  │(28.6%) │
│ **EBT**                            │  24,500  │  21,300  │   3,200  │ 15.0%  │
│ EBT %                              │  24.5%   │  22.4%   │          │        │
├────────────────────────────────────┼──────────┼──────────┼──────────┼────────┤
│ Tax                                │   7,350  │   6,390  │     960  │ 15.0%  │
│ Tax %                              │   7.4%   │   6.7%   │          │        │
│ **Net Income**                     │  17,150  │  14,910  │   2,240  │ 15.0%  │
└────────────────────────────────────┴──────────┴──────────┴──────────┴────────┘
```

---

## %-Werte Darstellungsvarianten

### Variante A: Separate %-Zeilen (Standard – diese Implementierung)

`Dim_ReportLine` enthält eigene Zeilen mit `LineType = 'PERCENTAGE'`
(z. B. `GP %`, `EBIT %`). Das `[LineValue]`-Measure gibt für diese Zeilen
den Quotienten zurück; für alle anderen Zeilen den Absolutwert.

**Vorteile:**
- Ein einziges Measure `[LineValue]` für alle Zeilen
- %-Zeilen können beliebig positioniert werden (via SortOrder)
- Funktioniert mit Calculation Group (Δ % macht weniger Sinn auf %-Zeilen →
  über Conditional Formatting ausblenden)

**Nachteile:**
- %-Zeile und Absolutwert-Zeile teilen sich dieselbe Spalte → Formatierung
  muss Zahlen- und %-Format mischen (bedingte Formatierung per Zelle)

### Variante B: Inline %-Spalte

Zweites Measure `[Margin %]` als separate Spalte im Matrix-Visual.
Gibt nur für Key-Subtotal-Zeilen (Gross Profit, EBIT, …) einen Wert zurück.

**Vorteile:**
- Klare Trennung: Absolute-Spalten und %-Spalte
- Einfachere Zahlenformatierung

**Nachteile:**
- Zusätzliche Spalte belegt Platz
- Weniger flexibel für andere %-Berechnungen

**Empfehlung:** Variante A für vollständige P&L-Berichte;
Variante B als ergänzende Spalte für Executive Dashboards.

---

## Report-Filterung für mehrere Berichte

Jede Power BI-Seite filtert die Matrix auf einen `ReportType`:

| Seite | Filter |
|---|---|
| P&L | `Dim_ReportLine[ReportType] = "PL"` |
| Balance Sheet | `Dim_ReportLine[ReportType] = "BS"` |
| Cashflow | `Dim_ReportLine[ReportType] = "CF"` |
| Working Capital | `Dim_ReportLine[ReportType] = "WC"` |
| Statistics | `Dim_ReportLine[ReportType] = "STAT"` |

Der Filter kann als **Visual-Filter** (nur diese Matrix), als **Seiten-Filter**
(alle Visuals der Seite) oder über einen **ausgeblendeten Slicer** gesetzt werden.

Das `[LineValue]`-Measure und alle anderen DAX-Measures funktionieren ohne
Änderung für alle `ReportType`-Werte, da die Berichtslogik vollständig in
`Dim_ReportLine` konfiguriert ist.

## Lokale Demo mit DuckDB

Für eine lokale Demo ohne Fabric/Cloud kannst du DuckDB als Datenquelle verwenden:

1. **DuckDB-Datenbank erstellen:**
   ```bash
   cd duckdb
   pip install -r requirements.txt
   python setup_duckdb.py
   ```

2. **Parquet-Export (empfohlen für Power BI Import):**
   ```bash
   python export_to_parquet.py
   ```

3. **Power BI Desktop anbinden:**
   - Datei → Daten abrufen → Parquet
   - Ordner `duckdb/parquet/` auswählen
   - Alle 8 Tabellen importieren
   - Beziehungen im Modell prüfen/erstellen

Siehe `duckdb/README.md` für Details.
