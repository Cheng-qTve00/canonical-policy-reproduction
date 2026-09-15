# Canonical Policy 论文复现与实验总结

## 一、实验范围、选择依据与局限性

本项目主要围绕论文 Canonical Policy: Learning Canonical 3D Representation for SE(3)-Equivariant Policy 的公开代码进行复现。

由于论文涉及多个机器人操作任务以及多种方法、随机种子和实验设置，如果完整复现论文中的全部实验，需要较大的训练资源和较长的计算时间。本项目主要使用个人笔记本完成训练，GPU 为 RTX 4070 Laptop GPU，显存约 8 GB，因此在实验数量上无法完全覆盖论文中的所有任务和全部随机种子。

基于计算资源和时间限制，本项目没有将目标设定为“逐项复现论文全部表格”，而是选择了几个能够代表核心方法和完整训练流程的实验。

首先选择 Stack D1 作为主要复现任务。该任务在官方仓库中有明确的 CP-SO2 和 CP-SO3 训练示例，因此可以较好地用于验证环境配置、数据处理、Canonical Encoder、Diffusion Policy 和正式评估等完整流程是否能够复现。同时，CP-SO2 和 CP-SO3 分别对应不同的旋转等变设置，对二者进行比较也能够帮助理解 canonical representation 对不同旋转自由度的处理方式。

在 Stack D1 上，本项目分别对 CP-SO2 和 CP-SO3 使用两个训练随机种子进行实验。虽然两个随机种子仍不足以进行严格的统计分析，但相比只训练一次，可以初步观察模型结果是否对随机初始化较为敏感，并避免只根据单次实验结果进行判断。

在完成 Stack D1 后，又选择 NutAssembly D0 作为第二个操作任务进行训练和评估。该实验的目的是进一步验证此前完成的数据处理、Canonical Policy 训练流程和评估流程能否应用到另一个结构和操作要求不同的 MimicGen 任务中。

NutAssembly D0 的单次完整训练耗时较长，因此目前只完成了 CP-SO2 的一个训练随机种子。该结果主要作为第二任务的补充实验，不能用于判断 NutAssembly 上模型性能的均值、方差或统计稳定性。

因此，本项目目前的实验范围可以概括为：

| 实验内容 | 目的 |
|---|---|
| Stack D1 + CP-SO2 | 主要复现实验 |
| Stack D1 + CP-SO3 | 与 CP-SO2 进行方法对比 |
| Stack D1 两个训练 seed | 初步观察训练随机性 |
| NutAssembly D0 + CP-SO2 | 第二任务的完整训练与评估 |


## 二、项目目标

本项目围绕 Canonical Policy 的公开代码展开，主要希望完成以下工作。

一方面，复现从 MimicGen 数据处理、点云 observation 构建、absolute action 转换，到 Canonical Policy 训练和仿真评估的完整流程。

另一方面，通过 Stack D1 上 CP-SO2 和 CP-SO3 的实验，对论文中的 canonical representation 和不同旋转等变设置形成更具体的理解。

在完成主要任务后，再将同一套训练流程应用到 NutAssembly D0，观察模型在第二个机器人操作任务上的实际训练和评估表现。


## 三、实验环境与本地训练适配

实验主要在个人笔记本的 WSL 环境中完成。

主要软件环境包括 Python、PyTorch、CUDA、PyTorch3D、MuJoCo、robomimic、robosuite、MimicGen 等。

本地 GPU 为 RTX 4070 Laptop GPU，显存约 8 GB。

官方训练配置默认使用较大的 physical batch。在本地硬件条件下，直接使用官方 batch 设置会造成明显的资源压力，并且在后续 NutAssembly 实验中实际观察到训练速度严重下降。

因此本地最终采用：

physical batch size = 32
gradient accumulation = 4

用多个小 batch 的梯度累计尽量保持与较大 effective batch 接近的更新尺度。

这一修改主要属于硬件条件下的训练适配。

## 四、数据处理与动作表示

实验数据来自 MimicGen。

数据大致经历以下流程：

原始 MimicGen HDF5
        ↓
states_to_obs
        ↓
生成 point cloud / voxel observation
        ↓
absolute action conversion
        ↓
*_voxel_abs.hdf5
        ↓
训练 Dataset / DataLoader

Stack D1 和 NutAssembly D0 均使用处理后的 point-cloud 数据进行训练。

实验过程中还专门检查了 absolute action 的维度问题。

经过数据转换后，HDF5 中保存的 action 仍然为 7 维：

3维位置
+
3维 rotation vector
+
1维 gripper
=
7维

而训练配置中使用：

rotation_rep = rotation_6d

因此旋转表示会在后续数据加载和模型表示阶段转换为 6D representation。

所以：

HDF5 中 action 为 7D

和：

模型中的 action representation 为 10D

并不矛盾，而是对应数据处理流程中的不同阶段。

## 五、Stack D1 主实验

Stack D1 是本项目的主要复现任务。

分别训练：

CP-SO2
CP-SO3

并对每种方法使用两个训练随机种子。

正式评估统一使用固定测试种子进行多 episode 测试，以减少不同模型因为测试初始状态不同而导致的比较误差。

目前实验记录中的结果为：

| Task | Method | Training Seed | Evaluation Episodes | Success Rate |
|---|---|---:|---:|---:|
| Stack D1 | CP-SO2 | 42 | 50 | 84% |
| Stack D1 | CP-SO2 | 43 | 50 | 76% |
| Stack D1 | CP-SO3 | 42 | 50 | 72% |
| Stack D1 | CP-SO3 | 43 | 50 | 76% |

按当前记录计算：

CP-SO2 两个 seed 平均：80%
CP-SO3 两个 seed 平均：74%

这里需要保持谨慎。

从两个训练 seed 的结果来看，CP-SO2 的平均成功率高于 CP-SO3，但只有两个随机种子，不足以证明二者存在稳定的统计差异。

同时，单个模型在不同训练 seed 下也出现了明显波动。

例如 CP-SO2 的两次结果并不完全一致，说明机器人模仿学习模型的最终表现仍然受到随机初始化、采样过程等因素影响。

因此更准确的结论是：

在当前两个训练随机种子的实验范围内，CP-SO2 的平均成功率高于 CP-SO3，但由于实验数量有限，该结果主要用于复现趋势和方法比较，不作为统计显著性结论。

## 六、NutAssembly D0 第二任务实验

完成 Stack D1 后，本项目进一步选择 NutAssembly D0 进行完整训练。

NutAssembly 与 Stack 在任务结构和操作要求上存在明显区别，对机械臂末端执行器的位置、姿态以及连续操作过程有更高要求。

该实验主要用于检验此前完成的数据处理、Canonical Policy 模型、训练流程以及正式评估流程是否能够继续应用到第二个任务。

目前完成的是：

Task：NutAssembly D0
Method：CP-SO2
Training seed：43
Demonstrations：200
Training epochs：250

由于本地 8 GB 显存限制，训练仍采用：

physical batch size = 32
gradient accumulation = 4

训练期间为了保证仿真环境稳定运行，关闭了视频可视化，并减少训练阶段的 rollout 环境数量。

## 七、NutAssembly D0 正式评估结果

正式评估共运行 50 个测试 episode。

按照目前实验日志记录，50 次测试结果可以分为三类：

正式评估结果如下：

| Episode 结果 | 数量 | 比例 |
|---|---:|---:|
| reward = 1.0 | 12 | 24% |
| reward = 0.5 | 18 | 36% |
| reward = 0 | 20 | 40% |

完整成功率为 `12 / 50 = 24%`。日志记录的 `test/mean_score = 0.42` 与 reward 分布一致：

$$ (12\times1+18\times0.5+20\times0)/50=0.42 $$

另有 `12 + 18 = 30` 个 episode 获得非零 reward，即 60%。但非零 reward 比例不能等同于完整成功率；完整成功率仍为 24%。

## 八、两个任务实验结果的观察

从目前的实验结果来看，Stack D1 上 CP-SO2 的表现明显高于 NutAssembly D0 上当前这一训练实例的完整成功率。

但这两个结果不能简单用于判断“Canonical Policy 在一个任务有效、在另一个任务无效”。

Stack D1 已经进行了两个训练随机种子，而 NutAssembly 目前只有一个训练随机种子；同时两个任务自身的操作难度、reward 定义和操作过程也不同。

NutAssembly 中存在较多 reward=0.5 的部分完成结果，说明部分测试 episode 获得了中间阶段奖励。

这说明问题并不一定出现在模型完全无法理解目标，而可能更多集中在：

完成前一部分操作
        ↓
保持操作稳定
        ↓
继续完成后续阶段
        ↓
最终任务成功

这一连续过程中。具体失败阶段仍需结合视频或更细的轨迹记录进一步分析。

如果后续继续研究，相比单纯增加训练 epoch，更值得分析 reward=0.5 episode 的具体失败阶段。

## 九、复现过程中遇到的主要工程问题

本次实验过程中遇到的问题主要集中在硬件适配、仿真环境和实验配置管理三个方面。

首先是本地 GPU 条件。

官方训练参数并不一定适合 RTX 4070 Laptop GPU。NutAssembly 的实际测速中发现，不同 physical batch size 对训练速度的影响非常明显，因此最终仍采用 batch32 + gradient accumulation 的方案。

其次是 MuJoCo / robosuite 环境。

NutAssembly 在部分渲染设置下曾出现底层 OpenGL / renderer 相关问题。关闭训练期间的视频可视化、减少并行环境后可以稳定训练。

这说明机器人学习代码中的训练速度和稳定性并不完全取决于神经网络，仿真环境本身也可能成为重要的工程瓶颈。

最后是 Hydra 配置管理问题。

实验过程中发现，已经完全解析过的配置文件如果被直接复制到另一个任务，部分：

task_name
dataset_path
env_runner.dataset_path

可能已经固定为旧实验值。

因此后续形成了一套正式训练前检查流程。

在开始耗时较长的训练之前，必须确认：

task_name
dataset_path
env_name
training seed
pointnet_type
num_epochs
max_steps
output directory

并先进行短时间 smoke test。

这一经验对后续机器人学习实验尤其重要，因为一次错误配置可能造成较大的计算时间浪费。

## 十、实验结果的局限性

当前实验最大的限制仍然是计算资源。

Stack D1 只完成了两个训练随机种子，因此不能进一步计算可靠的方差、置信区间或统计显著性。

NutAssembly D0 目前只有 CP-SO2 seed43 一个完整模型，因此：

24% success rate
0.42 mean score

只能描述这一具体实验实例。

如果以后获得服务器计算资源，更完整的实验应当继续补充：

NutAssembly 多训练 seed
NutAssembly CP-SO3
更多论文任务
其他 baseline

从而判断当前观察到的趋势是否稳定。

## 十一、总结

本项目完成了 Canonical Policy 从环境搭建、MimicGen 数据处理、点云 observation 构建、absolute action 转换、Canonical Policy 训练到正式仿真评估的一整套复现流程。

Stack D1 作为主要复现任务，完成了 CP-SO2 和 CP-SO3 两种设置、各两个训练随机种子的实验。

在当前实验范围内，CP-SO2 两个 seed 的平均成功率为 80%，CP-SO3 为 74%。

随后又完成了 NutAssembly D0 的 CP-SO2 训练和 50 次正式测试。当前 seed43 模型取得 24% 的完整成功率和 0.42 的 mean score，其中 60% 的测试 episode 获得了非零 reward。

相比单纯得到最终成功率，本次复现过程中更重要的收获是逐步理解了一个机器人模仿学习项目中：

原始数据
→ 点云表示
→ 动作表示
→ 模型结构
→ 训练过程
→ 仿真环境
→ 正式评估

之间的关系。

同时也认识到，论文复现并不仅仅是让代码能够运行。硬件条件、训练协议、随机种子、环境设置、评估种子以及配置管理都会直接影响最终结果。

目前的实验数量虽然还不足以完整复现论文全部 benchmark，但已经形成了一套能够重复执行和核验的实验流程，并完成了两个机器人操作任务上的完整训练与评估。
