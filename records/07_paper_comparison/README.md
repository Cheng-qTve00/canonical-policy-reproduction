# 07 论文结果对照

> **历史阶段记录**
>
> 本文件记录的是 strict-batch 最终协议确定之前的早期 Stack D1 / CP-SO2 训练与论文对照分析，保留用于追踪复现过程，不作为仓库最终结果。
>
> 最终有效结果请以以下文件为准：
>
> - `records/09_strict_batch_final_v2_eval/`
> - `records/10_cp_so3_final_v2_eval/`
> - `records/11_cp_so2_seed43_eval/`
> - `records/12_cp_so3_seed43_eval/`
> - `records/final_results_summary.md`


## 1. 对照目标

本阶段用于比较当前 Stack D1 / CP-SO2 复现实验与 Canonical Policy 论文报告结果。

论文：

Canonical Policy: Learning Canonical 3D Representation for SE(3)-Equivariant Policy

arXiv:2505.18474v2

当前本地实验：

- Task: Stack D1
- Policy: CP-SO2
- Demonstrations: 200
- Training seed: 42
- Epochs: 250

---

## 2. 论文正式主实验协议

论文在 MimicGen 任务上采用：

- 200 demonstrations
- 训练 250 epochs
- 训练随机种子：
  - 42
  - 43
  - 44
- 每个 seed 使用最后 10 个 epoch 的评估结果
- 每次 rollout 使用 50 个不同的 environment initializations
- 最终综合多个训练 seed 的结果进行报告

因此，论文主表中的结果不是：

- 单个 checkpoint 的最高成绩
- 单次 rollout 的成绩
- 单个训练 seed 的成绩

而是多个后期 checkpoint 和多个训练 seed 综合后的统计结果。

---

## 3. 论文 Stack D1 结果

论文 Table II 中 Stack D1 的结果为：

| Method | Stack D1 success rate |
|---|---:|
| DP3 | 23 ± 3% |
| iDP3 | 23 ± 7% |
| EquiBot | 1 ± 1% |
| CP-SO3 | 71 ± 5% |
| CP-SO2 | 79 ± 7% |

因此，CP-SO2 在 Stack D1 主实验中的论文结果为：

```text
79 ± 7%
```

该结果综合了多个训练随机种子，包括 seed 42、43、44。

---

## 4. 单 seed 42 的论文参考结果

论文消融实验固定使用 random seed 42，并同样基于后期多个 checkpoint 进行评估。

其中，与完整 CP-SO2 配置对应的 Stack D1 结果约为：

```text
76 ± 5%
```

因此，在当前只完成 seed 42 训练的情况下：

```text
76 ± 5%
```

比主实验中的：

```text
79 ± 7%
```

更适合作为当前阶段的参考量级。

需要注意：

论文不同表格对应不同实验目的，因此不能把所有表格中的数值简单视为完全相同的一次实验。

这里主要将 `76 ± 5%` 作为单 seed 42 条件下的参考结果。

---

## 5. 当前复现实验最后 10 个 epoch

本地正式训练日志位于：

```text
records/06_formal_training/formal_training.log
```

最后 10 个 epoch 的 test mean score 为：

```text
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
```

算术平均：

```text
69.2%
```

观测范围：

```text
66% ～ 74%
```

当前暂不把本地波动写成与论文中的 `±` 完全等价的统计量，因为还没有完全确认论文表格中 `±` 的具体统计定义。

---

## 6. 当前结果与论文对照

| Result | Stack D1 |
|---|---:|
| 论文主实验，3 seeds | 79 ± 7% |
| 论文 seed 42 参考 | 76 ± 5% |
| 本地 seed 42，最后 10 epochs 平均 | 69.2% |
| 本地训练最高单次 test score | 82% |
| epoch 50 独立复评 | 74% |
| epoch 249 独立复评 | 72% |

与 seed 42 论文参考均值相比：

```text
76.0% - 69.2% = 6.8 percentage points
```

与论文三 seed 主实验均值相比：

```text
79.0% - 69.2% = 9.8 percentage points
```

---

## 7. 当前复现程度判断

当前实验不能表述为：

> 已严格复现论文 79 ± 7% 的结果。

更准确的表述是：

> 已成功复现 Canonical Policy 的 Stack D1 / CP-SO2 完整训练流程，模型成功率达到论文结果相同量级，但当前 seed 42 最后 10 个 epoch 的平均成功率为 69.2%，仍低于论文单 seed 42 参考结果约 6.8 个百分点。

模型训练过程中曾两次达到：

```text
82%
```

分别出现在：

```text
epoch 50
epoch 120
```

说明当前实现具备达到论文报告性能区间的能力。

但是论文正式指标关注的是训练后期多个 checkpoint 的整体表现，因此不能使用训练过程中最高单次 82% 直接代替论文结果。

---

## 8. 已知实验差异

### 8.1 Batch size

官方配置：

```text
physical batch size = 128
```

本机由于 RTX 4070 Laptop GPU 8 GB 显存限制，采用：

```text
physical batch size = 32
gradient_accumulate_every = 4
effective batch size ≈ 128
```

梯度累积可以近似保持 effective batch size，但并不意味着训练过程与真实 physical batch size 128 完全等价。

---

### 8.2 Gradient accumulation

为了正确实现 gradient accumulation，本地对训练 workspace 做了修复：

```text
records/05_training/gradient_accumulation_fix.patch
```

修复后的行为为：

- 每 4 个 micro-batches 执行一次 optimizer step
- EMA 只在 optimizer step 后更新
- learning rate scheduler 只在 optimizer step 后更新

该修改是本机显存适配所需，不属于论文原始实验设置。

---

### 8.3 独立评估并行环境数

原训练配置中的环境并行数为：

```text
n_envs = 26
```

本机进行独立复评时，26 个 AsyncVectorEnv 无法稳定初始化。

测试结果：

```text
n_envs = 1  → 正常
n_envs = 4  → 正常
n_envs = 26 → 无法稳定初始化
```

因此独立正式评估采用：

```text
n_envs = 4
```

其他主要评估条件保持：

```text
n_test = 50
test seeds = 100000 ～ 100049
max_steps = 400
```

由于 Diffusion Policy 推理包含随机采样，改变并行环境数量可能改变随机数消耗顺序。

因此独立复评结果：

```text
epoch 50: 74%
epoch 249: 72%
```

只作为辅助验证结果，不直接替代论文正式评估指标。

---

## 9. 训练过程中的性能趋势

训练初期：

```text
epoch 0:  0.00
epoch 10: 0.48
epoch 20: 0.60
```

说明模型在前 20 个 epoch 中快速学习任务。

在 epoch 30 之后，测试成功率基本进入：

```text
0.66 ～ 0.82
```

的平台区间。

两个最高点：

```text
epoch 50:  0.82
epoch 120: 0.82
```

训练后期没有继续明显提升。

最后 10 个 epoch：

```text
0.66
0.66
0.70
0.70
0.74
0.68
0.72
0.66
0.70
0.70
```

平均：

```text
69.2%
```

因此当前训练表现更接近：

> 模型较早达到性能平台，随后长期波动，而不是随着训练轮数持续提高。

---

## 10. 当前最值得调查的差距来源

目前不能简单把约 6.8 个百分点的差距归因于某一个原因。

后续优先调查：

1. physical batch size 128 与 batch size 32 + gradient accumulation 4 是否造成实际训练差异；
2. 本地 gradient accumulation 修改与官方训练行为是否还存在其他细节差异；
3. PyTorch、MuJoCo、CUDA、Diffusers 等依赖环境是否与官方实验完全一致；
4. 数据预处理结果是否与作者实际使用的数据完全一致；
5. seed 42 单次训练自身的随机波动；
6. 论文 checkpoint 统计与评估流程的具体实现；
7. n_envs 对 Diffusion Policy 随机推理结果的影响；
8. 是否必须完成 seed 43、44 才能与论文 Table II 进行严格比较。

---

## 11. 当前实验的重要结果

当前第一轮复现结果为：

```text
Task: Stack D1
Method: Canonical Policy CP-SO2
Demonstrations: 200
Seed: 42
Epochs: 250

Training-time best test score: 82%

Final 10 epochs:
66%, 66%, 70%, 70%, 74%,
68%, 72%, 66%, 70%, 70%

Final-10 mean:
69.2%

Independent evaluation:
epoch 50  = 74% (37/50)
epoch 249 = 72% (36/50)
```

论文参考：

```text
Paper CP-SO2 Stack D1, 3 seeds:
79 ± 7%

Paper seed-42 reference:
approximately 76 ± 5%
```

---

## 12. 当前结论

第一轮复现可以定性为：

```text
训练流程复现：成功
数据处理流程：成功
模型正常学习任务：成功
达到论文相同性能量级：是
严格数值复现：尚未达到
```

当前最核心的对照为：

```text
Paper CP-SO2 Stack D1 (3 seeds): 79 ± 7%
Paper seed-42 reference:          76 ± 5%
Our seed-42 final-10 mean:        69.2%
Our best observed rollout:        82%
Our epoch-50 re-evaluation:       74%
Our epoch-249 re-evaluation:      72%
```

因此，目前不能简单继续增加训练时间。

下一阶段应优先定位实验设置和官方实现之间的差异，再决定是否进行第二轮长时间训练。
