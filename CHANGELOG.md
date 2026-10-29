# Changelog

## [0.1.1] — 2026-10-30

- Only what the paper uses: removed from `kubesbs/` the results of other studies
  (`results-repro/{k8ssim,kcs,small-final,test,traces}`, `summary-extended.json`), the
  development notes (`TODO.md`, `AGENTS.md`, `specs/`, `summaries/`,
  `REPRODUCIBILITY_REPORT.md`, `.specify/`) and Python caches committed by mistake in 0.1.0.
  No change to the code, the datasets or the paper's results.

## [0.1.0] — 2026-10-29

First version of the reproduction package.

- Frozen copy of KubeSBS v0.4.0 (commit `4dcb74b`) in `kubesbs/`, without the `medium`
  and `small` datasets.
- Captured results of the big sweep (two sessions, 432 runs), the benchmark (42 runs)
  and the fidelity study (36 runs).
- `reproduce.sh` + `Dockerfile`: regenerate every data figure and table of the paper;
  all six tables and summaries match `expected/` byte for byte.
- `REPRODUCE.md`: how to re-run the experiments.
