- dashboard: marketing_performance
  title: Marketing Performance
  layout: newspaper
  elements:
    - name: spend_total
      title: Total Spend
      model: marketing
      explore: marketing_spend
      type: single_value
      fields: [marketing_spend.total_spend]

    - name: cost_per_deal_by_channel
      title: Cost per Deal by Channel
      model: marketing
      explore: marketing_spend
      type: looker_bar
      fields: [marketing_spend.channel, marketing_spend.cost_per_deal]
      sorts: [marketing_spend.cost_per_deal]
