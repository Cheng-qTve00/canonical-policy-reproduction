# Canonical Policy 论文复现

本仓库用于记录论文 **Canonical Policy: Learning Canonical 3D Representation for SE(3)-Equivariant Policy** 的复现过程，包括环境配置、数据处理、训练协议修改、实验日志、评估结果和偏差分析。

## 官方项目

官方代码仓库：

    ZhangZhiyuanZhang/canonical_policy

本次复现固定使用官方 commit：

    de5a897e1fba61fa9f443834cedc60dde907e7eb

本仓库不是 Canonical Policy 官方实现，而是个人复现实验记录仓库。

大型数据集、处理后的 HDF5 文件和模型 checkpoint 不上传到 GitHub。

---

## 本地环境

主要硬件：

- Lenovo Legion / Y9000P
- Windows 11 + WSL Ubuntu 22.04
- NVIDIA RTX 4070 Laptop GPU
- 8GB GPU memory

主要软件环境：

- Conda env: `cp`
- Python 3.9.15
- PyTorch 2.1.0
- CUDA 11.8
- PyTorch3D 0.7.5
- MuJoCo 2.3.2
- robomimic
- robosuite
- MimicGen

完整环境信息记录在：

    records/00_environment/

---

## 当前复现任务

当前主要复现任务：

- Task: Stack D1
- Demonstrations: 200
- Training seeds: 42, 43
- Epochs: 250

已完成：

- CP-SO2
- CP-SO3
- NutAssembly D0 / CP-SO2 / seed43

完整实验总结见 [`records/canonical_policy_experiment_record.md`](records/canonical_policy_experiment_record.md)。

---

## 数据验证

原始 Stack D1 数据集包含：

    1000 demonstrations

当前实验使用：

    demo_0 ~ demo_199

共：

    200 demonstrations
    21561 transitions

训练 / 验证划分：

    198 train demos
    2 validation demos

对应训练 sequence 数量：

    19975

另外重新从原始数据处理过 `demo_0`，并与现有预处理 HDF5 中结果进行比较，确认点云结果一致。

数据和预处理记录见：

    records/01_dataset/
    records/02_preprocess_test/
    records/03_preprocess_200/
    records/04_action_conversion/

---

## 8GB GPU 下的训练协议调整

官方训练使用：

    physical batch size = 128
    gradient accumulation = 1
    drop_last = False

由于 RTX 4070 Laptop GPU 8GB 显存无法直接使用 batch size 128，本地采用：

    physical batch size = 32
    gradient accumulation = 4
    drop_last = False

对于 19975 个训练 sequences：

    625 micro-batches / epoch

其中：

    前 624 个 micro-batch = 32 samples
    最后 1 个 micro-batch = 7 samples

最终训练逻辑为：

    4 × 32 samples
    -> 1 optimizer update

最后：

    7 samples
    -> 1 independent optimizer update

因此：

    157 optimizer updates / epoch
    250 epochs
    -> 39250 optimizer updates

LR scheduler 和 EMA 均只在真正 optimizer update 时更新。

这一设置属于对官方 batch128 训练协议的近似模拟，而不是 bitwise exact reproduction。

详细修改、错误版本和验证记录见：

    records/05_training/
    records/06_formal_training/
    records/08_strict_batch_test/

---

## Strict Batch 调试记录

训练协议修改过程中曾出现一次严重缩进错误。

错误版本虽然表面完成了大量 epoch，但 loss、backward 和 optimizer step 被错误移动到 dataloader 循环外部，因此 optimizer 实际更新次数严重异常。

该实验结果被判定为无效，不用于最终复现结果。

最终修复后进行了独立 1 epoch 验证：

    epoch = 0
    global_step = 624
    optimizer_step = 157

符合理论预期：

    625 micro-batches
    -> 157 optimizer updates

最终正确训练 workspace：

    records/08_strict_batch_test/
    train_canonical_workspace_final_corrected.py

该文件的 SHA256 已验证与正式训练时项目中实际使用的：

    canonical_policy/workspace/train_canonical_workspace.py

完全一致。

---

## 最终实验结果概览

| Task | Method | Seed | Success Rate / Score |
|---|---|---:|---:|
| Stack D1 | CP-SO2 | 42 | 84% |
| Stack D1 | CP-SO2 | 43 | 76% |
| Stack D1 | CP-SO3 | 42 | 72% |
| Stack D1 | CP-SO3 | 43 | 76% |
| NutAssembly D0 | CP-SO2 | 43 | 24% full completion, mean score 0.42 |

Stack CP-SO2 两个训练 seed 的平均成功率为 80%，CP-SO3 为 74%。

Stack 目前只有两个 training seeds，不能据此声称统计显著；NutAssembly 目前只有一个 training seed。详细实验过程见 `records/` 下对应目录，完整总结见 [`records/canonical_policy_experiment_record.md`](records/canonical_policy_experiment_record.md)，精简结果表见 [`records/final_results_summary.md`](records/final_results_summary.md)。

## 当前完成进度

- [x] WSL2 与 CUDA 环境搭建
- [x] Canonical Policy 依赖安装
- [x] MimicGen / robosuite / robomimic 配置
- [x] Stack D1 数据集下载与验证
- [x] 200 demonstrations 点云预处理
- [x] absolute action conversion
- [x] batch32 + gradient accumulation4 显存适配
- [x] strict-batch 逻辑验证
- [x] CP-SO2 正式训练
- [x] CP-SO2 50-episode 独立评估
- [x] CP-SO3 正式训练
- [x] CP-SO3 50-episode 独立评估
- [x] Stack D1 第二个 training seed（CP-SO2 / CP-SO3）
- [x] NutAssembly D0 第二任务训练与评估（CP-SO2 seed43）
- [ ] equivariance / canonicalization 原理验证
- [x] 最终实验汇总与论文对照分析

---

## 当前结果的适用范围

目前可以认为已经完成：

> Stack D1 上 CP-SO2 和 CP-SO3 的两个 seed 复现实验，以及 NutAssembly D0 CP-SO2 seed43 的补充实验。

目前不能声称：

> 已完整复现 Canonical Policy 论文全部实验结果。

原因包括：

1. Stack D1 已有 training seed = 42、43；NutAssembly 当前只有 seed = 43；
2. 论文结果通常报告 mean ± std；
3. 尚未复现全部 manipulation tasks；
4. 尚未复现全部 baseline；
5. 本地受显存限制，使用 batch32 + gradient accumulation4 模拟官方 batch128；
6. 训练期间 rollout 配置为了降低本地计算成本进行了缩减。

因此，本仓库重点记录的是：

> 在有限计算资源条件下，对 Canonical Policy 核心方法进行可验证、可追踪的代表性复现。

---

## 后续计划

优先考虑：

1. 增加 training seeds，验证结果稳定性；
2. 增加更多 manipulation tasks；
3. 利用官方 canonical representation / equivariance 代码进行轻量原理验证；
4. 补充实验可视化和典型成功/失败案例分析。

不计划为了形式上的“完整”强行重跑全部 benchmark。

复现过程中优先保证：

    数据可验证
    配置可追踪
    修改有记录
    checkpoint 可核验
    evaluation 独立
    结果有日志
    偏差如实说明
