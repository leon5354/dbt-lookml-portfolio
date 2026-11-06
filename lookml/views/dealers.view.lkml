view: dealers {
  sql_table_name: marts.dim_dealers ;;

  dimension: dealer_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.dealer_id ;;
  }

  dimension: dealer_name {
    type: string
    sql: ${TABLE}.dealer_name ;;
  }

  dimension: dealer_region {
    type: string
    sql: ${TABLE}.region ;;
  }

  dimension: plan {
    type: string
    sql: ${TABLE}.plan ;;
  }
}
