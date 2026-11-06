# SALES MODEL: what the sales team can open. Core views plus sales-only views.
connection: "bigquery_prod"
include: "/models/core/datagroups.lkml"
include: "/models/core/*.view.lkml"
include: "/models/sales/*.view.lkml"
include: "/dashboards/sales_overview.dashboard.lookml"

persist_with: dbt_finished

explore: deals {
  label: "Sales: Deals"
  description: "One row per sold car. Start here for volume, price and bids."

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
