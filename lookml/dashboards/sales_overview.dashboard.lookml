# A dashboard as code. Each element is one saved Explore query (a "tile").
# This one reads the SALES model, so it can only use sales fields.
- dashboard: sales_overview
  title: Sales Overview
  layout: newspaper
  elements:
    - name: deals_total
      title: Deals Sold
      model: sales
      explore: deals
      type: single_value
      fields: [deals.deal_count]

    - name: finance_share_by_region
      title: Finance Share by Region
      model: sales
      explore: deals
      type: looker_bar
      fields: [deals.region, deals.finance_share]
      sorts: [deals.finance_share desc]

    - name: bids_per_deal_by_car
      title: Bids per Deal by Car
      model: sales
      explore: deals
      type: looker_bar
      fields: [deals.car, bids.bids_per_deal]
      sorts: [bids.bids_per_deal desc]
