#!/usr/bin/env python3
"""Date simulated datasets and score the dated trees against the truth.

Per dataset (one row of datasets.csv from sim_make_datasets.R):

  1. scripts/run_dating_grid_staged.py of the PhyloChronoRank pipeline
     (example settings, all methods, MD-Cat with --mdcat-bin, CI stages
     with 0 replicates).
  2. treePL repair (stage 4 can drop treePL from dating/candidates.csv;
     the stage-2 tree is put back).
  3. sim_date_error.R: true node-age error of every tree in
     dating/candidates.csv (whole tree, burst-zone nodes, root).

Markers dating.done and date_error.done; a dataset in progress is claimed
(claimed.pid), so more processes can share a list.

Usage:
  python3 sim_date_truth.py --datasets=DATASETS.csv --workdir=RUNS --scripts-dir=work/frozen/scripts
    --treepl-bin=PATH [--mdcat-bin=PATH] [--jobs=4]
"""

import argparse
import csv
import os
import re
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SIM_SCRIPTS = Path(__file__).resolve().parent


def run(cmd, log_path):
    with open(log_path, "w") as handle:
        return subprocess.call([str(c) for c in cmd], stdout=handle, stderr=subprocess.STDOUT)


def release(out):
    path = out / "claimed.pid"
    try:
        if path.exists() and path.read_text().strip() == str(os.getpid()):
            path.unlink()
    except OSError:
        pass


def repair_treepl(out):
    """Append the stage-2 treePL tree to dating/candidates.csv when stage 4
    failed and dropped it. Returns True when the file was changed."""
    dating = out / "dating"
    cand_csv = dating / "candidates.csv"
    log4 = dating / "stage4_treepl_ci.log"
    log2 = dating / "stage2_treepl_plain.log"
    if not (cand_csv.exists() and log4.exists() and log2.exists()):
        return False
    if "treePL finished: FAILED" not in log4.read_text():
        return False
    rows = list(csv.DictReader(open(cand_csv, newline="")))
    if any(r["method"] == "treePL" for r in rows):
        return False
    m = re.search(r"treePL finished: (treePL_smooth\S+) dated", log2.read_text())
    if not m:
        return False
    cand = m.group(1)
    tree = dating / "treepl" / "trees" / f"sim_{cand}.tre"
    sel = list(csv.DictReader(open(dating / "treepl" / "sim_treePL_selected_settings.csv", newline="")))
    scores = list(csv.DictReader(open(dating / "treepl" / "sim_treePL_cv_scores.csv", newline="")))
    if not tree.exists() or not sel:
        return False
    chosen = [s for s in scores if s["cv_selected"] == "TRUE"]
    main_tree = (dating / "MAIN_OUTPUT_TREES" / f"{cand}.tre").resolve()
    shutil.copyfile(tree, main_tree)
    shutil.copyfile(cand_csv, dating / "candidates_before_treepl_repair.csv")
    rows.append({"candidate": cand, "tree_file": str(main_tree), "method": "treePL", "model": "treePL",
                 "lambda": "NA", "nb_rate_cat": "NA", "smooth": sel[0]["smooth"], "selected_from_candidate": cand,
                 "selection_score": chosen[0]["cv_chisq"] if chosen else "NA", "selection_rule": "min_treepl_cv_chisq"})
    with open(cand_csv, "w", newline="") as handle:
        w = csv.DictWriter(handle, fieldnames=list(rows[0].keys()), quoting=csv.QUOTE_NONNUMERIC)
        w.writeheader()
        w.writerows(rows)
    return True


def claim(out):
    """Claim a dataset for this process; date_error.done is the finished marker."""
    path = out / "claimed.pid"
    done = out / "date_error.done"
    if path.exists() and (not done.exists() or path.stat().st_mtime > done.stat().st_mtime):
        try:
            pid = int(path.read_text().strip())
            os.kill(pid, 0)
            if pid != os.getpid():
                return False
        except (ValueError, ProcessLookupError, PermissionError):
            pass
    path.write_text(str(os.getpid()))
    return True


def steps(row, args):
    ds = row["dataset"]
    out = Path(args.workdir) / ds
    out.mkdir(parents=True, exist_ok=True)
    if (out / "date_error.done").exists():
        return ds, "already done", 0
    if not claim(out):
        return ds, "held by another process", 0
    scripts = Path(args.scripts_dir)
    t0 = time.time()
    dating = out / "dating"
    if not (out / "dating.done").exists():
        cmd = ["python3", scripts / "run_dating_grid_staged.py",
               f"--phylogram={row['phylogram']}", f"--calibrations-csv={row['calibrations']}",
               f"--outdir={dating}", "--out-prefix=sim", f"--treepl-numsites={args.n_sites}",
               f"--ci-sites={args.n_sites}", "--reltime-bootstrap-reps=0", "--treepl-ci-reps=0",
               "--chronos-ci-reps=0", "--mdcat-bootstrap-reps=0", f"--seed={row['rep']}",
               f"--treepl-bin={args.treepl_bin}", f"--megacc-bin={args.megacc_bin}"]
        if args.mdcat_bin:
            cmd += [f"--mdcat-bin={args.mdcat_bin}", f"--mdcat-jobs={args.mdcat_jobs}"]
        if run(cmd, out / "dating.log") != 0:
            return ds, "dating failed", time.time() - t0
        (out / "dating.done").write_text(f"{time.time() - t0:.0f}\n")
    if repair_treepl(out):
        (out / "treepl_repaired.done").touch()
    cmd = ["Rscript", SIM_SCRIPTS / "sim_date_error.R", f"--true-tree={row['true_tree']}",
           f"--candidates-csv={dating / 'candidates.csv'}", f"--dataset={ds}", f"--out={out / 'date_error.csv'}"]
    if row.get("bursts") and Path(row["bursts"]).exists():
        cmd.append(f"--bursts={row['bursts']}")
    if run(cmd, out / "date_error.log") != 0:
        return ds, "error step failed", time.time() - t0
    (out / "date_error.done").touch()
    return ds, "ok", time.time() - t0


def run_one(row, args):
    try:
        return steps(row, args)
    finally:
        release(Path(args.workdir) / row["dataset"])


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--datasets", required=True)
    p.add_argument("--workdir", required=True)
    p.add_argument("--scripts-dir", required=True)
    p.add_argument("--jobs", type=int, default=4)
    p.add_argument("--only", default="", help="comma list of dataset ids or cal sets")
    p.add_argument("--n-sites", type=int, default=1000)
    p.add_argument("--treepl-bin", required=True)
    p.add_argument("--megacc-bin", default="/usr/local/bin/megacc")
    p.add_argument("--mdcat-bin", default="")
    p.add_argument("--mdcat-jobs", type=int, default=1)
    args = p.parse_args()

    with open(args.datasets, newline="") as handle:
        rows = list(csv.DictReader(handle))
    if args.only:
        keep = set(args.only.split(","))
        rows = [r for r in rows if r["dataset"] in keep or r["cal_set"] in keep]
    rows.sort(key=lambda r: (int(r["rep"]), r["cal_set"], r["rate_model"]))
    Path(args.workdir).mkdir(parents=True, exist_ok=True)
    status_path = Path(args.workdir) / "batch_status.csv"
    print(f"{len(rows)} datasets, {args.jobs} at a time", flush=True)
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(run_one, r, args) for r in rows]
        for fut in as_completed(futures):
            ds, status, secs = fut.result()
            line = f"{time.strftime('%Y-%m-%d %H:%M:%S')},{ds},{status},{secs:.0f}"
            print(line, flush=True)
            with status_path.open("a") as handle:
                handle.write(line + "\n")


if __name__ == "__main__":
    main()
