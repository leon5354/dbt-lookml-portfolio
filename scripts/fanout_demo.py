"""See a fanout with real numbers, and how a primary key fixes it.

Run after `dbt build`: python scripts/fanout_demo.py
"""
from pathlib import Path

import duckdb

db = duckdb.connect(str(Path(__file__).resolve().parent.parent / "dev.duckdb"), read_only=True)

JOIN = "from marts.fct_deals d left join marts.fct_bids b on d.deal_id = b.deal_id"

true_total = db.execute("select sum(net_revenue_gbp) from marts.fct_deals").fetchone()[0]
rows = db.execute(f"select count(*) {JOIN}").fetchone()[0]
naive = db.execute(f"select sum(d.net_revenue_gbp) {JOIN}").fetchone()[0]

# What symmetric aggregates achieve: each deal_id counted once.
# Looker's real SQL is uglier, but the idea is the same.
safe = db.execute(f"""
    select sum(net_revenue_gbp) from (
        select distinct d.deal_id, d.net_revenue_gbp {JOIN}
    )
""").fetchone()[0]

print(f"Rows in fct_deals:           {db.execute('select count(*) from marts.fct_deals').fetchone()[0]}")
print(f"Rows after joining bids:     {rows}   <- the fanout")
print(f"True revenue:                £{true_total:,.0f}")
print(f"Plain SUM after the join:    £{naive:,.0f}   <- WRONG, too high")
print(f"Each deal counted once:      £{safe:,.0f}   <- what Looker's primary key gives you")
assert naive > true_total and safe == true_total
