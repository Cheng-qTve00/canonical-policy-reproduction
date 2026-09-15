# 05 训练环境验证与显存测试

## 1. 测试目标

在 RTX 4070 Laptop GPU（8 GB）上验证 Canonical Policy 的训练流程，并确定适合正式复现 Stack D1、CP-SO2、200 demonstrations 的训练参数。

官方配置使用：

- batch size：128
- gradient accumulation：1
- optimizer：AdamW
- learning rate：8e-5
- training epochs：250
- warmup steps：500

由于本机显存不足以安全使用物理 batch size 128，因此测试较小 batch size，并使用梯度累积接近官方有效 batch size。

## 2. 依赖问题与处理

训练启动过程中遇到以下依赖问题：

1. 缺少 `wandb`
   - 安装版本：`wandb==0.17.0`

2. `diffusers==0.11.1` 与较新的 `huggingface-hub` 不兼容
   - 原版本：`huggingface-hub==0.31.4`
   - 调整为：`huggingface-hub==0.25.2`

调整后：

```text
pip check
No broken requirements found.
## 3. Smoke Test

经过三次测试后，模型能够完成初始化、数据集缓存读取、前向传播、反向传播和参数更新。

主要非致命警告：

未安装 OpenGL_accelerate
robomimic 未配置 private macro
PyTorch CuDNN nvrtc.so workaround 警告

这些警告没有阻止训练运行。

## 4. Batch Size 测试
| 物理 Batch Size | 训练步数 | 墙钟时间 | 最大系统内存 | 峰值 GPU 显存 | 结果 |
|---:|---:|---:|---:|---:|---|
| 8 | 20 | 20.80 s | 2,289,436 KB | 未记录 | 成功 |
| 16 | 20 | 24.30 s | 2,302,112 KB | 未记录 | 成功 |
| 32 | 20 | 23.58 s | 2,331,712 KB | 3965 MiB | 成功 |
| 64 | 10 | 27.11 s | 2,379,976 KB | 7599 MiB | 成功但余量过小 |

GPU 总显存约为 8188 MiB。

Batch size 64 已使用约 92.8% 显存，只剩约 589 MiB，因此不适合长期正式训练。没有继续测试 batch size 128，以避免显存溢出。

## 5. 最终训练参数选择

正式训练暂定使用：

physical batch size = 32
gradient_accumulate_every = 4
effective batch size ≈ 128
drop_last = true

使用 drop_last=true 后，每个 epoch 包含：

624 micro-batches
624 / 4 = 156 optimizer updates

这样不会出现未完成的梯度累积跨越 epoch 边界。

需要注意，梯度累积得到的有效 batch size 只是近似官方物理 batch size 128，两种训练方式在随机采样和部分模型运算上仍可能存在细微差异。

## 6. 梯度累积源码问题

原始代码使用：

if self.global_step % cfg.training.gradient_accumulate_every == 0:

由于 global_step 从 0 开始，这会导致第一个微批次就执行参数更新。

同时，EMA 原本在每个微批次后更新，而不是仅在优化器更新后执行。

本次补丁改为：

should_step = (
    (self.global_step + 1)
    % cfg.training.gradient_accumulate_every == 0
)

if should_step:
    self.optimizer.step()
    self.optimizer.zero_grad()
    lr_scheduler.step()

if cfg.training.use_ema and should_step:
    ema.step(self.model)

补丁文件：

gradient_accumulation_fix.patch

该修改不是官方仓库原始实现，正式复现报告中需要明确说明。

## 7. 梯度累积验证

使用以下设置进行了 8 个微批次测试：

batch size = 32
gradient_accumulate_every = 4
max_train_steps = 8

学习率记录：

global_step 0: lr = 0
global_step 1: lr = 0
global_step 2: lr = 0
global_step 3: lr = 1.6e-7

global_step 4: lr = 1.6e-7
global_step 5: lr = 1.6e-7
global_step 6: lr = 1.6e-7
global_step 7: lr = 3.2e-7

这表明优化器分别在第 4 和第 8 个微批次后更新，共执行两次参数更新，梯度累积逻辑符合预期。

## 8. 当前结论

当前环境已经具备正式训练条件：

数据集预处理完成
模型和数据加载正常
前向与反向传播正常
batch size 32 显存余量充足
梯度累积 4 已验证
EMA 更新时机已修正
训练日志和源码补丁均已保存
