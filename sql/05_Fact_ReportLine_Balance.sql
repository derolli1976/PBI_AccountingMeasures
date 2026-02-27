-- =============================================================================
-- 05_Fact_ReportLine_Balance.sql
-- Pre-aggregation: Voraggregierte Fakten pro Berichtszeile
-- Aggregates Fact_Balance at the ReportLine level so that Direct Lake queries
-- touch fewer rows and DAX measures remain simple.
-- Only DATA lines are aggregated here; CALCULATED and PERCENTAGE lines are
-- derived entirely in DAX using the LineValue measure.
-- =============================================================================

CREATE OR REPLACE TABLE Fact_ReportLine_Balance AS
SELECT
    m.ReportLineKey,
    f.EntityKey,
    f.ScenarioKey,
    f.PeriodKey,
    -- Apply sign convention so all values are display-ready (positive = good)
    rl.SignConvention * SUM(f.Amount * m.MappingWeight)     AS Amount,
    rl.SignConvention * SUM(f.AmountLC * m.MappingWeight)   AS AmountLC
FROM Fact_Balance               f
JOIN Map_Account_ReportLine     m   ON f.AccountKey     = m.AccountKey
JOIN Dim_ReportLine             rl  ON m.ReportLineKey  = rl.ReportLineKey
WHERE rl.LineType = 'DATA'   -- only raw data lines; calculated lines use DAX
GROUP BY
    m.ReportLineKey,
    f.EntityKey,
    f.ScenarioKey,
    f.PeriodKey,
    rl.SignConvention;
