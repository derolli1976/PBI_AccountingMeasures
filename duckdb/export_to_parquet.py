#!/usr/bin/env python3
"""
export_to_parquet.py
====================
Exports all tables from demo.duckdb to Parquet files in the ./parquet/ folder.

Parquet files can be loaded directly into Power BI Desktop via
  Home → Get Data → Parquet

Usage:
    cd duckdb
    python export_to_parquet.py [--db PATH] [--out DIR]
"""

import argparse
import os
import sys

try:
    import duckdb
except ImportError:
    print("ERROR: duckdb package not found. Run: pip install -r requirements.txt")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

TABLES = [
    "Dim_Entity",
    "Dim_Scenario",
    "Dim_Period",
    "Dim_Account",
    "Dim_ReportLine",
    "Map_Account_ReportLine",
    "Fact_Balance",
    "Fact_ReportLine_Balance",
]


def export_tables(db_path: str, out_dir: str) -> None:
    if not os.path.exists(db_path):
        print(f"ERROR: Database not found: {db_path}")
        print("Run setup_duckdb.py first to create the database.")
        sys.exit(1)

    os.makedirs(out_dir, exist_ok=True)

    print(f"Opening database: {db_path}")
    con = duckdb.connect(db_path, read_only=True)

    try:
        print(f"Exporting tables to: {out_dir}\n")
        for table in TABLES:
            out_file = os.path.join(out_dir, f"{table}.parquet")
            con.execute(f"COPY {table} TO '{out_file}' (FORMAT PARQUET)")
            row = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()
            n = row[0] if row else 0
            print(f"  ✓ {table:<26s} → {os.path.basename(out_file)}  ({n:,} rows)")
    except Exception as exc:
        print(f"\nERROR: {exc}")
        sys.exit(1)
    finally:
        con.close()

    print(f"\n✅ Export complete. {len(TABLES)} Parquet files written to: {out_dir}")
    print("\nNext step – load in Power BI Desktop:")
    print("  Home → Get Data → Parquet → select each file in the parquet/ folder")


def main() -> None:
    parser = argparse.ArgumentParser(description="Export DuckDB tables to Parquet")
    parser.add_argument(
        "--db",
        default=os.path.join(SCRIPT_DIR, "demo.duckdb"),
        help="Path to the DuckDB database file (default: duckdb/demo.duckdb)",
    )
    parser.add_argument(
        "--out",
        default=os.path.join(SCRIPT_DIR, "parquet"),
        help="Output directory for Parquet files (default: duckdb/parquet/)",
    )
    args = parser.parse_args()
    export_tables(args.db, args.out)


if __name__ == "__main__":
    main()
