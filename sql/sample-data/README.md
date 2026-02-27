# Sample Data – DemoManufaktur GmbH Group

Demo dataset for the **PBI_AccountingMeasures** Power BI financial reporting solution.
It provides two full fiscal years (2024 and 2025) across three legal entities, four
scenarios and a complete P&L + Balance Sheet chart of accounts.

---

## Demo company

**DemoManufaktur GmbH Group** is a fictitious, medium-sized European manufacturing
conglomerate with subsidiaries in Germany, North America and Asia-Pacific.

---

## Entity structure

| EntityKey | Code     | Name                  | Region   | Country   | Type           |
|-----------|----------|-----------------------|----------|-----------|----------------|
| 1         | HQ       | Headquarters GmbH     | EMEA     | Germany   | Legal Entity   |
| 2         | US       | North America Inc.    | Americas | USA       | Legal Entity   |
| 3         | APAC     | Asia Pacific Ltd.     | APAC     | Singapore | Legal Entity   |
| 4         | EMEA_BU  | EMEA Business Unit    | EMEA     | –         | Business Unit  |
| 5         | GROUP    | Consolidated Group    | Global   | –         | Group          |

> **Note:** EntityKeys 4 and 5 are dimension members only (no Fact_Balance rows).
> Group consolidation is performed in DAX by summing EntityKeys 1–3.

---

## FX rates (local currency → EUR)

| Entity | Currency | Rate  |
|--------|----------|-------|
| HQ     | EUR      | 1.00  |
| US     | USD      | 0.92  |
| APAC   | SGD      | 0.69  |

`Amount` in Fact_Balance is always in EUR; `AmountLC` holds the local-currency value.

---

## Scenarios

| ScenarioKey | Code | Description              |
|-------------|------|--------------------------|
| 1           | ACT  | Actual                   |
| 2           | BUD  | Budget (+5% rev / +3% costs vs ACT) |
| 3           | FC   | Forecast (-2% rev / +1% costs vs ACT) |
| 4           | PY   | Prior Year (≈ ACT -7% rev / -5% costs) |

2025 ACT is 2024 ACT + 6% revenue growth, 4% cost increase.

---

## Time periods

24 monthly periods: **January 2024 – December 2025**
`PeriodKey` = YYYYMM (e.g. `202401` for January 2024).

---

## Chart of accounts overview

### P&L accounts (`AccountType = 'PL'`)

| Range  | Category              | ReportLineKey |
|--------|-----------------------|---------------|
| 4000–4900 | Revenue / Sales    | 1             |
| 5000–5900 | Cost of Sales      | 2             |
| 6100–6190 | Selling Expenses   | 4             |
| 6200–6290 | G&A                | 5             |
| 6300–6390 | R&D                | 6             |
| 6400–6490 | D&A                | 11            |
| 7000–7090 | Other Op Income    | 8             |
| 7100–7190 | Other Op Expenses  | 9             |
| 7200–7290 | Result from Investments | 13       |
| 7300–7390 | Interest Result    | 14            |
| 7800–7890 | Tax                | 17            |

### BS accounts (`AccountType = 'BS'`)

| Range       | Category                   | ReportLineKey |
|-------------|----------------------------|---------------|
| 100–120     | Intangible Assets          | 100           |
| 200–230     | PPE                        | 101           |
| 300–310     | Financial Assets           | 102           |
| 1200–1220   | Inventories                | 104           |
| 1300–1310   | Accounts Receivable        | 105           |
| 1400–1410   | Cash                       | 106           |
| 1500–1510   | Other Current Assets       | 107           |
| 3600–3610   | Share Capital              | 110           |
| 3700–3710   | Retained Earnings          | 111           |
| 3000–3010   | Long-Term Debt             | 113           |
| 3100–3110   | Other Non-Current Liabilities | 114        |
| 3300–3310   | Accounts Payable           | 116           |
| 3400–3410   | Short-Term Debt            | 117           |
| 3500–3510   | Other Current Liabilities  | 118           |

---

## Sign convention

| Account class              | GL storage | SignConvention | Display |
|----------------------------|-----------|----------------|---------|
| Revenue / income           | NEGATIVE  | -1             | positive (flip) |
| Expenses / costs           | POSITIVE  |  1             | positive (no flip) |
| BS assets                  | POSITIVE  |  1             | positive |
| BS equity / liabilities    | NEGATIVE  | -1             | positive (flip) |

The sign flip is applied in Power BI via the `SignConvention` column on
`Dim_ReportLine` during pre-aggregation in `Fact_ReportLine_Balance`.

---

## Data volume

| File                          | Rows   |
|-------------------------------|--------|
| 05a – HQ Fact_Balance         | 7,872  |
| 05b – US Fact_Balance         | 7,872  |
| 05c – APAC Fact_Balance       | 7,872  |
| **Total**                     | **23,616** |

Rows = 82 accounts × 24 periods × 4 scenarios × 3 entities.

---

## Expected KPIs (validation)

Run these figures after loading to validate data correctness.

### HQ — ACT 2024

| KPI           | Expected value | Approx. % of Revenue |
|---------------|---------------|----------------------|
| Revenue       | ~49.6 M EUR   | 100 %                |
| Gross Profit  | ~21.0 M EUR   | ~42 %                |
| EBIT          | ~8.6 M EUR    | ~17 %                |
| Net Income    | ~6.5 M EUR    | ~13 %                |

### Group Consolidated — ACT 2024

| KPI     | Expected value |
|---------|---------------|
| Revenue | ~95 M EUR     |

---

## Installation order

Run the scripts in the following order against your SQL database:

```
00_Schema_All_Tables.sql           -- Create all tables (dimensions + fact)
01_Seed_Dim_Entity.sql             -- Populate Dim_Entity
02_Seed_Dim_Scenario.sql           -- Populate Dim_Scenario
03_Seed_Dim_Period.sql             -- Populate Dim_Period
04_Seed_Dim_Account.sql            -- Populate Dim_Account
../02_Seed_PL_ReportLines.sql      -- Populate Dim_ReportLine (P&L lines)
../03_Seed_BS_ReportLines.sql      -- Populate Dim_ReportLine (BS lines)
../04_Map_Account_ReportLine.sql   -- P&L account → ReportLine mappings
06_Map_Account_ReportLine_BS.sql   -- BS account → ReportLine mappings
05a_Seed_Fact_Balance_HQ.sql       -- HQ GL balances
05b_Seed_Fact_Balance_US.sql       -- US GL balances
05c_Seed_Fact_Balance_APAC.sql     -- APAC GL balances
```

To regenerate the Fact_Balance files (e.g. after changing base amounts):

```bash
python sql/sample-data/generate_sample_data.py
```

The script uses `random.seed(42)` for full reproducibility.
