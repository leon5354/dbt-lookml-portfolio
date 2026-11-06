# CarMart: dbt + LookML for several business functions

A made-up car marketplace. Small enough to read in one sitting, and it really runs on your PC.
No cloud account is needed, because DuckDB stands in for BigQuery.

**What runs here:** dbt, every test, snapshots, the LookML checks, the fanout demo.
**What can't run:** LookML itself. It needs a Looker server, so no Explore will open.
`scripts/check_lookml.py` parses the files and checks them against what dbt built.

---

## 1. Run it

Open a terminal in this folder (PowerShell).

```powershell
.venv\Scripts\activate
dbt deps
dbt seed
dbt build
dbt docs generate
python scripts\check_lookml.py
python scripts\fanout_demo.py
```

You should see `PASS=44 ... ERROR=0`, then `3 models, 7 dashboard tiles checked, 0 problem(s)`, then the fanout numbers.

**See the DAG as a picture:** `dbt docs serve`, then click the green icon at the bottom right. Press Ctrl+C to stop.

---

## 2. The DAG

The DAG is the map of what depends on what. You never write it. dbt reads every `ref()` and `source()` and works it out.

```
SOURCES (raw)          STAGING            INTERMEDIATE      MARTS                 LOOKML MODEL      DASHBOARD

raw_dealers ────────▶ stg_dealers ──────────────────────▶ dim_dealers ──────┐
raw_deals ──────────▶ stg_deals ────────────────────────▶ fct_deals ────────┼──▶ sales ────────▶ sales_overview
raw_bids ───────────▶ stg_bids ─────▶ int_bid_stats ─────▶ fct_bids ─────────┘     finance ──────▶ finance_summary
raw_marketing_spend ▶ stg_marketing_spend ───────────────▶ fct_marketing_spend ───▶ marketing ───▶ marketing_performance
                                                          (fct_deals also feeds marketing)
```

The DAG also sets the build order, so `stg_deals` always builds before `fct_deals`.

**The dbt DAG ends at the marts.** Looker is a separate tool, and dbt doesn't build or run it. So the LookML columns in the drawing above are the full pipeline, not dbt's own DAG.

To show Looker on dbt's graph, we use **exposures** in `_marts.yml`. They're labels saying "this explore and this dashboard use these models". They run nothing, but they appear as the last nodes in `dbt docs serve`, so you can see who breaks if a model changes.

```powershell
dbt ls --resource-type exposure                                 # lists the Looker exposures
dbt ls --select +exposure:looker_deals_explore --output name    # everything feeding the explore
```

```powershell
dbt ls --select +fct_deals      # fct_deals and everything upstream
dbt ls --select stg_bids+       # stg_bids and everything downstream
```

---

## 3. Read the files in this order

| # | File | Teaches |
|---|---|---|
| 1 | `dbt_project.yml` | Project settings, defaults by folder |
| 2 | `profiles.yml` | The connection, with a BigQuery example |
| 3 | `models/staging/_sources.yml` | Declaring raw tables, freshness |
| 4 | `models/staging/stg_deals.sql` | Staging: rename, cast, clean |
| 5 | `models/staging/_staging.yml` | Docs and generic tests |
| 6 | `models/intermediate/int_bid_stats.sql` | Ephemeral, and avoiding a fanout |
| 7 | `models/marts/fct_deals.sql` | A fact table with row-level logic |
| 8 | `models/marts/fct_bids.sql` | Incremental, with BigQuery settings |
| 9 | `models/marts/_marts.yml` | Contract, tests, exposure |
| 10 | `models/marts/_unit_tests.yml` | Unit tests, including incremental |
| 11 | `tests/` | Singular tests and a custom generic test |
| 12 | `snapshots/dealers_snapshot.yml` | SCD Type 2 |
| 13 | `macros/generate_schema_name.sql` | A macro |
| 14 | `lookml/models/core/deals.view.lkml` | Shared dimensions, one shared measure |
| 15 | `lookml/models/finance/deals_finance.view.lkml` | A refinement: `view: +deals` |
| 16 | `lookml/models/sales/sales.model.lkml` | Explore, joins, includes |
| 17 | `lookml/models/marketing/` | A second fact table joined on two keys |
| 18 | `lookml/dashboards/*.lookml` | Dashboards as code, one per model |
| 19 | `scripts/check_lookml.py` | Testing LookML against dbt |
| 20 | `.github/workflows/ci.yml` | CI |

**See what dbt really runs:** after `dbt build`, open `target/compiled/carmart/models/marts/fct_deals.sql`. The Jinja is gone, and the ephemeral model is pasted in as a CTE.

---

## 3b. How the LookML is organised

One shared **core**, then one **model per business function**. Each model includes core plus only its own folder.

```
lookml/
├── models/
│   ├── core/         shared by everyone
│   │   ├── datagroups.lkml          cache rule, tied to dbt finishing
│   │   ├── deals.view.lkml          what a deal is + the one shared measure: deal_count
│   │   └── dealers.view.lkml
│   ├── sales/
│   │   ├── sales.model.lkml         explore: deals + dealers + bids
│   │   ├── deals_sales.view.lkml    adds average_price, finance_share to deals
│   │   └── bids.view.lkml
│   ├── marketing/
│   │   ├── marketing.model.lkml     explore: marketing_spend + deals
│   │   └── marketing_spend.view.lkml   spend, leads, cost_per_deal
│   └── finance/
│       ├── finance.model.lkml       explore: deals + dealers
│       └── deals_finance.view.lkml  adds fees, refunds, revenue, refund_rate to deals
└── dashboards/
    ├── sales_overview.dashboard.lookml
    ├── marketing_performance.dashboard.lookml
    └── finance_summary.dashboard.lookml
```

| Idea | How it shows here |
|---|---|
| **One definition of a deal** | `deals` and `deal_count` live in core. Every team counts deals the same way. |
| **Each team adds its own measures** | A refinement (`view: +deals`) extends the core view, without copying it. |
| **Teams only see what they need** | Finance can't see bids. Sales can't see spend. The model's `include:` lines decide. |
| **Cross-view measures** | `cost_per_deal` in marketing divides spend by core's `deal_count`. |
| **Two grains joined safely** | Spend is per channel-month, deals are per sale. The join uses both keys, `one_to_many`, and primary keys on both views. |
| **One cache rule** | One `datagroup` in core, used by all three models. |
| **A dashboard belongs to a model** | Each tile names its model, so it can only use fields that model exposes. |

`check_lookml.py` enforces this: it loads each model's own includes, so a field used outside its model fails the check.

---

## 4. The YAML files

| File | Job |
|---|---|
| `dbt_project.yml` | Project settings |
| `profiles.yml` | Where to connect |
| `packages.yml` | Outside packages, installed by `dbt deps` |
| `_sources.yml` | Raw tables and freshness |
| `_staging.yml`, `_marts.yml` | Descriptions, tests, contracts, exposures |
| `_unit_tests.yml` | Unit tests |
| `dealers_snapshot.yml` | Snapshot settings |
| `.github/workflows/ci.yml` | GitHub's instructions, not dbt |

dbt reads every YAML file under `models/`. The file names are only a team habit.

---

## 5. Tests in this project

| Type | Where | Example |
|---|---|---|
| Generic | `_staging.yml`, `_marts.yml` | `unique`, `not_null`, `relationships`, `accepted_values` |
| Custom generic | `tests/generic/positive_value.sql` | Value above 0 |
| Package | `_marts.yml` | `dbt_utils.unique_combination_of_columns` |
| Singular | `tests/assert_*.sql` | Revenue reconciles to raw |
| Unit | `_unit_tests.yml` | Null refund, no bids, incremental path |
| Contract | `_marts.yml` | Column names and types can't change quietly |

Every data test is a query that must return **zero rows** to pass.

---

## 6. What goes where

| Thing | Home | Example here |
|---|---|---|
| Row-level rule | dbt | `net_revenue_gbp`, `is_finance` |
| Grain and joins for tables | dbt | `fct_deals`, `fct_marketing_spend` |
| Definition every team shares | LookML core | `deal_count` |
| Sum, count, average for one team | LookML function folder | `total_revenue` (finance), `average_price` (sales) |
| Ratio | LookML | `refund_rate`, `cost_per_deal` |
| Join for users | LookML model | deals to bids (sales), spend to deals (marketing) |
| Label, description | LookML | "Bought on Finance" |

---

## 7. How CI works

On every pull request, GitHub starts a clean machine and runs `ci.yml`:

```
Open PR → install tools → dbt deps → dbt seed → dbt build → docs generate → check LookML → pass or fail
```

If a step fails, the PR is marked failed. With branch protection on, it can't merge.

**Slim CI** builds only what changed. Tested here by changing `dim_dealers`: full build 37 steps, slim build 5.

```powershell
dbt build --select state:modified+ --defer --state prod-artifacts
```

`prod-artifacts/` holds production's `manifest.json`. dbt compares against it to find what changed, and `--defer` reads unchanged parents from production.


---

## 8. How Git fits

Both dbt and LookML are plain text files in Git.

| Step | dbt | LookML |
|---|---|---|
| Make a branch | `git checkout -b my-change` | Development Mode gives you a branch |
| Edit | VS Code or similar | Looker's browser editor |
| Check | `dbt build` | Validate LookML |
| Save | `git commit` | Commit in Looker |
| Review | Pull request | Pull request, if the team requires it |
| Go live | Merge to main | Deploy to Production |

---

## 9. Break it on purpose (the best way to learn)

Each of these was tested. Undo each change before the next one.

| Try this | What happens |
|---|---|
| `fct_deals.sql`: remove `coalesce` from `refund_gbp` | Unit test fails, and everything downstream is skipped |
| `fct_deals.sql`: rename `net_revenue_gbp` | Contract fails the build |
| `core/deals.view.lkml`: use `${TABLE}.net_rev` | `check_lookml.py` fails: column not found |
| `core/deals.view.lkml`: remove `primary_key: yes` | `check_lookml.py` fails: no primary key |
| `marketing_performance.dashboard.lookml`: add `deals.total_revenue` | `check_lookml.py` fails: revenue is a finance field, not in the marketing model |
| Add a row to `raw_bids.csv`, then `dbt seed` and `dbt run --select fct_bids` | Incremental picks it up, if it's within 3 days of the latest bid |
| Change a dealer's `plan` and `updated_at`, then `dbt seed` and `dbt snapshot` | A second history row appears |

To rebuild from nothing: `dbt build --full-refresh`.

---

## 10. On real BigQuery

| Here | BigQuery |
|---|---|
| `delete+insert` | `merge` (`fct_bids.sql` switches by itself) |
| No partitions | `partition_by` and `cluster_by` (already in `fct_bids.sql`) |
| `varchar`, `double` in the contract | `string`, `float64` |
| No cost | Every query scans bytes, so dry run first |

---

## 11. Key ideas to explain

- **Several teams, one project:** shared core views, one model per function, refinements for team-specific measures.
- **Fanout:** `int_bid_stats` rolls bids up to deal grain before the join, so `fct_deals` can't fan out. In Looker, the primary key and `relationship` protect sums.
- **Test the join between tools:** "A rename in dbt shouldn't break a dashboard in silence, so I'd check LookML against dbt in CI." In real projects, Spectacles is a common tool for this.
- **Grain:** every model states its grain in the first line.
