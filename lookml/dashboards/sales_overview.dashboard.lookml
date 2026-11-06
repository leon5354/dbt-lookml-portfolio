# A dashboard as code. Each element is one saved Explore query (a "tile").
- dashboard: sales_overview
  title: Sales Overview
  layout: newspaper
  elements:
    - name: revenue_total
      title: Net Revenue
      model: carmart
      explore: deals
      type: single_value
      fields: [deals.total_revenue]

    - name: finance_share_by_region
      title: Finance Share by Region
      model: carmart
      explore: deals
      type: looker_bar
      fields: [deals.region, deals.finance_share]
      sorts: [deals.finance_share desc]
