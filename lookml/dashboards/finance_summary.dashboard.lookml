- dashboard: finance_summary
  title: Finance Summary
  layout: newspaper
  elements:
    - name: revenue_total
      title: Net Revenue
      model: finance
      explore: deals
      type: single_value
      fields: [deals.total_revenue]

    - name: refund_rate_by_month
      title: Refund Rate by Month
      model: finance
      explore: deals
      type: looker_line
      fields: [deals.sold_month, deals.refund_rate]
      sorts: [deals.sold_month]
