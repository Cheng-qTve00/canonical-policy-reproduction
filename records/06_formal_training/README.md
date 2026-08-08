# 06 CP-SO2 正式训练与评估

## 1. 实验目标

复现 Canonical Policy 在 Stack D1 任务上的 CP-SO2 配置。

本轮实验设置：

- Task：Stack D1
- Policy：CP-SO2
- Demonstrations：200
- Seed：42
- Epochs：250
- Optimizer：AdamW
- Learning rate：8e-5
- LR scheduler：cosine
- Warmup steps：500
- EMA：启用

由于 RTX 4070 Laptop GPU 8 GB 无法安全使用官方物理 batch size 128，本机采用：

```text
physical batch size = 32
gradient_accumulate_every = 4
effective batch size ≈ 128
drop_last = true

每个 epoch：

624 micro-batches
156 optimizer updates

梯度累积相关源码修复见：

records/05_training/gradient_accumulation_fix.patch
## 2. 正式训练

正式训练从头开始：

training.resume = false
logging.resume = false

训练完整完成 250 个 epoch：

first epoch = 0
last epoch = 249
global_step = 155999
optimizer_step = 39000
final learning rate = 0

计算关系：

250 × 624 = 156000 micro-batches
250 × 156 = 39000 optimizer updates

训练程序正常结束：

Exit status: 0

总墙钟时间：

86 h 26 min 04 s

训练完整日志：

formal_training.log

最终解析配置：

resolved_config.yaml
## 3. 训练过程中的测试结果

训练过程中按照环境 runner 的配置周期性进行 rollout。

记录到的 test mean score：

epoch   0: 0.00
epoch  10: 0.48
epoch  20: 0.60
epoch  30: 0.76
epoch  40: 0.72
epoch  50: 0.82
epoch  60: 0.66
epoch  70: 0.70
epoch  80: 0.66
epoch  90: 0.66
epoch 100: 0.70
epoch 110: 0.70
epoch 120: 0.82
epoch 130: 0.76
epoch 140: 0.74
epoch 150: 0.74
epoch 160: 0.74
epoch 170: 0.76
epoch 180: 0.70
epoch 190: 0.72
epoch 200: 0.70
epoch 210: 0.70
epoch 220: 0.70
epoch 230: 0.76
epoch 240: 0.66
epoch 241: 0.66
epoch 242: 0.70
epoch 243: 0.70
epoch 244: 0.74
epoch 245: 0.68
epoch 246: 0.72
epoch 247: 0.66
epoch 248: 0.70
epoch 249: 0.70

训练过程中最高 test mean score：

0.82

分别出现在：

epoch 50
epoch 120

保存下来的最高分 checkpoint 为：

epoch=0050-test_mean_score=0.820.ckpt
## 4. 训练趋势

整体训练过程可以分为三个阶段。

0～20 epoch
0.00 → 0.48 → 0.60

模型快速学习 Stack D1 基本操作。

30～120 epoch

测试成功率进入较高水平：

0.66 ～ 0.82

epoch 50 和 epoch 120 均达到 0.82。

130～249 epoch

测试结果主要维持在：

0.66 ～ 0.76

继续训练到 250 epoch 后没有观察到明显的泛化性能提升。

因此，本次实验中模型大约从 epoch 30 后进入性能平台期。

## 5. 独立评估

为了比较最佳 checkpoint 与最终 checkpoint，使用相同条件进行了独立 rollout。

评估条件：

n_test = 50
test_start_seed = 100000
test seeds = 100000 ~ 100049
max_steps = 400
n_train = 0
n_test_vis = 0

原配置：

n_envs = 26

在本机独立评估时，26 个并行 MuJoCo 环境在 AsyncVectorEnv 初始化阶段无法稳定启动。

经过测试：

n_envs = 1  → 正常
n_envs = 4  → 正常
n_envs = 26 → 初始化异常

因此独立正式评估使用：

n_envs = 4

测试 seed 数量、seed 值及 max_steps 均保持不变。

需要注意，Diffusion Policy 推理包含随机采样，因此改变并行环境数量可能改变随机数消耗顺序。独立评估结果应作为本机稳定评估结果记录，不应视为与原 n_envs=26 条件完全等价。

## 6. 最佳 checkpoint 独立评估

Checkpoint：

epoch 50
training-time test mean score = 0.82

50 个固定测试 seed 独立评估结果：

test mean score = 0.74
success = 37 / 50

日志：

eval_best_epoch0050.log
## 7. 最终 checkpoint 独立评估

Checkpoint：

epoch 249

50 个相同测试 seed 独立评估结果：

test mean score = 0.72
success = 36 / 50

日志：

eval_final_epoch0249.log
## 8. 最佳模型与最终模型比较
Checkpoint	训练过程中记录	独立复评	成功次数
epoch 50	0.82	0.74	37 / 50
epoch 249	0.70	0.72	36 / 50

两者独立评估只相差：

1 / 50 episode

因此不能认为 epoch 50 明显优于最终模型。

更合理的结论是：

CP-SO2 在约 epoch 30 后已经进入性能平台期，后续继续训练到 250 epoch 没有带来明显的测试泛化提升。

训练过程中观测到的最高 0.82 与独立复评 0.74 存在差异，说明单次 rollout 分数具有一定随机波动，因此正式报告中应同时保留训练过程中最高分和独立固定条件复评结果。

## 9. 当前复现结果

本轮实验最终可以记录为：

Task: Stack D1
Method: Canonical Policy CP-SO2
Demos: 200
Seed: 42
Training epochs: 250

Training-time best test score: 0.82
Independent evaluation (epoch 50): 0.74
Independent evaluation (epoch 249): 0.72

当前结果说明模型能够较稳定完成 Stack D1，并具有一定测试场景泛化能力。

后续进行论文结果对照时，应重点核对：

论文/官方报告采用的具体 checkpoint 选择规则；
官方评估是否同样使用 50 个 test seeds；
官方 n_envs=26 与本机 n_envs=4 对随机推理结果的影响；
官方物理 batch size 128 与本机 batch 32 + gradient accumulation 4 的差异；
是否需要多随机种子训练后报告均值与方差。
