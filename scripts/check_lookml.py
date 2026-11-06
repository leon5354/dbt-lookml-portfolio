"""Check LookML against what dbt really built. Needs `dbt docs generate` first.

We have no Looker server here, so this does a small part of what Spectacles
does in CI: a renamed dbt column fails here, not on someone's dashboard.

For each model in lookml/models/*/*.model.lkml it:
  1. loads only the views that model includes (core + its own folder),
  2. applies refinements (view: +name),
  3. checks tables, columns, primary keys, joins, ${view.field} references,
  4. checks every dashboard tile against the model it points at.

Run: python scripts/check_lookml.py
"""
import json
import re
import sys
from pathlib import Path

import lkml
import yaml

ROOT = Path(__file__).resolve().parent.parent
LOOKML = ROOT / "lookml"
errors = []

catalog = json.loads((ROOT / "target" / "catalog.json").read_text(encoding="utf-8"))
tables = {
    f"{n['metadata']['schema']}.{n['metadata']['name']}".lower(): {c.lower() for c in n["columns"]}
    for n in catalog["nodes"].values()
}


def load_views(model_name, include_patterns):
    """Views a model can see, in include order, with refinements merged in."""
    views = {}
    for pattern in include_patterns:
        if not pattern.endswith(".view.lkml"):
            continue
        for path in sorted(LOOKML.glob(pattern.lstrip("/"))):
            for view in lkml.load(path.read_text(encoding="utf-8")).get("views", []):
                name = view["name"]
                if name.startswith("+"):
                    base = views.get(name[1:])
                    if base is None:
                        errors.append(f"{model_name}: {path.name} refines {name[1:]}, which is not included first")
                        continue
                    for key in ("dimensions", "dimension_groups", "measures"):
                        base.setdefault(key, []).extend(view.get(key, []))
                else:
                    views[name] = view
    return views


def field_names(view):
    names = {d["name"] for d in view.get("dimensions", []) + view.get("measures", [])}
    for group in view.get("dimension_groups", []):
        names |= {f"{group['name']}_{t}" for t in group.get("timeframes", [])}
    return names


model_views = {}
model_explores = {}

for model_path in sorted((LOOKML / "models").glob("*/*.model.lkml")):
    model_name = model_path.name.removesuffix(".model.lkml")
    model = lkml.load(model_path.read_text(encoding="utf-8"))
    views = load_views(model_name, model.get("includes", []))
    model_views[model_name] = views
    model_explores[model_name] = {e["name"] for e in model.get("explores", [])}

    for name, view in views.items():
        table = view["sql_table_name"].strip().lower()
        if table not in tables:
            errors.append(f"{model_name}/{name}: table {table} is not built by dbt")
            continue
        if not any(d.get("primary_key") == "yes" for d in view.get("dimensions", [])):
            errors.append(f"{model_name}/{name}: no primary_key, so sums are unsafe across joins")
        known = field_names(view)
        for field in view.get("dimensions", []) + view.get("dimension_groups", []) + view.get("measures", []):
            sql = field.get("sql", "")
            for col in re.findall(r"\$\{TABLE\}\.(\w+)", sql):
                if col.lower() not in tables[table]:
                    errors.append(f"{model_name}/{name}.{field['name']}: column {col} is not in {table}")
            for ref_view, ref_field in re.findall(r"\$\{(\w+)\.(\w+)\}", sql):
                if ref_view not in views or ref_field not in field_names(views[ref_view]):
                    errors.append(f"{model_name}/{name}.{field['name']}: {ref_view}.{ref_field} is not visible in this model")

    for explore in model.get("explores", []):
        if explore["name"] not in views:
            errors.append(f"{model_name}/explore {explore['name']}: no view with that name")
        for join in explore.get("joins", []):
            if join["name"] not in views:
                errors.append(f"{model_name}/join {join['name']}: view is not included in this model")
            if "relationship" not in join:
                errors.append(f"{model_name}/join {join['name']}: no relationship set")

tiles = 0
for path in sorted((LOOKML / "dashboards").glob("*.dashboard.lookml")):
    for dash in yaml.safe_load(path.read_text(encoding="utf-8")):
        for tile in dash["elements"]:
            tiles += 1
            where = f"{dash['dashboard']}/{tile['name']}"
            views = model_views.get(tile["model"])
            if views is None:
                errors.append(f"{where}: model {tile['model']} does not exist")
                continue
            if tile["explore"] not in model_explores[tile["model"]]:
                errors.append(f"{where}: explore {tile['explore']} is not in model {tile['model']}")
            for field in tile["fields"]:
                view, _, name = field.partition(".")
                if view not in views or name not in field_names(views[view]):
                    errors.append(f"{where}: field {field} is not in model {tile['model']}")

for error in errors:
    print("FAIL", error)
print(f"{len(model_views)} models, {tiles} dashboard tiles checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
