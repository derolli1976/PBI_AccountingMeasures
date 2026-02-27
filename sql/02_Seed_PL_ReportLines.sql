-- =============================================================================
-- 02_Seed_PL_ReportLines.sql
-- Seed data: alle 24 P&L-Berichtszeilen für Dim_ReportLine (ReportType = 'PL')
-- Columns: ReportLineKey, ReportType, LineItem, SortOrder, LineType,
--          CalcFormula, CalcOperands, PercentageBase,
--          IsBold, IsSubtotal, IndentLevel, SignConvention, AccountFilter
-- =============================================================================

INSERT INTO Dim_ReportLine
    (ReportLineKey, ReportType, LineItem, SortOrder, LineType,
     CalcFormula, CalcOperands, PercentageBase,
     IsBold, IsSubtotal, IndentLevel, SignConvention, AccountFilter)
VALUES

-- ── Revenue ──────────────────────────────────────────────────────────────────
-- Sales: revenue accounts carry negative balances in GL → sign flip -1
(1,  'PL', 'Sales',                           100,  'DATA',
    NULL, NULL, NULL,
    1, 0, 0, -1, 'SALES'),

-- ── Cost of Sales ─────────────────────────────────────────────────────────────
(2,  'PL', 'Cost of Sales',                   200,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0,  1, 'COGS'),

-- ── Gross Profit (subtotal) ───────────────────────────────────────────────────
(3,  'PL', 'Gross Profit',                    300,  'CALCULATED',
    '[Sales] + [Cost of Sales]',
    '{"add":["Sales","Cost of Sales"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Operating Expenses ────────────────────────────────────────────────────────
(4,  'PL', 'Selling Expenses',                400,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'SELLING_EXP'),

(5,  'PL', 'General and Administration Exp.', 500,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'GA_EXP'),

(6,  'PL', 'Research and Development',        600,  'DATA',
    NULL, NULL, NULL,
    0, 0, 1,  1, 'RD_EXP'),

-- ── SGA (subtotal) ────────────────────────────────────────────────────────────
(7,  'PL', 'SGA',                             700,  'CALCULATED',
    '[Selling]+[GA]+[RD]',
    '{"add":["Selling Expenses","General and Administration Exp.","Research and Development"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Other Operating Items ─────────────────────────────────────────────────────
(8,  'PL', 'Other Operating Income',          800,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0, -1, 'OTH_OP_INC'),

(9,  'PL', 'Other Operating Expenses',        900,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0,  1, 'OTH_OP_EXP'),

-- ── EBIT (subtotal) ───────────────────────────────────────────────────────────
(10, 'PL', 'EBIT',                           1000,  'CALCULATED',
    '[GP]+[SGA]+[OthOpInc]+[OthOpExp]',
    '{"add":["Gross Profit","SGA","Other Operating Income","Other Operating Expenses"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── D&A (shown below EBIT for EBITDA bridge) ─────────────────────────────────
(11, 'PL', 'D&A',                            1100,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0,  1, 'DA'),

-- ── EBITDA (subtotal) ─────────────────────────────────────────────────────────
(12, 'PL', 'EBITDA',                         1200,  'CALCULATED',
    '[EBIT] + [D&A]',
    '{"add":["EBIT","D&A"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Financial Result ──────────────────────────────────────────────────────────
(13, 'PL', 'Result from Investments',        1300,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0, -1, 'INV_RESULT'),

(14, 'PL', 'Interest Result',                1400,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0, -1, 'INT_RESULT'),

(15, 'PL', 'Financial Result',               1500,  'CALCULATED',
    '[InvResult]+[IntResult]',
    '{"add":["Result from Investments","Interest Result"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── EBT (subtotal) ────────────────────────────────────────────────────────────
(16, 'PL', 'EBT',                            1600,  'CALCULATED',
    '[EBIT]+[FinResult]',
    '{"add":["EBIT","Financial Result"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Tax ───────────────────────────────────────────────────────────────────────
(17, 'PL', 'Tax',                            1700,  'DATA',
    NULL, NULL, NULL,
    0, 0, 0,  1, 'TAX'),

-- ── Net Income (bottom line) ──────────────────────────────────────────────────
(18, 'PL', 'Net Income',                     1800,  'CALCULATED',
    '[EBT]+[Tax]',
    '{"add":["EBT","Tax"]}',
    NULL,
    1, 1, 0,  1, NULL),

-- ── Percentage / Margin lines ─────────────────────────────────────────────────
-- Sort orders are interleaved so each % row appears immediately after its base row.
(19, 'PL', 'GP %',                            310,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL),

(20, 'PL', 'SGA %',                           710,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL),

(21, 'PL', 'EBITDA %',                       1210,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL),

(22, 'PL', 'EBIT %',                         1010,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL),

(23, 'PL', 'EBT %',                          1610,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL),

(24, 'PL', 'Tax %',                          1710,  'PERCENTAGE',
    NULL, NULL, 'Sales',
    0, 0, 0,  1, NULL);
