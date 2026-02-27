-- =============================================================================
-- 02_Seed_Dim_Scenario.sql
-- Seed data: Planning and reporting scenarios
-- =============================================================================

INSERT INTO Dim_Scenario (ScenarioKey, ScenarioCode, ScenarioName) VALUES
(1, 'ACT', 'Actual'),
(2, 'BUD', 'Budget'),
(3, 'FC',  'Forecast'),
(4, 'PY',  'Prior Year');
