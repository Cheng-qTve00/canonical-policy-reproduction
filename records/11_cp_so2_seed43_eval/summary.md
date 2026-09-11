# CP-SO2 Seed43 正式评估

## 实验目的

本实验用于检验 CP-SO2 在不同 training seed 下的结果稳定性。

此前 Stack D1 上已经完成：

    CP-SO2
    training seed = 42
    Success Rate = 84%

本次保持任务、数据、训练协议和评估协议不变，仅将：

    training.seed = 42

改为：

    training.seed = 43

数据集划分 seed 仍保持原配置，不随 training seed 改变。

---

## 训练配置

- Task: Stack D1
- Method: CP-SO2
- Demonstrations: 200
- Training seed: 43
- Epochs: 250
- Physical batch size: 32
- Gradient accumulation: 4
- drop_last: False

正式训练目录：

    data/outputs/cp_so2_seed43_final_v2

最终 checkpoint 状态：

    epoch = 249
    global_step = 156249
    optimizer step = 39250

说明训练完整执行了：

    157 optimizer updates / epoch
    × 250 epochs
    = 39250 optimizer updates

与 seed42 的训练步数完全一致。

---

## Smoke Test

正式训练前进行了 1 epoch smoke test。

训练集共有：

    19975 sequences

在 physical batch size = 32 时：

    625 micro-batches / epoch

checkpoint 检查结果：

    epoch = 0
    global_step = 624

进一步读取 AdamW optimizer state，210 个具有 optimizer state 的参数均显示：

    optimizer step = 157

因此确认：

    625 micro-batches
    -> 157 optimizer updates

seed43 下 strict-batch / gradient accumulation 逻辑正常。

Smoke test 末尾曾因关闭 test rollout 后缺少 `test_mean_score`，在 top-k checkpoint 阶段出现：

    KeyError: 'test_mean_score'

该错误发生在 `latest.ckpt` 已保存之后，与模型训练本身无关。

---

## 正式评估方式

正式训练完成后，将最终 checkpoint 复制到独立评估目录：

    data/eval_cp_so2_seed43_final_v2/checkpoints/latest.ckpt

并修改 checkpoint 中保存的 `_output_dir`，使其指向独立评估目录。

正式评估通过：

    TrainCanonicalWorkspace(...).eval()

执行，不使用 `train.py` 作为评估入口。

评估配置：

- n_train = 0
- n_train_vis = 0
- n_test = 50
- n_test_vis = 0
- n_envs = 4
- test_start_seed = 100000
- max_steps = 400

测试 seeds：

    100000 ~ 100049

共 50 个 episode。

该评估协议与 CP-SO2 seed42 及此前 CP-SO3 seed42 的正式评估保持一致。

---

## 最终结果

评估结果：

    38 success
    12 failure

    test/mean_score = 0.7600
    test/max_score = 0.7600

即：

    Success Rate = 76%

失败 seeds：

    100004
    100006
    100013
    100014
    100015
    100016
    100022
    100025
    100041
    100044
    100045
    100046

其余 38 个 test seeds 成功。

完整日志：

    eval_50episodes.log

---

## 与 Seed42 的比较

当前 CP-SO2 已完成两个 training seeds：

    seed42 = 84%
    seed43 = 76%

两次实验的简单平均成功率为：

    (84% + 76%) / 2 = 80%

论文中 Stack D1 CP-SO2 报告结果约为：

    79 ± 7 %

目前两个 training seed 的平均结果与论文报告的中心水平较为接近。

不过当前仍只有两个 training seeds，因此还不足以稳定估计 mean 和 standard deviation。

计划继续增加至少一个 training seed，以进一步观察训练随机性带来的性能波动。

---

## 当前结论

seed43 的结果低于 seed42：

    84% -> 76%

相差：

    8 percentage points

这说明单次训练结果存在较明显的随机波动。

因此，seed42 得到的 84% 不应被视为 CP-SO2 的固定性能。

目前更合理的描述是：

> 在 Stack D1、200 demonstrations 和统一训练/评估协议下，CP-SO2 在两个不同 training seeds 上分别取得 84% 和 76% 的成功率，简单平均为 80%。该结果表明模型存在一定跨训练随机种子的性能波动，同时当前平均水平与论文报告的约 79% 处于接近范围。

由于目前只有两个 training seeds，不对统计显著性或最终方差作进一步结论。
