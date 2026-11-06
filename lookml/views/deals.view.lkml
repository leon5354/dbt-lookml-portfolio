# VIEW FILE: one table's fields. Built on dbt's marts.fct_deals.
view: deals {
  sql_table_name: marts.fct_deals ;;

  # ---------- DIMENSIONS: things to group or filter by ----------

  dimension: deal_id {
    primary_key: yes       # makes sums safe across joins
    hidden: yes
    type: string
    sql: ${TABLE}.deal_id ;;
  }

  dimension: dealer_id {
    hidden: yes
    type: string
    sql: ${TABLE}.dealer_id ;;
  }

  dimension: car {
    type: string
    sql: ${TABLE}.car ;;
  }

  dimension: region {
    type: string
    sql: ${TABLE}.region ;;
    description: "Seller's region"
  }

  dimension: is_finance {
    label: "Bought on Finance"
    type: yesno
    sql: ${TABLE}.is_finance ;;
  }

  dimension: price_band {
    type: tier
    tiers: [10000, 20000]
    style: integer
    sql: ${TABLE}.final_price_gbp ;;
  }

  # One column gives sold_date, sold_week and sold_month.
  dimension_group: sold {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.sold_at ;;
  }

  # ---------- MEASURES: things to add up ----------

  measure: deal_count {
    type: count_distinct
    sql: ${deal_id} ;;
    drill_fields: [deal_id, car, region, sold_date]
  }

  measure: total_revenue {
    type: sum
    sql: ${TABLE}.net_revenue_gbp ;;
    value_format_name: gbp_0
    description: "Fee earned minus refunds. The row-level rule is in dbt."
  }

  measure: average_price {
    type: average
    sql: ${TABLE}.final_price_gbp ;;
    value_format_name: gbp_0
  }

  # A filtered measure.
  measure: finance_deals {
    type: count_distinct
    sql: ${deal_id} ;;
    filters: [is_finance: "yes"]
  }

  # type: number means "built from measures that are already added up".
  measure: finance_share {
    type: number
    sql: 1.0 * ${finance_deals} / NULLIF(${deal_count}, 0) ;;
    value_format_name: percent_1
  }
}
