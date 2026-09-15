# NutAssembly D0 — CP-SO2 seed 43

- Checkpoint: epoch 249, global step 539749
- Demonstrations: 200
- Training: 250 epochs, batch size 32, gradient accumulation 4
- Evaluation: 50 episodes, seeds 100000–100049, 1 environment, max 500 steps
- Dataset: `nut_assembly_d0_voxel_abs.hdf5`
- Policy: CP-SO2

The evaluator reports `test/mean_score: 0.42`. The log’s final per-seed block reports 12 episodes at 1.0, 24 at 0.5, and 14 at 0.0, while its final summary line reports `12 / 50` full successes and `test/mean_score: 0.42`. These figures are internally inconsistent: the listed per-seed values would average 0.48. The candidate summary supplied separately (18 at 0.5, 20 at 0.0) is also not supported by the raw per-seed block. The auditable facts are therefore 12 full successes and the logged mean 0.42; the partial-score distribution requires rerunning or repairing the evaluator export.

Success seeds (score 1.0): `100000, 100002, 100005, 100012, 100013, 100015, 100016, 100017, 100018, 100036, 100041, 100042`.

This result is not directly comparable to Stack D1's binary success rate unless the same success definition is used; NutAssembly's evaluator preserves partial progress with score 0.5.
