"""
Export the small aggregate marts to CSV for charts on zzeller.com.

Uses dbt's own Python API, so it connects with the same profile and credentials
as `dbt build`. No separate BigQuery setup is needed.

Run from the project root, after `dbt build`:
    python scripts/export_marts.py
"""
import contextlib
import io
from pathlib import Path

from dbt.cli.main import dbtRunner

# Aggregate tables only: small enough to commit, no customer-level rows
MODELS = ["fct_cohort_retention", "fct_repeat_rate_by_segment"]

project_root = Path(__file__).resolve().parent.parent
out_dir = project_root / "exports"
out_dir.mkdir(exist_ok=True)

runner = dbtRunner()
for model in MODELS:
    # `dbt show` runs a SELECT against the built table and returns the rows.
    # --limit -1 means "no row limit".
    # dbt show also prints a preview table to the terminal; capture it so output stays short
    with contextlib.redirect_stdout(io.StringIO()):
        result = runner.invoke(["show", "--select", model, "--limit", "-1", "--quiet"])
    if not result.success:
        raise SystemExit(f"dbt show failed for {model}: {result.exception}")

    table = result.result.results[0].agate_table
    path = out_dir / f"{model}.csv"
    table.to_csv(path)
    print(f"Wrote {path.relative_to(project_root)} ({len(table.rows)} rows)")
