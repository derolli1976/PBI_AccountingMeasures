-- =============================================================================
-- 04_Map_Account_ReportLine.sql
-- DDL + Beispiel-Mappings: Brückentabelle Konto → Berichtszeile
-- Maps individual GL accounts (AccountKey) to report lines (ReportLineKey).
-- MappingWeight allows partial allocations (e.g. 0.5 for split postings).
-- =============================================================================

CREATE TABLE Map_Account_ReportLine (
    AccountKey      INT             NOT NULL,
    ReportLineKey   INT             NOT NULL,
    -- Weight applied during pre-aggregation (1.0 = full amount, 0.5 = 50%)
    MappingWeight   DECIMAL(5,4)    DEFAULT 1.0,

    CONSTRAINT PK_Map_Account_ReportLine PRIMARY KEY (AccountKey, ReportLineKey),
    CONSTRAINT FK_Map_ReportLine FOREIGN KEY (ReportLineKey)
        REFERENCES Dim_ReportLine (ReportLineKey)
);

-- =============================================================================
-- Beispiel-Mappings (Example account range → ReportLineKey)
-- Adjust AccountKey values to match your chart of accounts.
-- =============================================================================

-- ── Sales  (ReportLineKey = 1) ────────────────────────────────────────────────
-- Accounts 4000–4999
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(4000, 1), (4001, 1), (4100, 1), (4200, 1), (4500, 1), (4900, 1);

-- ── Cost of Sales  (ReportLineKey = 2) ───────────────────────────────────────
-- Accounts 5000–5999
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(5000, 2), (5100, 2), (5200, 2), (5500, 2), (5900, 2);

-- ── Selling Expenses  (ReportLineKey = 4) ────────────────────────────────────
-- Accounts 6100–6199
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(6100, 4), (6110, 4), (6120, 4), (6130, 4), (6190, 4);

-- ── General & Administration  (ReportLineKey = 5) ────────────────────────────
-- Accounts 6200–6299
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(6200, 5), (6210, 5), (6220, 5), (6250, 5), (6290, 5);

-- ── Research & Development  (ReportLineKey = 6) ──────────────────────────────
-- Accounts 6300–6399
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(6300, 6), (6310, 6), (6320, 6), (6390, 6);

-- ── Other Operating Income  (ReportLineKey = 8) ──────────────────────────────
-- Accounts 7000–7099
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(7000, 8), (7010, 8), (7050, 8), (7090, 8);

-- ── Other Operating Expenses  (ReportLineKey = 9) ────────────────────────────
-- Accounts 7100–7199
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(7100, 9), (7110, 9), (7150, 9), (7190, 9);

-- ── D&A  (ReportLineKey = 11) ─────────────────────────────────────────────────
-- Accounts 6400–6499
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(6400, 11), (6410, 11), (6420, 11), (6490, 11);

-- ── Result from Investments  (ReportLineKey = 13) ────────────────────────────
-- Accounts 7200–7299
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(7200, 13), (7210, 13), (7250, 13), (7290, 13);

-- ── Interest Result  (ReportLineKey = 14) ────────────────────────────────────
-- Accounts 7300–7399
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(7300, 14), (7310, 14), (7350, 14), (7390, 14);

-- ── Tax  (ReportLineKey = 17) ─────────────────────────────────────────────────
-- Accounts 7800–7899
INSERT INTO Map_Account_ReportLine (AccountKey, ReportLineKey) VALUES
(7800, 17), (7810, 17), (7820, 17), (7890, 17);
