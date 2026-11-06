# SALES refinement: adds sales measures to the core deals view.
# The plus sign means "extend the view that already exists".
view: +deals {
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
