#!/bin/bash
# Regenerate every data figure and table of the paper from the captured results in
# kubesbs/results-repro, then compare them with expected/ (the versions printed in
# the paper). Tables and summaries must be identical; figures are regenerated for
# visual comparison (PNG bytes depend on the matplotlib build).
#
# Usage: bash reproduce.sh [OUT_DIR]        (default: ./out)
#        Inside Docker: see README.md. Needs Python 3 with requirements.txt.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mkdir -p "${1:-$ROOT/out}" && cd "${1:-$ROOT/out}" && pwd)"
K="$ROOT/kubesbs"
export PYTHON="${PYTHON:-python3}"
mkdir -p "$OUT/tables" "$OUT/figures"
cd "$K"

echo "== Cost of the simulators (big sweep, two sessions) and small-scale benchmark"
JUNE=results-repro/big-all
OCT=results-repro/big-spoofing-20261022,results-repro/big-spoofing-20261024
"$PYTHON" utils/repro/make_paper_plots.py --out "$OUT/figures" --session june=$JUNE --session oct=$OCT
"$PYTHON" utils/repro/make_benchmark_bars.py \
    --out "$OUT/figures/bars_run_time_total_cpu_seconds_memory_peak_gb_unscheduled_pods.png" \
    --session june=results-repro/benchmark-all --session oct=results-repro/benchmark-spoofing-20261022
"$PYTHON" utils/repro/paper_tables.py --out "$OUT/tables" --session june=$JUNE --session oct=$OCT \
    --phases results-repro/big-spoofing-20261022/harness.log@opensim,kwok,kube-sched \
    --phases results-repro/big-spoofing-20261024/harness.log@simkube,kubemark,kcs

echo "== Fidelity against a real cluster"
F=results-repro/fidelity-20261029
bash utils/repro/make_fidelity_dataset.sh "$OUT/fidelity-data" >/dev/null
status=0
if (cd "$OUT/fidelity-data" && sha256sum -c --quiet "$K/$F/DATASET.sha256"); then
    echo "fidelity dataset: byte-identical to the one used (DATASET.sha256)"
else
    echo "fidelity dataset: DIFFERENT from DATASET.sha256 (CRLF line endings on Windows also cause this)"
    status=1
fi
"$PYTHON" utils/repro/fidelity_report.py --out "$OUT/fidelity" \
    --nodes-dir "$OUT/fidelity-data/vanilla" \
    --real "4210R server=$F/spoofing-gcd/pods-real-*.csv" \
    --real "W-3245 server=$F/spoofing02/pods-real-*.csv" \
    --sim KWOK="$F/spoofing02/pods-kwok-*.csv" >/dev/null
cp "$OUT/fidelity/fidelity.tex" "$OUT/fidelity/fidelity-summary.txt" "$OUT/tables/"
cp "$OUT/fidelity/fidelity_latency_vs_node_count.png" "$OUT/figures/"

echo "== Comparison with the paper (expected/)"
for f in "$ROOT"/expected/tables/*; do
    n=$(basename "$f")
    if diff -q --strip-trailing-cr "$f" "$OUT/tables/$n" >/dev/null 2>&1; then
        echo "IDENTICAL    tables/$n"
    else
        echo "DIFFERENT    tables/$n   (diff expected/tables/$n $OUT/tables/$n)"
        status=1
    fi
done
for f in "$ROOT"/expected/figures/*; do
    n=$(basename "$f")
    if [[ -f "$OUT/figures/$n" ]]; then
        echo "REGENERATED  figures/$n   (compare with expected/figures/$n)"
    else
        echo "MISSING      figures/$n"
        status=1
    fi
done
[[ $status -eq 0 ]] && echo "All tables and the fidelity dataset match the paper." \
                    || echo "Some outputs differ from the paper."
exit $status
