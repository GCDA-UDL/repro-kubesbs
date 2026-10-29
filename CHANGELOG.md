# Changelog

## [0.1.0] — 2026-10-29

First version of the reproduction package.

- Frozen copy of KubeSBS v0.4.0 (commit `4dcb74b`) in `kubesbs/`, without the `medium`
  and `small` datasets.
- Captured results of the big sweep (two sessions, 432 runs), the benchmark (42 runs)
  and the fidelity study (36 runs).
- `reproduce.sh` + `Dockerfile`: regenerate every data figure and table of the paper;
  all six tables and summaries match `expected/` byte for byte.
- `REPRODUCE.md`: how to re-run the experiments.
