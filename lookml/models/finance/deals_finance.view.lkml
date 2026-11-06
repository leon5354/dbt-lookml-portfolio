# FINANCE refinement: money measures on the core deals view.
# The row-level rule (fee minus refund) lives in dbt. Sums and ratios live here.
view: +deals {
  measure: total_fees {
    type: sum
    sql: ${TABLE}.fee_gbp ;;
    value_format_name: gbp_0
  }

  measure: total_refunds {
    type: sum
    sql: ${TABLE}.refund_gbp ;;
    value_format_name: gbp_0
  }

  measure: total_revenue {
    type: sum
    sql: ${TABLE}.net_revenue_gbp ;;
    value_format_name: gbp_0
    description: "Fee earned minus refunds."
  }

  measure: refund_rate {
    type: number
    sql: 1.0 * ${total_refunds} / NULLIF(${total_fees}, 0) ;;
    value_format_name: percent_1
  }
}
