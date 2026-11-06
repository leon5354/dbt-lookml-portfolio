# CORE: shared by every model. One cache rule, so all functions refresh together.
# Clear the cache when dbt finishes, not on a blind timer.
datagroup: dbt_finished {
  sql_trigger: SELECT MAX(run_finished_at) FROM ops.dbt_runs ;;
  max_cache_age: "24 hours"
}
