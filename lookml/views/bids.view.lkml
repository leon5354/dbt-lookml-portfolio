view: bids {
  sql_table_name: marts.fct_bids ;;

  dimension: bid_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.bid_id ;;
  }

  dimension: deal_id {
    hidden: yes
    type: string
    sql: ${TABLE}.deal_id ;;
  }

  dimension: amount_gbp {
    type: number
    sql: ${TABLE}.amount_gbp ;;
    value_format_name: gbp_0
  }

  dimension_group: bid {
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.bid_at ;;
  }

  measure: bid_count {
    type: count_distinct
    sql: ${bid_id} ;;
  }

  measure: average_bid {
    type: average
    sql: ${TABLE}.amount_gbp ;;
    value_format_name: gbp_0
  }

  measure: bids_per_deal {
    type: number
    sql: 1.0 * ${bid_count} / NULLIF(${deals.deal_count}, 0) ;;
    value_format_name: decimal_1
  }
}
