-- =============================================================================
-- 00_Schema_All_Tables.sql
-- DDL: Sample-data schema for the financial reporting demo dataset
-- Creates all dimension and fact tables needed for the demo.
-- Run this script FIRST before seeding any data.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dim_Entity: Legal entities, business units, and consolidation nodes
-- -----------------------------------------------------------------------------
CREATE TABLE Dim_Entity (
    EntityKey       INT             NOT NULL,
    EntityCode      VARCHAR(20)     NOT NULL,   -- Short code used in reports
    EntityName      VARCHAR(100)    NOT NULL,   -- Full display name
    Region          VARCHAR(50)     NULL,
    Country         VARCHAR(50)     NULL,
    EntityType      VARCHAR(50)     NULL,       -- 'Legal Entity', 'Business Unit', 'Group'

    CONSTRAINT PK_Dim_Entity PRIMARY KEY (EntityKey)
);

-- -----------------------------------------------------------------------------
-- Dim_Scenario: Planning/reporting scenarios
-- -----------------------------------------------------------------------------
CREATE TABLE Dim_Scenario (
    ScenarioKey     INT             NOT NULL,
    ScenarioCode    VARCHAR(20)     NOT NULL,   -- Short code: ACT, BUD, FC, PY
    ScenarioName    VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_Dim_Scenario PRIMARY KEY (ScenarioKey)
);

-- -----------------------------------------------------------------------------
-- Dim_Period: Calendar / fiscal periods (month grain)
-- -----------------------------------------------------------------------------
CREATE TABLE Dim_Period (
    PeriodKey       INT             NOT NULL,   -- YYYYMM format, e.g. 202401
    FiscalYear      INT             NOT NULL,
    FiscalPeriod    INT             NOT NULL,   -- Month number 1–12
    Quarter         VARCHAR(2)      NOT NULL,   -- Q1 … Q4
    YearMonth       VARCHAR(7)      NOT NULL,   -- 'YYYY-MM'
    PeriodName      VARCHAR(20)     NOT NULL,   -- 'Jan 2024'

    CONSTRAINT PK_Dim_Period PRIMARY KEY (PeriodKey)
);

-- -----------------------------------------------------------------------------
-- Dim_Account: Chart of accounts (P&L and BS accounts)
-- -----------------------------------------------------------------------------
CREATE TABLE Dim_Account (
    AccountKey      INT             NOT NULL,
    AccountCode     VARCHAR(20)     NOT NULL,   -- Formatted account number string
    AccountName     VARCHAR(100)    NOT NULL,
    L1_Category     VARCHAR(100)    NULL,       -- Top-level category (Revenue, Cost of Sales, …)
    L2_Subcategory  VARCHAR(100)    NULL,       -- Sub-category (Net Revenue, Direct Costs, …)
    L3_Detail       VARCHAR(100)    NULL,       -- Detailed grouping label
    AccountType     VARCHAR(5)      NOT NULL,   -- 'PL' = P&L account, 'BS' = Balance Sheet
    -- Sign convention applied when reading from Fact_Balance:
    --  -1 = revenue / income stored as NEGATIVE in GL → flip to positive for display
    --   1 = expense / asset stored as POSITIVE in GL
    SignConvention  INT             NOT NULL    DEFAULT 1,

    CONSTRAINT PK_Dim_Account PRIMARY KEY (AccountKey)
);

-- -----------------------------------------------------------------------------
-- Fact_Balance: GL balances at monthly grain
-- For P&L accounts: monthly posting amount (flow)
-- For BS accounts:  period-end stock balance
-- Amount    = value in reporting currency (EUR)
-- AmountLC  = value in local currency
-- -----------------------------------------------------------------------------
CREATE TABLE Fact_Balance (
    EntityKey       INT             NOT NULL,
    ScenarioKey     INT             NOT NULL,
    AccountKey      INT             NOT NULL,
    PeriodKey       INT             NOT NULL,
    Amount          DECIMAL(18,2)   NOT NULL    DEFAULT 0,
    AmountLC        DECIMAL(18,2)   NOT NULL    DEFAULT 0,

    CONSTRAINT PK_Fact_Balance
        PRIMARY KEY (EntityKey, ScenarioKey, AccountKey, PeriodKey),
    CONSTRAINT FK_Fact_Entity
        FOREIGN KEY (EntityKey)   REFERENCES Dim_Entity   (EntityKey),
    CONSTRAINT FK_Fact_Scenario
        FOREIGN KEY (ScenarioKey) REFERENCES Dim_Scenario (ScenarioKey),
    CONSTRAINT FK_Fact_Account
        FOREIGN KEY (AccountKey)  REFERENCES Dim_Account  (AccountKey),
    CONSTRAINT FK_Fact_Period
        FOREIGN KEY (PeriodKey)   REFERENCES Dim_Period   (PeriodKey)
);
