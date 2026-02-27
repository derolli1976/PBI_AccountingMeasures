-- =============================================================================
-- 03_Seed_BS_ReportLines.sql
-- Seed data: Beispiel-Bilanzzeilen für Dim_ReportLine (ReportType = 'BS')
-- Demonstrates that the same Dim_ReportLine table drives Balance Sheet reports.
-- Columns: ReportLineKey, ReportType, LineItem, SortOrder, LineType,
--          CalcFormula, CalcOperands, PercentageBase,
--          IsBold, IsSubtotal, IndentLevel, SignConvention, AccountFilter
-- =============================================================================

INSERT INTO Dim_ReportLine
    (ReportLineKey, ReportType, LineItem, SortOrder, LineType,
     CalcFormula, CalcOperands, PercentageBase,
     IsBold, IsSubtotal, IndentLevel, SignConvention, AccountFilter)
VALUES

-- ════════════════════════════════════════════════════════════════════════════
-- ASSETS (Aktiva)
-- ════════════════════════════════════════════════════════════════════════════

-- ── Non-Current Assets (Anlagevermögen) ──────────────────────────────────────
(100, 'BS', 'Intangible Assets',                100,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'INTANG_ASSETS'),

(101, 'BS', 'Property, Plant & Equip.',         200,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'PPE'),

(102, 'BS', 'Financial Assets',                 300,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'FIN_ASSETS'),

(103, 'BS', 'Fixed Assets',                     400,  'CALCULATED',
    '[Intangible Assets]+[Property, Plant & Equip.]+[Financial Assets]',
    '{"add":["Intangible Assets","Property, Plant & Equip.","Financial Assets"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Current Assets (Umlaufvermögen) ──────────────────────────────────────────
(104, 'BS', 'Inventories',                      500,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'INVENTORY'),

(105, 'BS', 'Accounts Receivable',              600,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'AR'),

(106, 'BS', 'Cash and Cash Equivalents',        700,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'CASH'),

(107, 'BS', 'Other Current Assets',             800,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'OTH_CURR_ASSETS'),

(108, 'BS', 'Current Assets',                   900,  'CALCULATED',
    '[Inventories]+[Accounts Receivable]+[Cash and Cash Equivalents]+[Other Current Assets]',
    '{"add":["Inventories","Accounts Receivable","Cash and Cash Equivalents","Other Current Assets"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Total Assets ──────────────────────────────────────────────────────────────
(109, 'BS', 'Total Assets',                    1000,  'CALCULATED',
    '[Fixed Assets]+[Current Assets]',
    '{"add":["Fixed Assets","Current Assets"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ════════════════════════════════════════════════════════════════════════════
-- EQUITY & LIABILITIES (Passiva)
-- ════════════════════════════════════════════════════════════════════════════

-- ── Equity (Eigenkapital) ─────────────────────────────────────────────────────
(110, 'BS', 'Share Capital',                   1100,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'SHARE_CAPITAL'),

(111, 'BS', 'Retained Earnings',               1200,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'RETAINED_EARN'),

(112, 'BS', 'Total Equity',                    1300,  'CALCULATED',
    '[Share Capital]+[Retained Earnings]',
    '{"add":["Share Capital","Retained Earnings"]}',
    NULL,
    1, 1, 0, -1, NULL),

-- ── Non-Current Liabilities (Langfristige Verbindlichkeiten) ─────────────────
(113, 'BS', 'Long-Term Debt',                  1400,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'LT_DEBT'),

(114, 'BS', 'Other Non-Current Liabilities',   1500,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'OTH_LT_LIAB'),

(115, 'BS', 'Non-Current Liabilities',         1600,  'CALCULATED',
    '[Long-Term Debt]+[Other Non-Current Liabilities]',
    '{"add":["Long-Term Debt","Other Non-Current Liabilities"]}',
    NULL,
    1, 1, 0, -1, NULL),

-- ── Current Liabilities (Kurzfristige Verbindlichkeiten) ─────────────────────
(116, 'BS', 'Accounts Payable',                1700,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'AP'),

(117, 'BS', 'Short-Term Debt',                 1800,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'ST_DEBT'),

(118, 'BS', 'Other Current Liabilities',       1900,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1, -1, 'OTH_CURR_LIAB'),

(119, 'BS', 'Current Liabilities',             2000,  'CALCULATED',
    '[Accounts Payable]+[Short-Term Debt]+[Other Current Liabilities]',
    '{"add":["Accounts Payable","Short-Term Debt","Other Current Liabilities"]}',
    NULL,
    1, 1, 0, -1, NULL),

-- ── Total Equity & Liabilities ────────────────────────────────────────────────
(120, 'BS', 'Total Equity & Liabilities',      2100,  'CALCULATED',
    '[Total Equity]+[Non-Current Liabilities]+[Current Liabilities]',
    '{"add":["Total Equity","Non-Current Liabilities","Current Liabilities"]}',
    NULL,
    1, 1, 0, -1, NULL);
