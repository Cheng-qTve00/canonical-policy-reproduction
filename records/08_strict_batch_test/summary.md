# Strict Batch 模拟与调试记录

## 背景

Canonical Policy 官方训练配置中使用：

- physical batch size = 128
- gradient accumulation = 1
- `drop_last = False`

由于本地 RTX 4070 Laptop GPU 只有 8GB 显存，无法直接使用 batch size 128，因此本地复现采用：

- physical batch size = 32
- gradient accumulation = 4
- `drop_last = False`

对于 Stack D1 的训练集：

- train sequences = 19975
- batch size 32 时，每个 epoch 一共有 625 个 micro-batch
- 前 624 个 micro-batch 每个包含 32 个样本
- 最后一个 micro-batch 只有 7 个样本

因此，本地希望模拟出的训练协议为：

- 每 4 个完整的 32-sample micro-batch 组成一次 optimizer update
- 最后 7 个样本单独作为一次完整权重的 optimizer update
- 每个 epoch 共 157 次 optimizer update
- 250 epochs 共 39250 次 optimizer update

## 代码修改过程

### `train_canonical_workspace_INVALID_INDENT.py`

该文件记录了一次无效的中间实现。

当时已经加入了 strict-batch 相关逻辑，包括：

- 最后一个短 batch 单独更新
- optimizer step 按 batch accumulation 进行
- scheduler 和 EMA 跟随 optimizer step 更新

但是在自动修改代码时发生了缩进错误。

原本应该位于：

    for batch_idx, batch in enumerate(tepoch):

循环内部的以下训练逻辑：

- loss 计算
- backward
- optimizer step
- scheduler step
- EMA 更新
- logging

被错误移动到了 dataloader 循环外部。

因此，使用该版本产生的训练结果属于无效实验，不能作为最终复现结果。

---

### `train_canonical_workspace_final_corrected.py`

该文件是修复后的最终有效训练 workspace。

主要修正包括：

- 将训练逻辑重新放回 dataloader 循环内部
- gradient accumulation 在每个 epoch 内独立进行
- 最后一个 7-sample batch 单独执行一次 optimizer update
- LR scheduler 只在真正 optimizer update 时更新
- EMA 只在真正 optimizer update 时更新
- 使用本地 `DummyWandbRun` 替代在线 WandB 日志

已经通过 SHA256 校验确认：

    records/08_strict_batch_test/train_canonical_workspace_final_corrected.py

与最终正式训练时实际使用的：

    canonical_policy/workspace/train_canonical_workspace.py

内容完全一致。

该版本用于后续正式 CP-SO2 和 CP-SO3 训练。

## 1 Epoch 验证

`strict_batch_1epoch.log` 记录了正式长训练前进行的 1 epoch 验证。

理论预期：

    625 micro-batches
    157 optimizer updates

实际 checkpoint 检查结果与预期一致：

    epoch = 0
    global_step = 624
    optimizer_step = 157

因此可以确认修正后的 gradient accumulation 和最后一个短 batch 处理逻辑工作正常。

## 说明

本地采用的：

    physical batch size = 32
    gradient accumulation = 4

目的是在 8GB 显存限制下尽可能模拟官方：

    physical batch size = 128
    gradient accumulation = 1

的训练协议。

但这并不是 bitwise exact reproduction。

由于 physical batch size 不同，diffusion 训练过程中的随机数消耗顺序等细节仍可能与官方直接 batch128 训练存在差异。

因此最终报告中应将其描述为：

> 在本地 GPU 显存限制下进行的训练协议近似复现，而非逐比特完全一致复现。
