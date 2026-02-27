-- =============================================================================
-- 06_Map_Account_ReportLine_BS.sql
-- Mappings: BS accounts → BS ReportLines
-- Complements 04_Map_Account_ReportLine.sql which covers P&L mappings.
-- ReportLine keys match those defined in 03_Seed_BS_ReportLines.sql.
-- =============================================================================

-- ── Intangible Assets  (ReportLineKey = 100) ──────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(100, 100), (110, 100), (120, 100);

-- ── PPE  (ReportLineKey = 101) ────────────────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(200, 101), (210, 101), (220, 101), (230, 101);

-- ── Financial Assets  (ReportLineKey = 102) ───────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(300, 102), (310, 102);

-- ── Inventories  (ReportLineKey = 104) ───────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(1200, 104), (1210, 104), (1220, 104);

-- ── Accounts Receivable  (ReportLineKey = 105) ────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(1300, 105), (1310, 105);

-- ── Cash  (ReportLineKey = 106) ───────────────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(1400, 106), (1410, 106);

-- ── Other Current Assets  (ReportLineKey = 107) ───────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(1500, 107), (1510, 107);

-- ── Share Capital  (ReportLineKey = 110) ─────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3600, 110), (3610, 110);

-- ── Retained Earnings  (ReportLineKey = 111) ─────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3700, 111), (3710, 111);

-- ── Long-Term Debt  (ReportLineKey = 113) ────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3000, 113), (3010, 113);

-- ── Other Non-Current Liabilities  (ReportLineKey = 114) ─────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3100, 114), (3110, 114);

-- ── Accounts Payable  (ReportLineKey = 116) ───────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3300, 116), (3310, 116);

-- ── Short-Term Debt  (ReportLineKey = 117) ────────────────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3400, 117), (3410, 117);

-- ── Other Current Liabilities  (ReportLineKey = 118) ─────────────────────────
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(3500, 118), (3510, 118);
