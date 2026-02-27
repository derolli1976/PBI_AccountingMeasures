-- =============================================================================
-- 04_Seed_Dim_Account.sql
-- Seed data: Chart of Accounts for DemoManufaktur GmbH Group
-- Covers all P&L accounts referenced in 04_Map_Account_ReportLine.sql
-- and all BS accounts referenced in 06_Map_Account_ReportLine_BS.sql
-- Sign convention: -1 = stored NEGATIVE in GL (revenue / income / liabilities)
--                   1 = stored POSITIVE in GL (expenses / assets)
-- =============================================================================

-- =============================================================================
-- P&L ACCOUNTS (AccountType = 'PL')
-- =============================================================================

-- ── Revenue / Sales  (ReportLineKey = 1, SignConvention = -1) ─────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(4000, '4000', 'Product Revenue - Germany',  'Revenue', 'Net Revenue', 'Domestic',  'PL', -1),
(4001, '4001', 'Product Revenue - Export EU','Revenue', 'Net Revenue', 'Export EU', 'PL', -1),
(4100, '4100', 'Service Revenue',            'Revenue', 'Net Revenue', 'Services',  'PL', -1),
(4200, '4200', 'Licence Revenue',            'Revenue', 'Net Revenue', 'Licences',  'PL', -1),
(4500, '4500', 'Project Revenue',            'Revenue', 'Net Revenue', 'Projects',  'PL', -1),
(4900, '4900', 'Other Revenue',              'Revenue', 'Net Revenue', 'Other',     'PL', -1);

-- ── Cost of Sales  (ReportLineKey = 2, SignConvention = 1) ────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(5000, '5000', 'Material Costs',          'Cost of Sales', 'Direct Costs', 'Raw Materials', 'PL', 1),
(5100, '5100', 'Production Labour',       'Cost of Sales', 'Direct Costs', 'Labour',        'PL', 1),
(5200, '5200', 'Manufacturing Overhead',  'Cost of Sales', 'Direct Costs', 'Overhead',      'PL', 1),
(5500, '5500', 'Freight & Logistics',     'Cost of Sales', 'Direct Costs', 'Logistics',     'PL', 1),
(5900, '5900', 'Other COGS',              'Cost of Sales', 'Direct Costs', 'Other',         'PL', 1);

-- ── Selling Expenses  (ReportLineKey = 4, SignConvention = 1) ─────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(6100, '6100', 'Sales Personnel',          'Operating Expenses', 'Selling', 'Personnel', 'PL', 1),
(6110, '6110', 'Marketing & Advertising',  'Operating Expenses', 'Selling', 'Marketing', 'PL', 1),
(6120, '6120', 'Trade Shows & Events',     'Operating Expenses', 'Selling', 'Events',    'PL', 1),
(6130, '6130', 'Travel Selling',           'Operating Expenses', 'Selling', 'Travel',    'PL', 1),
(6190, '6190', 'Other Selling Expenses',   'Operating Expenses', 'Selling', 'Other',     'PL', 1);

-- ── G&A  (ReportLineKey = 5, SignConvention = 1) ──────────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(6200, '6200', 'Management & Administration', 'Operating Expenses', 'G&A', 'Personnel',         'PL', 1),
(6210, '6210', 'Legal & Consulting',          'Operating Expenses', 'G&A', 'External Services',  'PL', 1),
(6220, '6220', 'IT & Software',               'Operating Expenses', 'G&A', 'IT',                 'PL', 1),
(6250, '6250', 'Office & Facilities',         'Operating Expenses', 'G&A', 'Facilities',         'PL', 1),
(6290, '6290', 'Other G&A',                   'Operating Expenses', 'G&A', 'Other',              'PL', 1);

-- ── R&D  (ReportLineKey = 6, SignConvention = 1) ──────────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(6300, '6300', 'R&D Personnel',            'Operating Expenses', 'R&D', 'Personnel', 'PL', 1),
(6310, '6310', 'R&D Materials & Prototypes','Operating Expenses', 'R&D', 'Materials', 'PL', 1),
(6320, '6320', 'R&D External Services',    'Operating Expenses', 'R&D', 'External',  'PL', 1),
(6390, '6390', 'Other R&D',                'Operating Expenses', 'R&D', 'Other',     'PL', 1);

-- ── D&A  (ReportLineKey = 11, SignConvention = 1) ─────────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(6400, '6400', 'Depreciation Intangibles',  'Operating Expenses', 'D&A', 'Intangibles', 'PL', 1),
(6410, '6410', 'Depreciation PPE',          'Operating Expenses', 'D&A', 'PPE',         'PL', 1),
(6420, '6420', 'Amortisation ROU Assets',   'Operating Expenses', 'D&A', 'ROU',         'PL', 1),
(6490, '6490', 'Other D&A',                 'Operating Expenses', 'D&A', 'Other',       'PL', 1);

-- ── Other Operating Income  (ReportLineKey = 8, SignConvention = -1) ──────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(7000, '7000', 'Gains on Asset Disposal', 'Other Operating', 'Income', 'Disposal',  'PL', -1),
(7010, '7010', 'Insurance Recoveries',    'Other Operating', 'Income', 'Insurance', 'PL', -1),
(7050, '7050', 'Government Grants',       'Other Operating', 'Income', 'Grants',    'PL', -1),
(7090, '7090', 'Other Operating Income',  'Other Operating', 'Income', 'Other',     'PL', -1);

-- ── Other Operating Expenses  (ReportLineKey = 9, SignConvention = 1) ─────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(7100, '7100', 'Restructuring Charges', 'Other Operating', 'Expenses', 'Restructuring', 'PL', 1),
(7110, '7110', 'Impairment Charges',    'Other Operating', 'Expenses', 'Impairment',    'PL', 1),
(7150, '7150', 'Legal Settlements',     'Other Operating', 'Expenses', 'Legal',         'PL', 1),
(7190, '7190', 'Other Op Expenses',     'Other Operating', 'Expenses', 'Other',         'PL', 1);

-- ── Result from Investments  (ReportLineKey = 13, SignConvention = -1) ────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(7200, '7200', 'Income from Investments',    'Financial Result', 'Investments', 'Income',   'PL', -1),
(7210, '7210', 'Dividends Received',         'Financial Result', 'Investments', 'Dividends','PL', -1),
(7250, '7250', 'Gains on Financial Assets',  'Financial Result', 'Investments', 'Gains',    'PL', -1),
(7290, '7290', 'Other Investment Result',    'Financial Result', 'Investments', 'Other',    'PL', -1);

-- ── Interest Result  (ReportLineKey = 14, SignConvention = -1) ────────────────
-- Income items stored NEGATIVE in GL, expense items stored POSITIVE in GL.
-- Net interest = SUM(GL) * -1 applied by ReportLine SignConvention.
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(7300, '7300', 'Interest Income',      'Financial Result', 'Interest', 'Income',  'PL', -1),
(7310, '7310', 'Interest Expense',     'Financial Result', 'Interest', 'Expense', 'PL', -1),
(7350, '7350', 'FX Gains/Losses',      'Financial Result', 'Interest', 'FX',      'PL', -1),
(7390, '7390', 'Other Financial Items','Financial Result', 'Interest', 'Other',   'PL', -1);

-- ── Tax  (ReportLineKey = 17, SignConvention = 1) ─────────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(7800, '7800', 'Current Income Tax', 'Tax', 'Income Tax', 'Current',     'PL', 1),
(7810, '7810', 'Deferred Tax',       'Tax', 'Income Tax', 'Deferred',    'PL', 1),
(7820, '7820', 'Trade Tax',          'Tax', 'Income Tax', 'Trade Tax',   'PL', 1),
(7850, '7850', 'Other Tax',          'Tax', 'Income Tax', 'Other',       'PL', 1),
(7890, '7890', 'Tax Adjustments',    'Tax', 'Income Tax', 'Adjustments', 'PL', 1);

-- =============================================================================
-- BS ACCOUNTS (AccountType = 'BS')
-- =============================================================================

-- ── Intangible Assets  (ReportLineKey = 100, SignConvention = 1) ──────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(100, '0100', 'Goodwill',                'Non-Current Assets', 'Intangible Assets', 'Goodwill',   'BS', 1),
(110, '0110', 'Customer Relationships',  'Non-Current Assets', 'Intangible Assets', 'Intangibles','BS', 1),
(120, '0120', 'Software & Licences',     'Non-Current Assets', 'Intangible Assets', 'Software',   'BS', 1);

-- ── PPE  (ReportLineKey = 101, SignConvention = 1) ────────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(200, '0200', 'Land & Buildings',      'Non-Current Assets', 'PPE', 'Land & Buildings', 'BS', 1),
(210, '0210', 'Machinery & Equipment', 'Non-Current Assets', 'PPE', 'Machinery',        'BS', 1),
(220, '0220', 'Vehicles',              'Non-Current Assets', 'PPE', 'Vehicles',         'BS', 1),
(230, '0230', 'Right-of-Use Assets',   'Non-Current Assets', 'PPE', 'ROU Assets',       'BS', 1);

-- ── Financial Assets  (ReportLineKey = 102, SignConvention = 1) ───────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(300, '0300', 'Investments in Associates', 'Non-Current Assets', 'Financial Assets', 'Associates', 'BS', 1),
(310, '0310', 'Long-Term Loans',           'Non-Current Assets', 'Financial Assets', 'Loans',      'BS', 1);

-- ── Inventories  (ReportLineKey = 104, SignConvention = 1) ───────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(1200, '1200', 'Raw Materials',  'Current Assets', 'Inventories', 'Raw Materials',  'BS', 1),
(1210, '1210', 'Work in Progress','Current Assets', 'Inventories', 'WIP',            'BS', 1),
(1220, '1220', 'Finished Goods', 'Current Assets', 'Inventories', 'Finished Goods', 'BS', 1);

-- ── Accounts Receivable  (ReportLineKey = 105, SignConvention = 1) ────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(1300, '1300', 'Trade Receivables', 'Current Assets', 'Receivables', 'Trade', 'BS', 1),
(1310, '1310', 'Other Receivables', 'Current Assets', 'Receivables', 'Other', 'BS', 1);

-- ── Cash  (ReportLineKey = 106, SignConvention = 1) ───────────────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(1400, '1400', 'Bank Accounts', 'Current Assets', 'Cash', 'Bank',       'BS', 1),
(1410, '1410', 'Petty Cash',    'Current Assets', 'Cash', 'Petty Cash', 'BS', 1);

-- ── Other Current Assets  (ReportLineKey = 107, SignConvention = 1) ───────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(1500, '1500', 'Prepaid Expenses', 'Current Assets', 'Other Current Assets', 'Prepayments',   'BS', 1),
(1510, '1510', 'VAT Receivable',   'Current Assets', 'Other Current Assets', 'Tax Receivable','BS', 1);

-- ── Share Capital  (ReportLineKey = 110, SignConvention = -1) ─────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3600, '3600', 'Share Capital',    'Equity', 'Share Capital', 'Issued Capital', 'BS', -1),
(3610, '3610', 'Capital Reserves', 'Equity', 'Share Capital', 'Reserves',       'BS', -1);

-- ── Retained Earnings  (ReportLineKey = 111, SignConvention = -1) ─────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3700, '3700', 'Retained Earnings',    'Equity', 'Retained Earnings', 'Prior Years',   'BS', -1),
(3710, '3710', 'Current Year Profit',  'Equity', 'Retained Earnings', 'Current Year',  'BS', -1);

-- ── Long-Term Debt  (ReportLineKey = 113, SignConvention = -1) ────────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3000, '3000', 'Bank Loans Long-Term', 'Non-Current Liabilities', 'Long-Term Debt', 'Bank Loans', 'BS', -1),
(3010, '3010', 'Bonds Payable',        'Non-Current Liabilities', 'Long-Term Debt', 'Bonds',      'BS', -1);

-- ── Other Non-Current Liabilities  (ReportLineKey = 114, SignConvention = -1) ─
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3100, '3100', 'Pension Provisions', 'Non-Current Liabilities', 'Other LT Liabilities', 'Pensions',   'BS', -1),
(3110, '3110', 'Other Provisions',   'Non-Current Liabilities', 'Other LT Liabilities', 'Provisions', 'BS', -1);

-- ── Accounts Payable  (ReportLineKey = 116, SignConvention = -1) ──────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3300, '3300', 'Trade Payables',     'Current Liabilities', 'Payables', 'Trade',    'BS', -1),
(3310, '3310', 'Accrued Liabilities','Current Liabilities', 'Payables', 'Accruals', 'BS', -1);

-- ── Short-Term Debt  (ReportLineKey = 117, SignConvention = -1) ───────────────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3400, '3400', 'Bank Overdraft',   'Current Liabilities', 'Short-Term Debt', 'Overdraft', 'BS', -1),
(3410, '3410', 'Short-Term Loans', 'Current Liabilities', 'Short-Term Debt', 'Loans',     'BS', -1);

-- ── Other Current Liabilities  (ReportLineKey = 118, SignConvention = -1) ─────
INSERT INTO Dim_Account
    (AccountKey, AccountCode, AccountName, L1_Category, L2_Subcategory, L3_Detail, AccountType, SignConvention)
VALUES
(3500, '3500', 'Tax Payables',    'Current Liabilities', 'Other Current Liabilities', 'Tax',         'BS', -1),
(3510, '3510', 'Deferred Revenue','Current Liabilities', 'Other Current Liabilities', 'Deferred Rev','BS', -1);
