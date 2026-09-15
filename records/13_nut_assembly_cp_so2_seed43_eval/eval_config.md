# NutAssembly D0 正式评估配置

以下参数根据 `eval_50episodes.log` 的评估头部、最终结果区块和 `training_config.yaml` 核对整理。

- Task: `nut_assembly_d0`
- Policy: CP-SO2
- Training seed: 43
- Checkpoint: epoch 249

正式 evaluation：

- `n_test = 50`
- test seeds = `100000–100049`
- `n_test_vis = 0`
- `n_envs = 1`
- `max_steps = 500`

说明：`training_config.yaml` 中的 `env_runner.n_test = 1` 是训练期间 rollout 配置；本文件记录的 50 episode 是最终独立评估配置，两者用途不同。
