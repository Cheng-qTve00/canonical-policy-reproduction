# Canonical Policy Reproduction Final Results Summary

## 1. Experimental Overview

This reproduction focuses on the Stack D1 manipulation task from the Canonical Policy paper.

### Task

- Environment: Stack D1
- Method: Canonical Policy
- Dataset: Robomimic Stack D1
- Demonstrations: 200

### Training Protocol

Due to local GPU memory limitation (RTX 4070 Laptop GPU, 8GB), the official batch setting was adapted:

Official:

- batch size: 128

Local reproduction:

- physical batch size: 32
- gradient accumulation: 4
- drop_last: False

The training update count was verified to match the official optimization schedule:

- 157 optimizer updates per epoch
- 250 epochs
- Total optimizer updates: 39250

This is an optimization-protocol reproduction rather than bitwise exact reproduction.

---

## 2. Evaluation Protocol

All final evaluations use an independent evaluation procedure.

Configuration:

- Test episodes: 50
- Test seeds: 100000 ~ 100049
- Number of environments: 4
- Maximum steps per episode: 400

The evaluation is performed using separately copied checkpoints to avoid affecting training outputs.

---

## 3. Final Results

### Stack D1 Success Rate

| Method | Training Seed | Success Rate |
|---|---:|---:|
| CP-SO2 | 42 | 84% |
| CP-SO2 | 43 | 76% |
| CP-SO3 | 42 | 72% |
| CP-SO3 | 43 | 76% |

---

## 4. Multi-seed Statistics

### CP-SO2

Results:

- Seed 42: 84%
- Seed 43: 76%

Mean:

80%

Standard deviation:

approximately 4%

---

### CP-SO3

Results:

- Seed 42: 72%
- Seed 43: 76%

Mean:

74%

Standard deviation:

approximately 2%

---

## 5. Comparison with Paper Results

The paper reports approximately:

Stack D1 CP-SO2:

79 ± 7%

The reproduced CP-SO2 result:

80%

The reproduced performance falls within the reported range.

For CP-SO3, the reproduced results show similar task completion capability with slightly lower average success rate compared with CP-SO2.

---

## 6. Reproduction Conclusions

The reproduction successfully verified:

1. Canonical Policy training pipeline can be reproduced locally.
2. CP-SO2 and CP-SO3 models can both complete the Stack D1 task.
3. Multi-seed experiments show stable performance.
4. Independent evaluation confirms that the obtained results are consistent with the paper's reported performance range.

---

## 7. Current Limitations

The current reproduction does not include:

- Full benchmark reproduction across all simulation tasks.
- Complete comparison with all baselines.
- Extensive equivariance visualization experiments.

Possible future extensions:

- Canonical representation equivariance verification.
- Additional manipulation tasks.
- More random seeds.
