# CORE VIEW: what a "deal" is, for everyone. Dimensions and ONE shared measure.
# Each business function adds its own measures with a refinement (view: +deals).
# Built on dbt's marts.fct_deals.
view: deals {
  sql_table_name: marts.fct_deals ;;

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
    description: "Seller region"
  }

  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
    description: "Marketing channel that brought the deal in"
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

  # The one measure every team must agree on. Defined once, here.
  measure: deal_count {
    type: count_distinct
    sql: ${deal_id} ;;
    drill_fields: [deal_id, car, region, sold_date]
  }
}
