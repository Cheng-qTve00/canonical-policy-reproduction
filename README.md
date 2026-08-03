# Canonical Policy Reproduction

本仓库用于记录论文 **Canonical Policy: Learning Canonical 3D Representation for SE(3)-Equivariant Policy** 的复刻过程。

## 说明

- 本仓库不是 Canonical Policy 官方实现。
- 官方代码来源：ZhangZhiyuanZhang/canonical_policy
- 本仓库主要保存环境配置、实验命令、复刻记录和结果分析。
- 原始数据集、处理后的 HDF5 文件和大型模型权重不上传到 GitHub。

## 当前进度

- [x] 完成 WSL2 与 CUDA 环境搭建
- [x] 安装 Canonical Policy 依赖
- [x] 安装 MimicGen、robosuite 和 robomimic
- [x] 下载并验证 Stack D1 数据集
- [x] 跑通单轨迹点云和体素预处理
- [ ] 完成 200 条轨迹正式预处理
- [ ] 转换绝对动作数据
- [ ] 训练 CP-SO2
- [ ] 评估并对比论文结果
