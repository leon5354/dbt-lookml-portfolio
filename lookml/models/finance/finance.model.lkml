# FINANCE MODEL: revenue and refunds. No bids, no marketing spend.
connection: "bigquery_prod"
include: "/models/core/datagroups.lkml"
include: "/models/core/*.view.lkml"
include: "/models/finance/*.view.lkml"
include: "/dashboards/finance_summary.dashboard.lookml"

persist_with: dbt_finished

explore: deals {
  label: "Finance: Revenue"
  description: "One row per sold car. Start here for fees, refunds and net revenue."

  always_filter: {
    filters: [deals.sold_date: "90 days"]
  }

  join: dealers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${deals.dealer_id} = ${dealers.dealer_id} ;;
  }
}
