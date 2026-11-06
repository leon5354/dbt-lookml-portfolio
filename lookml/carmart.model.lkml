# MODEL FILE: the connection, the caching rule and what users can open.
connection: "bigquery_prod"
include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lookml"

# Clear the cache when dbt finishes, not on a blind timer.
datagroup: dbt_finished {
  sql_trigger: SELECT MAX(run_finished_at) FROM ops.dbt_runs ;;
  max_cache_age: "24 hours"
}
persist_with: dbt_finished

# An explore is the starting point users see.
explore: deals {
  label: "Deals"
  description: "One row per sold car. Start here for revenue."

  # Forces a date filter, so nobody scans all of history by accident.
  always_filter: {
    filters: [deals.sold_date: "90 days"]
  }

  # many_to_one is safe: each deal has one dealer, so rows don't repeat.
  join: dealers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${deals.dealer_id} = ${dealers.dealer_id} ;;
  }

  # one_to_many fans out: each deal repeats once per bid. Looker needs this
  # relationship and the primary keys to keep deals' sums correct.
  join: bids {
    type: left_outer
    relationship: one_to_many
    sql_on: ${deals.deal_id} = ${bids.deal_id} ;;
  }
}
