# CP-SO3 最终正式评估

## 实验信息

本实验对应 Canonical Policy 在 Stack D1 任务上的 CP-SO3 复现结果。

主要训练配置：

- Task: Stack D1
- Method: CP-SO3
- Demonstrations: 200
- Training seed: 42
- Epochs: 250
- Physical batch size: 32
- Gradient accumulation: 4
- `drop_last = False`

本实验与 CP-SO2 正式实验保持相同的本地训练条件，主要区别仅为：

    policy.pointnet_type = cp_so3

因此可以用于与 CP-SO2 进行直接对照。

最终有效训练目录：

    data/outputs/cp_so3_final_v2

## 最终训练状态验证

正式评估前检查最终 checkpoint，得到：

    epoch = 249
    global_step = 156249
    optimizer_step = 39250

说明 CP-SO3 同样完成了：

    250 epochs
    157 optimizer updates / epoch
    39250 optimizer updates in total

训练步数与 CP-SO2 完全一致。

## 评估方式

为了避免修改原始训练 checkpoint，先复制模型到独立评估目录：

    data/eval_cp_so3_final_v2/checkpoints/latest.ckpt

然后使用：

    TrainCanonicalWorkspace(...).eval()

进行独立 rollout。

没有使用：

    python train.py

作为评估入口，因为 `train.py` 默认调用 `workspace.run()`，会重新进入训练流程。

评估配置：

- `n_train = 0`
- `n_train_vis = 0`
- `n_test = 50`
- `n_test_vis = 0`
- `n_envs = 4`
- `test_start_seed = 100000`
- `max_steps = 400`

因此测试 episode 对应：

    seed 100000 ~ 100049

共 50 个独立测试环境。

该评估协议与 CP-SO2 最终正式评估完全一致。

## 最终结果

最终结果：

    36 success
    14 failure
    test/mean_score = 0.7200
    test/max_score = 0.7200

即：

    Success Rate = 72%

失败 seeds：

    100000
    100004
    100006
    100007
    100010
    100012
    100013
    100015
    100019
    100020
    100027
    100040
    100044
    100045

其余 36 个测试 seed 均成功。

完整评估日志保存在：

    eval_50episodes.log

## 与 CP-SO2 的直接对照

CP-SO2：

    42 / 50 success
    Success Rate = 84%

CP-SO3：

    36 / 50 success
    Success Rate = 72%

两者使用：

- 相同任务
- 相同 demonstration 数量
- 相同 training seed
- 相同 epochs
- 相同 batch / gradient accumulation 设置
- 相同 optimizer update 数量
- 相同 50 个 test seeds
- 相同 max_steps
- 相同 n_envs

因此，这是一组直接的 paired comparison。

结果显示：

    CP-SO2 比 CP-SO3 高 12 个百分点

该段只比较 seed42 的单次结果，不能据此声称 CP-SO2 在统计意义上显著优于 CP-SO3；完整的双 seed 结果见 `records/final_results_summary.md`。

更准确的表述是：

> 在本次 Stack D1、200 demonstrations、seed42 的复现实验中，CP-SO2 的成功率为 84%，CP-SO3 为 72%，CP-SO2 在当前实验条件下表现更好。

## Seed 级别对比

两种方法都成功的测试 seed 数量：

    34

两种方法都失败的测试 seeds：

    100012
    100015
    100019
    100020
    100044
    100045

即共同失败：

    6 / 50

CP-SO2 成功但 CP-SO3 失败：

    8

CP-SO3 成功但 CP-SO2 失败：

    2

这说明在相同测试初始条件下，本次实验中 CP-SO2 对更多测试 seed 表现出了成功行为。

## 复现偏差说明

与 CP-SO2 一样，本实验属于有限 GPU 资源下的训练协议近似复现。

主要偏差包括：

1. physical batch size 从官方 128 调整为 32，并使用 gradient accumulation = 4；
2. 训练期间的 rollout 配置经过缩减；
3. physical batch size 的不同可能导致 diffusion 训练随机数消耗顺序与官方实现存在差异。

因此，当前结果应理解为：

> 在统一且经过验证的本地复现条件下，对 CP-SO2 与 CP-SO3 进行的代表性实验比较。

而不能表述为对论文全部统计实验的完整复现。
