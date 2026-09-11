# CP-SO3 Seed43 正式评估

## 实验目的

本实验用于评估 CP-SO3 在不同 training seed 下的性能稳定性。

此前已经完成：

- CP-SO3
- Stack D1
- 200 demonstrations
- training seed = 42

结果：

    Success Rate = 72%

本实验保持任务、数据规模、训练协议和评估协议一致，仅修改：

    training.seed = 43

用于分析随机种子对模型性能的影响。

---

## 训练配置

- Task: Stack D1
- Method: CP-SO3
- Demonstrations: 200
- Training seed: 43
- Epochs: 250

训练资源限制下采用：

- Physical batch size: 32
- Gradient accumulation: 4
- drop_last: False

训练目录：

    data/outputs/cp_so3_seed43_final_v3

最终 checkpoint:

    epoch = 249
    global_step = 156249
    optimizer step = 39250

其中：

    157 optimizer updates / epoch
    × 250 epochs
    = 39250 optimizer updates

说明该模型完成了完整训练过程。

---

## Smoke Test

正式训练前进行了 1 epoch smoke test。

验证结果：

    625 micro-batches
    -> 157 optimizer updates

checkpoint 状态：

    epoch = 0
    global_step = 624
    optimizer step = 157

确认 strict batch gradient accumulation 逻辑正确。

---

## 正式评估方式

训练完成后，将 checkpoint 复制到独立评估目录：

    data/eval_cp_so3_seed43_final_v3/checkpoints/latest.ckpt

并修改 checkpoint 中保存的 `_output_dir`，
避免评估过程污染训练目录。

评估入口：

    TrainCanonicalWorkspace(...).eval()

评估配置：

- n_test = 50
- n_envs = 4
- test_start_seed = 100000
- max_steps = 400

测试范围：

    seed 100000 ~ 100049

共 50 个 episode。

---

## 最终结果

评估结果：

    38 success
    12 failure

    test/mean_score = 0.7600
    test/max_score = 0.7600

因此：

    Success Rate = 76%

失败 seeds：

    100005
    100006
    100015
    100016
    100017
    100019
    100024
    100025
    100037
    100040
    100044
    100045

---

## 与其他实验比较

当前 Stack D1 多 seed 结果：

| Method | Seed42 | Seed43 | Mean |
|---|---:|---:|---:|
| CP-SO2 | 84% | 76% | 80% |
| CP-SO3 | 72% | 76% | 74% |

论文 Stack D1 CP-SO2 结果：

    79 ± 7 %

当前 CP-SO2 两个 seed 平均：

    80%

CP-SO3 两个 seed 平均：

    74%

均处于论文报告结果附近。

---

## 当前结论

CP-SO3 在 Stack D1 上完成了两个 training seed 的复现：

    seed42 = 72%
    seed43 = 76%

相比 CP-SO2：

    seed42 = 84%
    seed43 = 76%

CP-SO3 整体性能略低，但两个 seed 之间波动较小。

实验表明：

1. Canonical Policy 的 CP-SO2 和 CP-SO3 均可以在本地环境中稳定复现；
2. 多随机种子实验显示模型存在一定性能波动；
3. 当前结果与论文报告的成功率范围一致。

后续可以进一步开展：

- canonical representation / equivariance 验证；
- 第二个 manipulation task 验证；
- 更完整的 benchmark 对比。
