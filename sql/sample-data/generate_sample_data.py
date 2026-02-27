"""
generate_sample_data.py
=======================
Generates Fact_Balance INSERT statements for the DemoManufaktur GmbH Group demo dataset.

Outputs:
  05a_Seed_Fact_Balance_HQ.sql
  05b_Seed_Fact_Balance_US.sql
  05c_Seed_Fact_Balance_APAC.sql

Sign convention:
  Revenue / income accounts (SignConvention=-1): stored as NEGATIVE in GL
  Expense / asset accounts  (SignConvention= 1): stored as POSITIVE in GL
  BS liability/equity       (SignConvention=-1): stored as NEGATIVE in GL

Run:  python generate_sample_data.py
"""

import random
import os
import math

random.seed(42)

# ---------------------------------------------------------------------------
# Output directory (same folder as this script)
# ---------------------------------------------------------------------------
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------
# Periods: 202401 … 202512
# ---------------------------------------------------------------------------
PERIODS_2024 = [202400 + m for m in range(1, 13)]
PERIODS_2025 = [202500 + m for m in range(1, 13)]
ALL_PERIODS  = PERIODS_2024 + PERIODS_2025

def period_month(pk):
    return pk % 100   # 1-12

def period_year(pk):
    return pk // 100  # 2024 or 2025

# ---------------------------------------------------------------------------
# Monthly seasonality factors (sum = 1.00)
# ---------------------------------------------------------------------------
MONTHLY_FACTORS = [0.06, 0.07, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.12]
_monthly_factors_sum = sum(MONTHLY_FACTORS)
if abs(_monthly_factors_sum - 1.0) >= 1e-9:
    raise ValueError(
        f"MONTHLY_FACTORS must sum to 1.0, got {_monthly_factors_sum:.4f}"
    )

# ---------------------------------------------------------------------------
# P&L account definitions
# (account_key, sign_convention, annual_display_amount_HQ_2024_ACT)
# display_amount = what appears in the P&L report (always positive for income
# and expenses).  GL storage = display_amount * sign_convention (flipped by
# the ReportLine SignConvention during aggregation in Power BI).
# ---------------------------------------------------------------------------
PL_ACCOUNTS = {
    # Sales (SignConvention=-1 → GL = -display)
    4000: (-1, 20_000_000),
    4001: (-1, 15_000_000),
    4100: (-1,  8_000_000),
    4200: (-1,  4_000_000),
    4500: (-1,  2_000_000),
    4900: (-1,  1_000_000),
    # COGS (SignConvention=1 → GL = +display)
    5000: ( 1, 12_000_000),
    5100: ( 1,  8_000_000),
    5200: ( 1,  5_000_000),
    5500: ( 1,  2_000_000),
    5900: ( 1,  1_500_000),
    # Selling Expenses
    6100: ( 1,  1_500_000),
    6110: ( 1,  1_200_000),
    6120: ( 1,    500_000),
    6130: ( 1,    500_000),
    6190: ( 1,    800_000),
    # G&A
    6200: ( 1,  1_200_000),
    6210: ( 1,    800_000),
    6220: ( 1,    600_000),
    6250: ( 1,    500_000),
    6290: ( 1,    400_000),
    # R&D
    6300: ( 1,  1_000_000),
    6310: ( 1,    400_000),
    6320: ( 1,    500_000),
    6390: ( 1,    350_000),
    # D&A
    6400: ( 1,    400_000),
    6410: ( 1,  1_200_000),
    6420: ( 1,    500_000),
    6490: ( 1,    400_000),
    # Other Op Income (SignConvention=-1 → GL = -display)
    7000: (-1,    200_000),
    7010: (-1,    100_000),
    7050: (-1,    150_000),
    7090: (-1,     50_000),
    # Other Op Expenses
    7100: ( 1,    100_000),
    7110: ( 1,          0),
    7150: ( 1,     50_000),
    7190: ( 1,     50_000),
    # Result from Investments (SignConvention=-1 → GL = -display; income = positive display)
    7200: (-1,    200_000),
    7210: (-1,    100_000),
    7250: (-1,     50_000),
    7290: (-1,          0),
    # Interest Result (SignConvention=-1)
    # interest income → positive display → GL negative
    # interest expense → negative display (cost) → GL positive
    7300: (-1,    100_000),   # income   → GL -100K
    7310: (-1,   -600_000),   # expense  → GL +600K (negative display × -1 = positive GL)
    7350: (-1,   -100_000),   # FX cost  → GL +100K
    7390: (-1,    -50_000),   # other cost → GL +50K
    # Tax (SignConvention=1)
    7800: ( 1,  1_200_000),
    7810: ( 1,    200_000),
    7820: ( 1,    300_000),
    7850: ( 1,     50_000),
    7890: ( 1,     50_000),
}

# ---------------------------------------------------------------------------
# Scenario multipliers applied to annual base amounts  (revenue / cost split)
# ---------------------------------------------------------------------------
SCENARIO_MULTIPLIERS = {
    # ScenarioKey: (rev_mult, cost_mult)
    1: (1.00, 1.00),   # ACT
    2: (1.05, 1.03),   # BUD – slightly optimistic
    3: (0.98, 1.01),   # FC  – slightly below budget
    4: (0.93, 0.95),   # PY  – prior year was smaller
}

# 2025 growth on top of 2024_ACT base
GROWTH_2025 = {
    1: (1.06, 1.04),   # ACT 2025 = 2024_ACT * 1.06 / 1.04
    2: (1.10, 1.07),   # BUD 2025
    3: (1.04, 1.05),   # FC  2025
    4: (1.00, 1.00),   # PY  2025 = 2024_ACT (copy prior year)
}

# ---------------------------------------------------------------------------
# Entity definitions
# ---------------------------------------------------------------------------
ENTITIES = {
    1: {"code": "HQ",   "scale": 1.00, "fx": 1.00},
    2: {"code": "US",   "scale": 0.60, "fx": 0.92},
    3: {"code": "APAC", "scale": 0.30, "fx": 0.69},
}

# ---------------------------------------------------------------------------
# BS account base balances  (HQ, ACT, period-end stock; negative = credit)
# ---------------------------------------------------------------------------
BS_ACCOUNTS = {
    # Non-Current Assets (positive)
    100: 15_000_000, 110:  8_000_000, 120:  3_000_000,
    200: 12_000_000, 210: 18_000_000, 220:  2_000_000, 230:  4_000_000,
    300:  5_000_000, 310:  2_000_000,
    # Current Assets (positive)
    1200:  3_000_000, 1210:  2_000_000, 1220:  4_000_000,
    1300:  8_000_000, 1310:  1_500_000,
    1400:  6_000_000, 1410:    100_000,
    1500:  1_000_000, 1510:    800_000,
    # Equity (negative = credit balance)
    3600: -10_000_000, 3610:  -5_000_000,
    3700: -20_000_000, 3710:          0,  # 3710 accumulates P&L
    # Non-Current Liabilities (negative)
    3000: -15_000_000, 3010:  -5_000_000,
    3100:  -3_000_000, 3110:  -2_000_000,
    # Current Liabilities (negative)
    3300:  -5_000_000, 3310:  -2_000_000,
    3400:  -1_000_000, 3410:  -3_000_000,
    3500:  -1_500_000, 3510:  -1_000_000,
}

# Which BS accounts are equity/liability (negative GL, credit balances)
BS_CREDIT_ACCOUNTS = {3600, 3610, 3700, 3710, 3000, 3010, 3100, 3110,
                      3300, 3310, 3400, 3410, 3500, 3510}


def jitter_factor(pct=0.03):
    """Return a random multiplier within ±pct of 1.0 (e.g. 0.97–1.03)."""
    return 1.0 + random.uniform(-pct, pct)


def annual_pl_gl(account_key, scenario_key, year, entity_scale, entity_fx):
    """
    Return the annual GL amount for a P&L account.
    sign_conv=-1 → GL = -display_amount  (revenue stored negative)
    sign_conv= 1 → GL = +display_amount  (expense stored positive)
    """
    sign_conv, base_display = PL_ACCOUNTS[account_key]
    is_revenue = (sign_conv == -1)

    # 2024 ACT base
    base = base_display

    if year == 2024:
        rev_m, cost_m = SCENARIO_MULTIPLIERS[scenario_key]
        mult = rev_m if is_revenue else cost_m
    else:  # 2025
        rev_m24, cost_m24 = SCENARIO_MULTIPLIERS[scenario_key]
        rev_g, cost_g = GROWTH_2025[scenario_key]
        if scenario_key == 4:
            # PY 2025 = ACT 2024
            rev_m, cost_m = SCENARIO_MULTIPLIERS[1]
            mult = rev_m if is_revenue else cost_m
        else:
            mult = (rev_m24 * rev_g) if is_revenue else (cost_m24 * cost_g)

    annual_display = base * mult * entity_scale * jitter_factor(0.03)
    # Convert display → GL storage (sign_conv is already -1 or 1)
    gl_annual = annual_display * sign_conv
    return gl_annual


def monthly_pl_rows(entity_key, scenario_key):
    """Yield (entity_key, scenario_key, account_key, period_key, amount, amount_lc) for P&L."""
    entity = ENTITIES[entity_key]
    fx = entity["fx"]
    scale = entity["scale"]

    for account_key in PL_ACCOUNTS:
        for year in (2024, 2025):
            gl_annual = annual_pl_gl(account_key, scenario_key, year, scale, fx)
            periods = PERIODS_2024 if year == 2024 else PERIODS_2025
            for pk in periods:
                m = period_month(pk) - 1  # 0-based index
                monthly_gl = gl_annual * MONTHLY_FACTORS[m] * jitter_factor(0.02)
                amount_eur = round(monthly_gl, 2)
                amount_lc  = round(monthly_gl / fx, 2) if fx != 1.0 else amount_eur
                yield (entity_key, scenario_key, account_key, pk, amount_eur, amount_lc)


def bs_balance(account_key, scenario_key, period_key, entity_scale, entity_fx,
               cumulative_pl_eur):
    """
    Return (amount_eur, amount_lc) for a BS account stock balance.
    cumulative_pl_eur = running sum of all P&L GL amounts up to this period (EUR).
    """
    base = BS_ACCOUNTS[account_key]

    # Scenario slight adjustment
    scenario_adj = {1: 1.00, 2: 1.02, 3: 0.99, 4: 0.96}[scenario_key]
    year = period_year(period_key)
    year_adj = 1.06 if year == 2025 else 1.0

    if account_key == 3710:
        # Current Year Profit accumulates the P&L net result
        amount_eur = round(cumulative_pl_eur * scenario_adj, 2)
    else:
        # Mild monthly drift ±2%
        amount_eur = round(base * entity_scale * scenario_adj * year_adj * jitter_factor(0.02), 2)

    amount_lc = round(amount_eur / entity_fx, 2) if entity_fx != 1.0 else amount_eur
    return amount_eur, amount_lc


def monthly_bs_rows(entity_key, scenario_key, pl_rows_by_period):
    """
    Yield BS rows. pl_rows_by_period = dict[period_key -> list of GL amounts].
    """
    entity = ENTITIES[entity_key]
    fx = entity["fx"]
    scale = entity["scale"]

    # Build cumulative P&L net result per year (running total within each year)
    cumulative = {2024: 0.0, 2025: 0.0}

    all_periods_sorted = sorted(ALL_PERIODS)
    for pk in all_periods_sorted:
        year = period_year(pk)
        # Add this month's P&L net to the cumulative (resets on Jan of each year)
        if period_month(pk) == 1:
            cumulative[year] = 0.0
        month_pl_net = sum(pl_rows_by_period.get(pk, []))
        cumulative[year] += month_pl_net

        for account_key in BS_ACCOUNTS:
            cum_pl = cumulative[year]
            amount_eur, amount_lc = bs_balance(
                account_key, scenario_key, pk, scale, fx, cum_pl
            )
            yield (entity_key, scenario_key, account_key, pk, amount_eur, amount_lc)


# ---------------------------------------------------------------------------
# SQL writer
# ---------------------------------------------------------------------------
BATCH_SIZE = 50

def write_sql_file(filepath, entity_key, entity_code, rows_iter):
    """Write INSERT statements in batches of BATCH_SIZE."""
    header = f"""\
-- =============================================================================
-- {os.path.basename(filepath)}
-- Fact_Balance seed data – Entity: {entity_code} (EntityKey={entity_key})
-- Generated by generate_sample_data.py (fixed seed=42)
-- DO NOT EDIT MANUALLY – regenerate via the Python script.
-- =============================================================================

"""
    batch = []
    current_scenario = None
    file_lines = [header]

    def flush_batch():
        nonlocal batch
        if not batch:
            return
        vals = ",\n".join(
            f"({r[0]}, {r[1]}, {r[2]}, {r[3]}, {r[4]:.2f}, {r[5]:.2f})"
            for r in batch
        )
        file_lines.append(
            "INSERT INTO Fact_Balance "
            "(EntityKey, ScenarioKey, AccountKey, PeriodKey, Amount, AmountLC) VALUES\n"
            + vals + ";\n\n"
        )
        batch = []

    scenario_names = {1: "ACT", 2: "BUD", 3: "FC", 4: "PY"}

    for row in rows_iter:
        sc = row[1]
        if sc != current_scenario:
            flush_batch()
            current_scenario = sc
            file_lines.append(
                f"-- Entity {entity_key} ({entity_code}), "
                f"Scenario {sc} ({scenario_names[sc]})\n"
            )
        batch.append(row)
        if len(batch) >= BATCH_SIZE:
            flush_batch()

    flush_batch()

    with open(filepath, "w", encoding="utf-8") as f:
        f.writelines(file_lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def generate_entity(entity_key):
    entity = ENTITIES[entity_key]
    code = entity["code"]

    all_rows = []
    for scenario_key in (1, 2, 3, 4):
        # Collect P&L rows
        pl_rows = list(monthly_pl_rows(entity_key, scenario_key))
        # Index P&L amounts by period for cumulative P&L calculation
        pl_by_period = {}
        for r in pl_rows:
            pl_by_period.setdefault(r[3], []).append(r[4])  # r[4] = Amount EUR

        bs_rows = list(monthly_bs_rows(entity_key, scenario_key, pl_by_period))
        all_rows.extend(pl_rows)
        all_rows.extend(bs_rows)

    # Sort: scenario → account → period for a clean output
    all_rows.sort(key=lambda r: (r[1], r[2], r[3]))

    suffix = {1: "05a", 2: "05b", 3: "05c"}[entity_key]
    filename = f"{suffix}_Seed_Fact_Balance_{code}.sql"
    filepath = os.path.join(OUT_DIR, filename)
    write_sql_file(filepath, entity_key, code, iter(all_rows))
    return all_rows, filepath


def summarise(entity_key, rows):
    """Print key P&L KPIs for ACT 2024."""
    REVENUE_ACCS = {4000, 4001, 4100, 4200, 4500, 4900}
    COGS_ACCS    = {5000, 5100, 5200, 5500, 5900}
    EBIT_EXCL    = {7800, 7810, 7820, 7850, 7890,   # tax
                    7200, 7210, 7250, 7290,           # fin result investments
                    7300, 7310, 7350, 7390}           # interest result

    revenue_gl = sum(r[4] for r in rows
                     if r[1] == 1 and r[2] in REVENUE_ACCS and period_year(r[3]) == 2024)
    cogs_gl    = sum(r[4] for r in rows
                     if r[1] == 1 and r[2] in COGS_ACCS    and period_year(r[3]) == 2024)
    pl_net_gl  = sum(r[4] for r in rows
                     if r[1] == 1 and r[2] in PL_ACCOUNTS  and period_year(r[3]) == 2024)
    ebit_gl    = sum(r[4] for r in rows
                     if r[1] == 1 and r[2] in PL_ACCOUNTS
                     and r[2] not in EBIT_EXCL
                     and period_year(r[3]) == 2024)

    # Display = GL * -1 for revenue (SignConvention=-1), GL * 1 for expenses
    rev_display  = -revenue_gl
    cogs_display =  cogs_gl
    gp_display   = rev_display - cogs_display
    ebit_display = -ebit_gl   # entire EBIT net: flip sign of net GL
    ni_display   = -pl_net_gl

    entity_code = ENTITIES[entity_key]["code"]
    print(f"\n{'='*55}")
    print(f"  {entity_code} (EntityKey={entity_key}) — ACT 2024 Summary")
    print(f"{'='*55}")
    print(f"  Revenue    : EUR {rev_display/1e6:>8.2f} M")
    print(f"  Gross Profit: EUR {gp_display/1e6:>8.2f} M  ({gp_display/rev_display*100:.1f}%)")
    print(f"  EBIT       : EUR {ebit_display/1e6:>8.2f} M  ({ebit_display/rev_display*100:.1f}%)")
    print(f"  Net Income : EUR {ni_display/1e6:>8.2f} M  ({ni_display/rev_display*100:.1f}%)")


if __name__ == "__main__":
    total_rows = 0
    all_entity_rows = {}

    for ek in (1, 2, 3):
        rows, fp = generate_entity(ek)
        all_entity_rows[ek] = rows
        total_rows += len(rows)
        print(f"Written {len(rows):,} rows → {fp}")

    for ek in (1, 2, 3):
        summarise(ek, all_entity_rows[ek])

    # Group consolidated revenue (ACT 2024)
    REVENUE_ACCS = {4000, 4001, 4100, 4200, 4500, 4900}
    group_rev = sum(
        -r[4]
        for ek in (1, 2, 3)
        for r in all_entity_rows[ek]
        if r[1] == 1 and r[2] in REVENUE_ACCS and period_year(r[3]) == 2024
    )
    print(f"\n{'='*55}")
    print(f"  GROUP CONSOLIDATED — ACT 2024 Revenue: EUR {group_rev/1e6:.2f} M")
    print(f"{'='*55}")
    print(f"\nTotal rows generated: {total_rows:,}")
