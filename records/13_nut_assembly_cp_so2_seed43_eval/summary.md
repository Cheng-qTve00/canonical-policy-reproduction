# NutAssembly D0 — CP-SO2 seed 43

- Checkpoint: epoch 249, global step 539749
- Demonstrations: 200
- Training: 250 epochs, batch size 32, gradient accumulation 4
- Evaluation: 50 episodes, seeds 100000–100049, 1 environment, max 500 steps
- Dataset: `nut_assembly_d0_voxel_abs.hdf5`
- Policy: CP-SO2

The 50 unique test seeds (100000–100049) contain 12 scores of 1.0, 18 scores of 0.5, and 20 scores of 0.0. Full completion is 12/50 = 24%; the mean is (12 + 18 × 0.5)/50 = 0.42, matching `test/mean_score: 0.42`. Non-zero reward occurs in 30/50 episodes (60%); this is not the full-completion rate. The previously reported distribution conflict was a counting error in the documentation, not an inconsistency in the original log.

Success seeds (score 1.0): `100000, 100002, 100005, 100012, 100013, 100015, 100016, 100017, 100018, 100036, 100041, 100042`.

This result is not directly comparable to Stack D1's binary success rate unless the same success definition is used; NutAssembly's evaluator preserves partial progress with score 0.5.
