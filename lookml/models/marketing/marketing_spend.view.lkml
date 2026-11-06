# MARKETING view: spend per channel per month. Built on dbt's marts.fct_marketing_spend.
view: marketing_spend {
  sql_table_name: marts.fct_marketing_spend ;;

  dimension: spend_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.spend_id ;;
  }

  dimension: channel {
    type: string
    sql: ${TABLE}.channel ;;
  }

  # spend_month is a DATE, not a timestamp. Without these two lines,
  # Looker treats it as a timestamp, which breaks on BigQuery.
  dimension_group: spend {
    type: time
    datatype: date
    convert_tz: no
    timeframes: [raw, month]
    sql: ${TABLE}.spend_month ;;
  }

  measure: total_spend {
    type: sum
    sql: ${TABLE}.spend_gbp ;;
    value_format_name: gbp_0
  }

  measure: total_leads {
    type: sum
    sql: ${TABLE}.leads ;;
  }

  # Uses the shared deal_count from core, so marketing and sales agree.
  measure: cost_per_deal {
    type: number
    sql: 1.0 * ${total_spend} / NULLIF(${deals.deal_count}, 0) ;;
    value_format_name: gbp_0
  }

  measure: cost_per_lead {
    type: number
    sql: 1.0 * ${total_spend} / NULLIF(${total_leads}, 0) ;;
    value_format_name: gbp_0
  }
}
