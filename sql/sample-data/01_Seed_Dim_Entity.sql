-- =============================================================================
-- 01_Seed_Dim_Entity.sql
-- Seed data: Legal entities, business units, and group nodes
-- DemoManufaktur GmbH Group
-- =============================================================================

INSERT INTO Dim_Entity (EntityKey, EntityCode, EntityName, Region, Country, EntityType) VALUES
(1, 'HQ',      'Headquarters GmbH',    'EMEA',     'Germany',   'Legal Entity'),
(2, 'US',      'North America Inc.',   'Americas',  'USA',       'Legal Entity'),
(3, 'APAC',    'Asia Pacific Ltd.',    'APAC',      'Singapore', 'Legal Entity'),
(4, 'EMEA_BU', 'EMEA Business Unit',  'EMEA',      NULL,        'Business Unit'),
(5, 'GROUP',   'Consolidated Group',  'Global',    NULL,        'Group');
