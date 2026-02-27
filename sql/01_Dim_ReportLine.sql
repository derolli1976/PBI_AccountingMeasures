-- =============================================================================
-- 01_Dim_ReportLine.sql
-- DDL: Steuerungstabelle für alle Berichtszeilen (P&L, BS, CF, WC, STAT)
-- Core control table – defines every line in every financial report.
-- =============================================================================

CREATE TABLE Dim_ReportLine (
    -- Primary key
    ReportLineKey       INT             NOT NULL,

    -- Report type: 'PL' = P&L, 'BS' = Balance Sheet, 'CF' = Cashflow,
    --              'WC' = Working Capital, 'STAT' = Statistical
    ReportType          VARCHAR(20)     NOT NULL,

    -- Display name shown in the Matrix visual
    LineItem            VARCHAR(100)    NOT NULL,

    -- Controls row order within the report
    SortOrder           INT             NOT NULL,

    -- 'DATA'       – summed directly from Fact_ReportLine_Balance
    -- 'CALCULATED' – computed from other lines (e.g. Gross Profit = Sales + COGS)
    -- 'PERCENTAGE' – ratio relative to a base line (e.g. GP %)
    LineType            VARCHAR(20)     NOT NULL,

    -- Human-readable formula for documentation (e.g. '[Sales] - [Cost of Sales]')
    CalcFormula         VARCHAR(500)    NULL,

    -- JSON reference to operand LineItems used by the DAX SWITCH logic
    -- Example: '{"add":["Sales","Cost of Sales"]}'
    CalcOperands        VARCHAR(500)    NULL,

    -- LineItem name used as denominator for PERCENTAGE lines (e.g. 'Sales')
    PercentageBase      VARCHAR(100)    NULL,

    -- Formatting flags – evaluated in Power BI conditional formatting rules
    IsBold              BIT             DEFAULT 0,   -- 1 = bold font
    IsSubtotal          BIT             DEFAULT 0,   -- 1 = subtotal / separator row
    IndentLevel         INT             DEFAULT 0,   -- 0 = flush left, 1 = one indent, …

    -- Sign convention applied during pre-aggregation:
    --  1 = costs / expenses are positive after sign flip (standard P&L view)
    -- -1 = revenue lines are stored as negative in GL → flip to positive for display
    SignConvention      INT             DEFAULT 1,

    -- Logical mapping key linking this line to accounts in Map_Account_ReportLine
    -- NULL for CALCULATED and PERCENTAGE lines
    AccountFilter       VARCHAR(500)    NULL,

    CONSTRAINT PK_Dim_ReportLine PRIMARY KEY (ReportLineKey)
);
