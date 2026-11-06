"""Check LookML against what dbt really built. Needs `dbt docs generate` first.

We have no Looker server here, so this does a small part of what Spectacles
does in CI: a renamed dbt column fails here, not on someone's dashboard.

Run: python scripts/check_lookml.py
"""
import json
import re
import sys
from pathlib import Path

import lkml
import yaml

ROOT = Path(__file__).resolve().parent.parent
errors = []

catalog = json.loads((ROOT / "target" / "catalog.json").read_text(encoding="utf-8"))
tables = {
    f"{n['metadata']['schema']}.{n['metadata']['name']}".lower(): {c.lower() for c in n["columns"]}
    for n in catalog["nodes"].values()
}

views = {}
for path in (ROOT / "lookml" / "views").glob("*.view.lkml"):
    for view in lkml.load(path.read_text(encoding="utf-8"))["views"]:
        views[view["name"]] = view

for name, view in views.items():
    table = view["sql_table_name"].strip().lower()
    if table not in tables:
        errors.append(f"{name}: table {table} is not built by dbt")
        continue
    fields = view.get("dimensions", []) + view.get("dimension_groups", []) + view.get("measures", [])
    if not any(d.get("primary_key") == "yes" for d in view.get("dimensions", [])):
        errors.append(f"{name}: no primary_key, so sums are unsafe across joins")
    for field in fields:
        for col in re.findall(r"\$\{TABLE\}\.(\w+)", field.get("sql", "")):
            if col.lower() not in tables[table]:
                errors.append(f"{name}.{field['name']}: column {col} is not in {table}")


def field_names(view):
    names = {d["name"] for d in view.get("dimensions", []) + view.get("measures", [])}
    for group in view.get("dimension_groups", []):
        names |= {f"{group['name']}_{t}" for t in group.get("timeframes", [])}
    return names


model = lkml.load((ROOT / "lookml" / "carmart.model.lkml").read_text(encoding="utf-8"))
for explore in model["explores"]:
    if explore["name"] not in views:
        errors.append(f"explore {explore['name']}: no view with that name")
    for join in explore.get("joins", []):
        if join["name"] not in views:
            errors.append(f"join {join['name']}: no view with that name")
        if "relationship" not in join:
            errors.append(f"join {join['name']}: no relationship set")

for path in (ROOT / "lookml" / "dashboards").glob("*.dashboard.lookml"):
    for dash in yaml.safe_load(path.read_text(encoding="utf-8")):
        for tile in dash["elements"]:
            for field in tile["fields"]:
                view, _, name = field.partition(".")
                if view not in views or name not in field_names(views[view]):
                    errors.append(f"{dash['dashboard']}/{tile['name']}: unknown field {field}")

for error in errors:
    print("FAIL", error)
print(f"{len(views)} views checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
