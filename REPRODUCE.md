# Reproducing the paper

Three levels, from minutes to days:

1. **Regenerate the figures and tables** from the captured results (2 minutes, any
   machine with Docker). This is what `reproduce.sh` does; see the README.
2. **Re-run the cost experiments** (big sweep and benchmark) on a Linux server.
3. **Re-run the fidelity study** (real k3s cluster and KWOK) on a Linux server.

Absolute costs depend on the host. On another machine, expect the same ranking of the
tools, the same scheduling outcomes (unscheduled pods) and the same scaling behaviour,
not the same seconds and gigabytes. `compare_runs.py` reports the differences per tool
and node count.

All commands below run from `kubesbs/`.

## 1. Regenerate the figures and tables

```bash
docker build -t repro-kubesbs .            # from the repository root
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/repro" repro-kubesbs
```

`reproduce.sh` runs, in order: `make_paper_plots.py` and `make_benchmark_bars.py` (cost
figures), `paper_tables.py` (scaling, phases and variability tables and `summary.txt`),
`make_fidelity_dataset.sh` (rebuilds the fidelity dataset and checks it against
`results-repro/fidelity-20261029/DATASET.sha256`) and `fidelity_report.py` (fidelity table,
latency figure and `fidelity-summary.txt`). It then compares the six tables and summaries
with `expected/tables/` and exits with status 1 if any differs.

## 2. Re-run the cost experiments

**Host.** The published runs used one server with 2× Xeon Silver 4210R (20 cores / 40
threads), 128 GB of memory, Rocky Linux 9.3 (kernel 5.14) with **cgroups v2**, which KubeRun
needs to measure CPU and memory. Docker must allow privileged containers. The most
memory-hungry tool, Kubemark, peaks at about 21.5 GB.

**Before a big run** (details in `utils/repro/README.md`, "Host requirements"):

```bash
# Kubemark at ~700 hollow nodes overflows the default neighbour table
sudo sysctl -w net.ipv4.neigh.default.gc_thresh1=4096 \
               net.ipv4.neigh.default.gc_thresh2=8192 \
               net.ipv4.neigh.default.gc_thresh3=16384
```

Containers must resolve the image registries; if the site DNS does not answer them, pass
public resolvers with `DNS="8.8.8.8 1.1.1.1"`. `run_sweep.sh` checks both before starting.

**Run and compare.** `run_sweep.sh` runs the tools in the runner container, pinned by
digest to the image of every published run, and writes `RUN_INFO` (host, commit, image)
and `harness.log` next to the CSVs. The kcs binary is built on first use
(`modules/kcs/build.sh`, needs Go).

```bash
# Benchmark: 6 tools + vanilla Kubernetes, 3 runs (about 20 minutes)
bash utils/repro/run_sweep.sh
python3 utils/repro/compare_runs.py results-repro/benchmark-all results-repro/benchmark-<host>-<date>

# Big sweep: 6 tools x 12 sizes x 3 runs (about 22 hours of run time)
DATASET=big MODULES="opensim kwok kube-sched simkube kubemark kcs" bash utils/repro/run_sweep.sh
python3 utils/repro/compare_runs.py results-repro/big-all results-repro/big-<host>-<date>
python3 utils/repro/run_phases.py results-repro/big-<host>-<date>/harness.log
```

To include the new session in the figures and tables, add it to the `--session` arguments
of the scripts in `reproduce.sh`.

## 3. Re-run the fidelity study

The real cluster and KWOK run **directly on the host**, not in the runner container.

**Host.** Linux with Docker; the published runs used the server above and a second one
(Xeon W-3245, 16 cores / 32 threads, 192 GB, Ubuntu 20.04). The 100-node real cluster
needs about 23 GB of memory, and its memory grows roughly as 0.16·N + 0.00065·N² GB, so
do not go beyond 100 nodes on one host. At 60–100 nodes the cluster saturates the CPU
of a 32–40-thread host (see `results-repro/fidelity-20261029/NOTES.md`). KubeRun measures
the cluster's cost only under cgroups v2; placement and latency are recorded either way.

**Tools** (the versions used): k3d v5.7.4, kubectl v1.29.0, kwokctl v0.7.0, Python 3 with
PyYAML and msgpack (and SciPy and matplotlib for the analysis). The real module pins the
node image `rancher/k3s:v1.29.0-k3s1`.

**Host limits.** Each k3s node uses several inotify instances; the default limit (128)
stops a cluster at about 14 nodes:

```bash
sudo sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=1048576
```

**Run.** One dataset folder per size, then the real cluster and KWOK, three runs each:

```bash
bash utils/repro/make_fidelity_dataset.sh                  # data/fidelity/{base,vanilla}
for n in 10 30 60 100; do
  mkdir -p data/fidelity/size$n
  cp data/fidelity/vanilla/nodes-$n.yaml data/fidelity/vanilla/pods-$n.yaml data/fidelity/size$n/
done
R=$PWD/results-fidelity-$(hostname -s)
mkdir -p "$R"
export POD_RECORDS_DIR=$R REAL_WORK_DIR=$R/work REAL_PLATFORM=k3d-$(hostname -s) KWOK_KUBE_VERSION=v1.29.0
for n in 10 30 60 100; do
  for tool in real kwok; do
    bash kube-run.sh -m $tool -e data/fidelity/size$n -n 3 -x 1800 -o "$R/$tool-$n.csv" > "$R/$tool-$n.log" 2>&1
  done
done
```

Each run leaves `pods-<tool>-<platform>-<nodes>-<rep>.csv` in `$R`. Before the pods are
created, the real module checks that every node's allocatable equals its trace node's
and stops otherwise.

**Analyse** the new runs together with the published ones by adding them as another
platform:

```bash
F=results-repro/fidelity-20261029
python3 utils/repro/fidelity_report.py --out fidelity-out --nodes-dir data/fidelity/vanilla \
    --real "4210R server=$F/spoofing-gcd/pods-real-*.csv" \
    --real "W-3245 server=$F/spoofing02/pods-real-*.csv" \
    --real "my host=$R/pods-real-*.csv" \
    --sim KWOK="$F/spoofing02/pods-kwok-*.csv"
```

`fidelity-summary.txt` then reports the agreement and occupancy distance between your
real runs and the published ones (`real-across-hosts`).
