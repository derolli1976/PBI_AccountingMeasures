#!/usr/bin/env python3
"""
setup_duckdb.py
===============
Creates a local DuckDB database (demo.duckdb) containing the full
PBI_AccountingMeasures demo data model.

Usage:
    cd duckdb
    pip install -r requirements.txt
    python setup_duckdb.py [--db PATH]

The script:
  1. Creates (or replaces) demo.duckdb
  2. Creates all tables with DuckDB-compatible DDL
  3. Loads all seed data from ../sql/ and ../sql/sample-data/
  4. Builds Fact_ReportLine_Balance via pre-aggregation query
  5. Prints a summary with table sizes and a P&L sample
"""

import argparse
import os
import re
import sys

try:
    import duckdb
except ImportError:
    print("ERROR: duckdb package not found. Run: pip install -r requirements.txt")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
SQL_DIR = os.path.join(REPO_ROOT, "sql")
SAMPLE_DIR = os.path.join(SQL_DIR, "sample-data")

# ---------------------------------------------------------------------------
# DuckDB-compatible DDL
# DuckDB uses BOOLEAN instead of BIT; all other standard SQL types are fine.
# ---------------------------------------------------------------------------

DDL_STATEMENTS = [
    # Dim_Entity
    """
    CREATE TABLE IF NOT EXISTS Dim_Entity (
        EntityKey   INTEGER     NOT NULL,
        EntityCode  VARCHAR(20) NOT NULL,
        EntityName  VARCHAR(100) NOT NULL,
        Region      VARCHAR(50),
        Country     VARCHAR(50),
        EntityType  VARCHAR(50),
        PRIMARY KEY (EntityKey)
    )
    """,

    # Dim_Scenario
    """
    CREATE TABLE IF NOT EXISTS Dim_Scenario (
        ScenarioKey  INTEGER     NOT NULL,
        ScenarioCode VARCHAR(20) NOT NULL,
        ScenarioName VARCHAR(100) NOT NULL,
        PRIMARY KEY (ScenarioKey)
    )
    """,

    # Dim_Period
    """
    CREATE TABLE IF NOT EXISTS Dim_Period (
        PeriodKey    INTEGER     NOT NULL,
        FiscalYear   INTEGER     NOT NULL,
        FiscalPeriod INTEGER     NOT NULL,
        Quarter      VARCHAR(2)  NOT NULL,
        YearMonth    VARCHAR(7)  NOT NULL,
        PeriodName   VARCHAR(20) NOT NULL,
        PRIMARY KEY (PeriodKey)
    )
    """,

    # Dim_Account
    """
    CREATE TABLE IF NOT EXISTS Dim_Account (
        AccountKey     INTEGER      NOT NULL,
        AccountCode    VARCHAR(20)  NOT NULL,
        AccountName    VARCHAR(100) NOT NULL,
        L1_Category    VARCHAR(100),
        L2_Subcategory VARCHAR(100),
        L3_Detail      VARCHAR(100),
        AccountType    VARCHAR(5)   NOT NULL,
        SignConvention INTEGER      NOT NULL DEFAULT 1,
        PRIMARY KEY (AccountKey)
    )
    """,

    # Dim_ReportLine  -- BIT columns replaced with INTEGER
    """
    CREATE TABLE IF NOT EXISTS Dim_ReportLine (
        ReportLineKey  INTEGER      NOT NULL,
        ReportType     VARCHAR(20)  NOT NULL,
        LineItem       VARCHAR(100) NOT NULL,
        SortOrder      INTEGER      NOT NULL,
        LineType       VARCHAR(20)  NOT NULL,
        CalcFormula    VARCHAR(500),
        CalcOperands   VARCHAR(500),
        PercentageBase VARCHAR(100),
        IsBold         INTEGER      DEFAULT 0,
        IsSubtotal     INTEGER      DEFAULT 0,
        IndentLevel    INTEGER      DEFAULT 0,
        SignConvention INTEGER      DEFAULT 1,
        AccountFilter  VARCHAR(500),
        PRIMARY KEY (ReportLineKey)
    )
    """,

    # Fact_Balance
    """
    CREATE TABLE IF NOT EXISTS Fact_Balance (
        EntityKey   INTEGER        NOT NULL,
        ScenarioKey INTEGER        NOT NULL,
        AccountKey  INTEGER        NOT NULL,
        PeriodKey   INTEGER        NOT NULL,
        Amount      DECIMAL(18,2)  NOT NULL DEFAULT 0,
        AmountLC    DECIMAL(18,2)  NOT NULL DEFAULT 0,
        PRIMARY KEY (EntityKey, ScenarioKey, AccountKey, PeriodKey),
        FOREIGN KEY (EntityKey)   REFERENCES Dim_Entity   (EntityKey),
        FOREIGN KEY (ScenarioKey) REFERENCES Dim_Scenario (ScenarioKey),
        FOREIGN KEY (AccountKey)  REFERENCES Dim_Account  (AccountKey),
        FOREIGN KEY (PeriodKey)   REFERENCES Dim_Period   (PeriodKey)
    )
    """,

    # Map_Account_ReportLine
    """
    CREATE TABLE IF NOT EXISTS Map_Account_ReportLine (
        AccountKey    INTEGER       NOT NULL,
        ReportLineKey INTEGER       NOT NULL,
        MappingWeight DECIMAL(5,4)  DEFAULT 1.0,
        PRIMARY KEY (AccountKey, ReportLineKey),
        FOREIGN KEY (ReportLineKey) REFERENCES Dim_ReportLine (ReportLineKey)
    )
    """,
]

# Pre-aggregation query – identical to sql/05_Fact_ReportLine_Balance.sql
FACT_REPORTLINE_BALANCE_SQL = """
CREATE OR REPLACE TABLE Fact_ReportLine_Balance AS
SELECT
    m.ReportLineKey,
    f.EntityKey,
    f.ScenarioKey,
    f.PeriodKey,
    rl.SignConvention * SUM(f.Amount    * m.MappingWeight) AS Amount,
    rl.SignConvention * SUM(f.AmountLC  * m.MappingWeight) AS AmountLC
FROM Fact_Balance           f
JOIN Map_Account_ReportLine m  ON f.AccountKey    = m.AccountKey
JOIN Dim_ReportLine         rl ON m.ReportLineKey = rl.ReportLineKey
WHERE rl.LineType = 'DATA'
GROUP BY
    m.ReportLineKey,
    f.EntityKey,
    f.ScenarioKey,
    f.PeriodKey,
    rl.SignConvention
"""

# ---------------------------------------------------------------------------
# Seed SQL files to load (in order)
# ---------------------------------------------------------------------------
SEED_FILES = [
    # Dimensions
    os.path.join(SAMPLE_DIR, "01_Seed_Dim_Entity.sql"),
    os.path.join(SAMPLE_DIR, "02_Seed_Dim_Scenario.sql"),
    os.path.join(SAMPLE_DIR, "03_Seed_Dim_Period.sql"),
    os.path.join(SAMPLE_DIR, "04_Seed_Dim_Account.sql"),
    # ReportLine definitions
    os.path.join(SQL_DIR,    "02_Seed_PL_ReportLines.sql"),
    os.path.join(SQL_DIR,    "03_Seed_BS_ReportLines.sql"),
    # Account → ReportLine mappings
    os.path.join(SQL_DIR,    "04_Map_Account_ReportLine.sql"),
    os.path.join(SAMPLE_DIR, "06_Map_Account_ReportLine_BS.sql"),
    # Fact data (large files – loaded last)
    os.path.join(SAMPLE_DIR, "05a_Seed_Fact_Balance_HQ.sql"),
    os.path.join(SAMPLE_DIR, "05b_Seed_Fact_Balance_US.sql"),
    os.path.join(SAMPLE_DIR, "05c_Seed_Fact_Balance_APAC.sql"),
]


def extract_dml_statements(sql_text: str) -> list[str]:
    """
    Extract only DML (INSERT / UPDATE / DELETE) statements from a SQL file,
    skipping DDL (CREATE TABLE, ALTER TABLE, …) and comments.

    Returns a list of individual SQL statements (without trailing semicolons).
    """
    # Remove single-line comments
    sql_text = re.sub(r"--[^\n]*", "", sql_text)
    # Remove multi-line comments
    sql_text = re.sub(r"/\*.*?\*/", "", sql_text, flags=re.DOTALL)

    # Split on semicolons
    raw_stmts = sql_text.split(";")

    dml = []
    for stmt in raw_stmts:
        stmt = stmt.strip()
        if not stmt:
            continue
        upper = stmt.upper().lstrip()
        # Keep INSERT / UPDATE / DELETE; skip CREATE / ALTER / DROP / SET / GO
        if upper.startswith("INSERT") or upper.startswith("UPDATE") or upper.startswith("DELETE"):
            dml.append(stmt)
    return dml


def load_sql_file(con: duckdb.DuckDBPyConnection, filepath: str) -> int:
    """Load a SQL seed file, executing only DML statements. Returns statement count."""
    with open(filepath, "r", encoding="utf-8") as fh:
        content = fh.read()

    stmts = extract_dml_statements(content)
    for stmt in stmts:
        con.execute(stmt)
    return len(stmts)


def create_tables(con: duckdb.DuckDBPyConnection) -> None:
    print("Creating tables …")
    for ddl in DDL_STATEMENTS:
        con.execute(ddl)
    print("  ✓ All tables created")


def load_seed_data(con: duckdb.DuckDBPyConnection) -> None:
    print("\nLoading seed data …")
    for filepath in SEED_FILES:
        if not os.path.exists(filepath):
            print(f"  WARNING: file not found – {filepath}")
            continue
        name = os.path.basename(filepath)
        count = load_sql_file(con, filepath)
        print(f"  ✓ {name:<45s} ({count} statement(s))")


def build_aggregation(con: duckdb.DuckDBPyConnection) -> None:
    print("\nBuilding Fact_ReportLine_Balance …")
    con.execute(FACT_REPORTLINE_BALANCE_SQL)
    print("  ✓ Pre-aggregation complete")


def print_summary(con: duckdb.DuckDBPyConnection, db_path: str) -> None:
    tables = [
        "Dim_Entity",
        "Dim_Scenario",
        "Dim_Period",
        "Dim_Account",
        "Dim_ReportLine",
        "Map_Account_ReportLine",
        "Fact_Balance",
        "Fact_ReportLine_Balance",
    ]

    print(f"\n✅ DuckDB database created: {db_path}")
    print("\nTable sizes:")
    for tbl in tables:
        row = con.execute(f"SELECT COUNT(*) FROM {tbl}").fetchone()
        n = row[0] if row else 0
        print(f"  {tbl:<26s}: {n:>8,} rows")

    # P&L sample: HQ (EntityKey=1), Actual (ScenarioKey=1), FY 2024
    print("\nSample P&L (HQ, Actual, full year 2024):")
    sample_sql = """
    SELECT
        rl.LineItem,
        SUM(frb.Amount) AS TotalAmount
    FROM Fact_ReportLine_Balance frb
    JOIN Dim_ReportLine          rl  ON frb.ReportLineKey = rl.ReportLineKey
    WHERE frb.EntityKey   = 1
      AND frb.ScenarioKey = 1
      AND frb.PeriodKey BETWEEN 202401 AND 202412
      AND rl.ReportType  = 'PL'
      AND rl.LineType    = 'DATA'
    GROUP BY rl.LineItem, rl.SortOrder
    ORDER BY rl.SortOrder
    """
    rows = con.execute(sample_sql).fetchall()
    for line_item, amount in rows:
        print(f"  {line_item:<35s}: {amount:>15,.0f}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Create DuckDB demo database")
    parser.add_argument(
        "--db",
        default=os.path.join(SCRIPT_DIR, "demo.duckdb"),
        help="Path for the DuckDB database file (default: duckdb/demo.duckdb)",
    )
    args = parser.parse_args()

    db_path = args.db

    # Remove existing database so we start fresh
    for suffix in ("", ".wal"):
        p = db_path + suffix if suffix else db_path
        if os.path.exists(p):
            os.remove(p)
            print(f"Removed existing file: {p}")

    print(f"Creating DuckDB database: {db_path}\n")

    try:
        con = duckdb.connect(db_path)
    except Exception as exc:
        print(f"ERROR: Could not open database: {exc}")
        sys.exit(1)

    try:
        create_tables(con)
        load_seed_data(con)
        build_aggregation(con)
        print_summary(con, db_path)
    except Exception as exc:
        print(f"\nERROR: {exc}")
        con.close()
        sys.exit(1)
    finally:
        con.close()


if __name__ == "__main__":
    main()
