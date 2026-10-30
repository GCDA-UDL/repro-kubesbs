# KubeSBS: A Reproducible Measurement Framework for Kubernetes Cluster Simulators — reproduction package

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)
[![Data: CC BY 4.0](https://img.shields.io/badge/Data-CC_BY_4.0-lightgrey.svg)](LICENSE-data)
![Reproducible with Docker](https://img.shields.io/badge/reproducible-Docker-2496ED.svg)

Code, captured results and analysis environment for the paper

> **KubeSBS: A Reproducible Measurement Framework for Kubernetes Cluster Simulators**
> (under review).

**Authors:** Matias Medina, Rosana Tomàs, Josep Lluís Lérida, Fernando Guirado and
Vitor L. da Silva — SEMBAC, Universitat de Lleida, Spain.
The framework itself is developed at [GCDA-UDL/kubesbs](https://github.com/GCDA-UDL/kubesbs);
this repository freezes the version used by the paper.

## What is inside

| Path | Contents |
|---|---|
| [`kubesbs/`](kubesbs) | Frozen copy of **KubeSBS v0.4.0** (tag `v0.4.0`, commit `4dcb74b`): KubeGen, KubeRun, KubeDirector, the tool modules, the datasets and the reproduction scripts. Only what the paper uses is kept: the `medium` and `small` datasets, the results of other studies (`results-repro/{k8ssim,kcs,small-final,test,traces}`) and the development notes (`TODO.md`, `AGENTS.md`, `specs/`, `summaries/`, `REPRODUCIBILITY_REPORT.md`, `.specify/`) are left out; links to them inside `kubesbs/` point to files of the [full repository](https://github.com/GCDA-UDL/kubesbs/tree/v0.4.0). |
| [`kubesbs/results-repro/`](kubesbs/results-repro) | Captured results of every experiment in the paper (table below), with harness logs and provenance where they exist. |
| [`expected/`](expected) | The data tables and figures exactly as printed in the paper. |
| [`reproduce.sh`](reproduce.sh) | Regenerates every data figure and table from the captured results and compares the tables with `expected/`. |
| [`Dockerfile`](Dockerfile), [`requirements.txt`](requirements.txt) | Analysis environment (Python 3.11, pinned by digest and versions). |
| [`REPRODUCE.md`](REPRODUCE.md) | How to re-run the experiments themselves. |

## Quick start: regenerate the figures and tables (about 2 minutes)

```bash
docker build -t repro-kubesbs .
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/repro" repro-kubesbs
```

Outputs go to `out/` (`out/tables`, `out/figures`). The script ends with one line per
output: `IDENTICAL` for each table that matches the paper byte for byte, and
`REGENERATED` for each figure (PNG bytes depend on the matplotlib build, so compare them
visually with `expected/figures/`). It also rebuilds the scaled dataset of the fidelity
study and checks it against the checksums of the dataset that was used. Without
Docker: `pip install -r requirements.txt && bash reproduce.sh` (Linux or macOS).

## Paper element → script → input

All scripts are in `kubesbs/utils/repro/` and run from `kubesbs/`.

| Paper element | Script | Input (`kubesbs/results-repro/…`) |
|---|---|---|
| Peak memory, CPU time, run time and scheduling success vs. node count (`fig:memory`, `fig:cpu`, `fig:runtime`, `fig:success`) | `make_paper_plots.py` | `big-all` (June 2026) + `big-spoofing-20261022`, `big-spoofing-20261024` (October 2026) |
| Small-scale benchmark with vanilla Kubernetes (`fig:benchmark`) | `make_benchmark_bars.py` | `benchmark-all` + `benchmark-spoofing-20261022` |
| Cost-scaling exponents, run-time phases, variability (`tab:scaling`, `tab:phases`, `tab:variability`) and the numbers in the text (`summary.txt`) | `paper_tables.py` (phases via `run_phases.py`) | the big sweep of both sessions; `harness.log` of the October runs |
| Fidelity of KWOK against a real cluster (`tab:fidelity`, `fig:fidelity-latency`, `fidelity-summary.txt`) | `make_fidelity_dataset.sh`, `fidelity_report.py` | `fidelity-20261029` |

The framework diagram and the tables of tools and datasets contain no measured data and
are written by hand.

## Captured results

| Folder | Experiment | Runs | Host |
|---|---|---|---|
| `big-all` | Big sweep: 6 tools × 12 sizes (100–1,200 nodes) × 3 | 216 | 2× Xeon Silver 4210R (40 threads), 128 GB, Rocky Linux 9.3, cgroups v2; June 2026 |
| `big-spoofing-20261022`, `big-spoofing-20261024` | Same sweep, second session | 216 | same server and runner image; October 2026 |
| `benchmark-all`, `benchmark-spoofing-20261022` | Benchmark: 6 tools + vanilla × 3, two sessions | 2 × 21 | same server |
| `fidelity-20261029` | Real k3s cluster on two servers + KWOK, 10–100 nodes × 3 | 36 | the server above and a Xeon W-3245 server (32 threads, 192 GB, Ubuntu 20.04) |

Each folder has its own `NOTES.md` or entry in `kubesbs/utils/repro/README.md` with the
details (discarded runs, host limits, caveats).

## Re-running the experiments

Re-running needs Linux hosts with Docker; the cost of the tools depends on the host, so
expect the same ranking and scheduling outcomes rather than the same absolute numbers.
The big sweep takes about 22 hours of measured run time per session, the benchmark about
20 minutes, and the fidelity study under an hour per host. See [REPRODUCE.md](REPRODUCE.md).

## How to cite

Use [`CITATION.cff`](CITATION.cff) (GitHub shows a "Cite this repository" button). The
Zenodo archive and its DOI will be added when the paper is published.

## License

Code: Apache-2.0 ([`LICENSE`](LICENSE)); KubeSBS's own notices are in
[`kubesbs/NOTICE`](kubesbs/NOTICE). Captured results and generated data: CC BY 4.0
([`LICENSE-data`](LICENSE-data)). The workloads derive from the Alibaba cluster trace
([alibaba/clusterdata](https://github.com/alibaba/clusterdata)), and the tools that
KubeSBS runs are pulled from their upstream projects under their own licenses.

## Funding

This work has been granted by the Ministerio de Ciencia, Innovación y Universidades
(MICIU) AEI/10.13039/501100011033 under contract PID2023-146193OB-I00.

## Contact

Vitor L. da Silva — vitor.dasilva@udl.cat
