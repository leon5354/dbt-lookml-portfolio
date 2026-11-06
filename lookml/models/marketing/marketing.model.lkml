# MARKETING MODEL: spend against the deals each channel brought in.
connection: "bigquery_prod"
include: "/models/core/datagroups.lkml"
include: "/models/core/*.view.lkml"
include: "/models/marketing/*.view.lkml"
include: "/dashboards/marketing_performance.dashboard.lookml"

persist_with: dbt_finished

# Starts from spend, because a channel with spend and no deals must still show.
explore: marketing_spend {
  label: "Marketing: Channel Spend"
  description: "One row per channel per month. Start here for spend and cost per deal."

  # Spend has one row per channel-month, deals has many. Join on both keys.
  join: deals {
    type: left_outer
    relationship: one_to_many
    sql_on: ${marketing_spend.channel} = ${deals.acquisition_channel}
        AND ${marketing_spend.spend_month} = ${deals.sold_month} ;;
  }
}
