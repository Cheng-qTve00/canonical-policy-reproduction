# CP-SO2 最终正式评估

## 实验信息

本实验对应 Canonical Policy 在 Stack D1 任务上的 CP-SO2 复现结果。

主要训练配置：

- Task: Stack D1
- Method: CP-SO2
- Demonstrations: 200
- Training seed: 42
- Epochs: 250
- Physical batch size: 32
- Gradient accumulation: 4
- `drop_last = False`

由于本地 RTX 4070 Laptop GPU 只有 8GB 显存，训练采用 batch32 + gradient accumulation4 的方式近似模拟官方 batch128 训练协议。

最终有效训练目录：

    data/outputs/strict_batch_final_v2

## 最终训练状态验证

正式评估前检查最终 checkpoint，得到：

    epoch = 249
    global_step = 156249
    optimizer_step = 39250

其中：

- 每个 epoch 有 625 个 micro-batch
- 每个 epoch 有 157 次 optimizer update
- 250 epochs 共 39250 次 optimizer update

因此最终 checkpoint 的训练步数与预期一致。

## 评估方式

没有使用：

    python train.py

直接进行评估，因为 `train.py` 默认进入 `workspace.run()`，会重新执行训练流程。

正式评估使用：

    TrainCanonicalWorkspace(...).eval()

为了避免修改原始训练 checkpoint，先复制模型到独立评估目录：

    data/eval_strict_batch_final_v2/checkpoints/latest.ckpt

然后进行独立 rollout。

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

## 最终结果

最终结果：

    42 success
    8 failure
    test/mean_score = 0.8400
    test/max_score = 0.8400

即：

    Success Rate = 84%

失败 seeds：

    100011
    100012
    100015
    100016
    100019
    100020
    100044
    100045

其余 42 个测试 seed 均成功。

完整评估日志保存在：

    eval_50episodes.log

## 与论文结果对照

论文中 Stack D1 / CP-SO2 报告结果约为：

    79 ± 7 %

本次单次 training seed = 42 的复现实验得到：

    84%

因此，本次结果与论文报告的性能水平处于同一范围。

但需要注意：

- 本次 84% 仅来自一个训练 seed
- 论文报告的是 mean ± std
- 因此不能用单次 84% 直接声称完整复现了论文统计结果
- 更准确的表述是：Stack D1 + CP-SO2 的单次代表性实验复现成功，并达到与论文相近的性能水平

## 复现偏差说明

本次训练并不是逐比特完全复现官方实验。

主要偏差包括：

1. 本地显存限制导致 physical batch size 从官方的 128 调整为 32，并使用 gradient accumulation = 4。
2. 正式训练期间为了降低 rollout 开销，缩减了训练过程中的环境评估规模。
3. Physical batch size 的变化可能影响 diffusion 训练中的随机数消耗顺序。

因此，本实验应描述为在有限 GPU 资源条件下进行的训练协议近似复现。

最终独立测试协议、数据、训练步数和 checkpoint 状态均进行了单独验证。
