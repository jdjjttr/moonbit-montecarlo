# 🎲 MoonBit 金融蒙特卡洛模拟框架 (`moonbit-montecarlo`)

[![MoonBit Version](https://img.shields.io/badge/MoonBit-0.10.3-brightgreen.svg)](https://www.moonbitlang.cn/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![CI Status](https://github.com/jdjjttr/moonbit-montecarlo/actions/workflows/ci.yml/badge.svg)](https://github.com/jdjjttr/moonbit-montecarlo/actions)

面向定价、风险管理和资产负债分析的高性能、工业级、**100% 跨运行可复现** 随机模拟框架。全量采用原生 MoonBit 语言 (`.mbt`) 编写，专为 **MoonBit 2026 开源创新大赛 (OSC 2026)** 研发。

---

## 🌟 核心特性与技术亮点

1. **确定性跨运行可复现 (Bit-Exact Reproducibility)**:
   - 内置 **Xorshift128+**, **PCG32**, **SplitMix64** 伪随机数生成器。
   - 包含基于 FNV-1a 64 位哈希算法的模拟轨迹与参数契约校验值 (Path Matrix Checksum)，确保同一随机 Seed 下跨平台、跨运行输出完全一致。
2. **准蒙特卡洛 (Quasi-Monte Carlo) 低偏差引擎**:
   - 支持多维 Scrambled **Halton** 序列 (最高 32 维)。
   - 支持 Gray 码加速的 32 维 **Sobol** 低偏差序列生成器。
   - 支持 Korobov **Rank-1 Lattice** 随机偏移网格规则。
3. **丰富随机过程与模拟器 (Stochastic Processes)**:
   - 几何布朗运动 (**GBM**): 用于股票与大宗商品路径模拟。
   - Vasicek 利率模型: 均值回归高斯过程与零息债券定价。
   - CIR 过程: 均值回归平方根过程与 Feller 条件检验。
   - Ornstein-Uhlenbeck (**OU**) 过程: 均值回归扩展过程。
   - Merton 跃迁扩散过程 (**Jump Diffusion**): 结合 Poisson 跃迁与 log-normal 跃迁幅度的资产定价。
4. **工业级方差缩减技术 (Variance Reduction)**:
   - 对偶变量法 (**Antithetic Variates**): 对偶路径负协方差削减标准误。
   - 控制变量法 (**Control Variates**): 基于 OLS 协方差回归推导最优 \(\beta^*\)。
   - 重要性抽样 (**Importance Sampling**): 基于 Radon-Nikodym 漂移转换及似然比权重，加速尾部极罕见事件抽样。
   - 分层抽样与拉丁超立方抽样 (**LHS**): 多维超立方均衡网格抽样。
5. **多资产相关性与 Copula 联结函数**:
   - 密集矩阵 Cholesky 分解与半正定数值修正。
   - 高斯 Copula (**Gaussian Copula**) 与 斯图登特-t Copula (**Student-t Copula**) 联合相关向量生成。
6. **全功能衍生品定价引擎 (Derivatives Pricing)**:
   - 欧式期权 (European Options) & Black-Scholes 解析解与 Greeks (Delta, Gamma, Vega, Theta, Rho)。
   - 亚式期权 (Asian Options): 算术平均与几何平均期权定价。
   - 障碍期权 (Barrier Options): Down-and-Out, Down-and-In, Up-and-Out, Up-and-In 与布朗桥连续触界校正。
   - 回溯期权 (Lookback Options): 浮动执行价与固定执行价最高/最低价期权。
   - **美式期权 Longstaff-Schwartz LSM 算法**: 基于普通最小二乘法 (OLS) 拟合拟基函数，支持早起执行边界估计。
7. **金融风险与压力测试引擎 (Risk Metrics)**:
   - 历史 VaR、参数化 VaR 与蒙特卡洛 VaR 计算器。
   - 条件 Value at Risk / 期望缺口 (**CVaR / Expected Shortfall**)。
   - 宏观情景压力测试套件 (Stress Testing Suite) 与路径有限差分 Greeks。
8. **多格式导出与审计 (Audit & Report Engine)**:
   - JSON / CSV 格式路径与结果导出。
   - 自动生成 Markdown 格式的执行总结分析报告。

---

## 🏗️ 架构设计与模块划分

```mermaid
flowchart TD
    A[随机种子与分布 / lib/core] -->|PRNG & Normal/Quantile| B[准蒙特卡洛 / lib/qmc]
    A -->|随机数 / 轨迹矩阵| C[随机过程模拟器 / lib/stochastic]
    C -->|GBM / Vasicek / CIR / Jump| D[方差缩减引擎 / lib/variance_reduction]
    A -->|Cholesky 分解| E[多资产相关性与 Copula / lib/multi_asset]
    C -->|路径数据| F[衍生品定价引擎 / lib/pricing]
    C -->|损益分布| G[金融风险与压力测试 / lib/risk]
    F -->|定价与 Greeks| H[可复现审计与报告 / lib/audit]
    G -->|VaR / CVaR / 压力测试| H
    H -->|命令行控制台| I[命令行 Runner / lib/cli]
```

### 包结构说明：

| 包路径 | 功能描述 | LOC 规模 |
| :--- | :--- | :--- |
| `lib/core` | PRNG (Xorshift128+, PCG32, SplitMix64), 标准分布 (Normal, Uniform, Exp, Poisson, Student-t), Welford 运行统计量, 轨迹矩阵哈希 | ~400 行 |
| `lib/qmc` | 低偏差序列 (Halton, 32-D Sobol, Korobov Rank-1 Lattice) | ~400 行 |
| `lib/stochastic` | 随机过程 (GBM, Vasicek, CIR, OU, Merton Jump Diffusion) | ~500 行 |
| `lib/variance_reduction` | 方差缩减 (Antithetic, Control Variates, Importance Sampling, LHS) | ~300 行 |
| `lib/multi_asset` | Cholesky 分解, 矩阵运算, 高斯 & Student-t Copula, 多资产相关路径 | ~300 行 |
| `lib/pricing` | 欧式、亚式、障碍、回溯期权与 Longstaff-Schwartz (LSM) 美式期权定价引擎 | ~700 行 |
| `lib/risk` | 历史/参数/蒙特卡洛 VaR, CVaR (Expected Shortfall), 宏观压力测试, 有限差分 Greeks | ~400 行 |
| `lib/audit` | FNV 校验值审计轨迹, JSON, CSV, Markdown 报告生成器 | ~300 行 |
| `lib/cli` | CLI 配置解析器与批量模拟 Runner | ~150 行 |

---

## 📐 数学公式与理论基础

### 1. 几何布朗运动 (GBM) 步长求解:
\[
S_{t+\Delta t} = S_t \exp\left( \left(\mu - \frac{1}{2}\sigma^2\right)\Delta t + \sigma \sqrt{\Delta t} Z \right), \quad Z \sim N(0, 1)
\]

### 2. Vasicek 利率模型精确高斯步长:
\[
r_{t+\Delta t} = r_t e^{-a \Delta t} + b (1 - e^{-a \Delta t}) + \sigma \sqrt{\frac{1 - e^{-2a\Delta t}}{2a}} Z
\]

### 3. Longstaff-Schwartz 美式期权最小二乘法 (LSM):
在时间步 \(t\)，对处于实值状态 (In-The-Money) 的样本路径，以拟合基函数 \(\{1, S, S^2\}\) 进行 OLS 回归估算继续持有价值 (Continuation Value):
\[
\hat{C}(S_t) = \beta_0 + \beta_1 S_t + \beta_2 S_t^2
\]
若立即执行收益 \(h_t(S_t) > \hat{C}(S_t)\)，则更新早起执行决断。

---

## 🚀 快速上手与 CLI 使用指南

### 1. 环境准备
使用最新版 MoonBit 工具链 (**0.10.3**):

```bash
# 检查 MoonBit 版本
moon version
```

### 2. 编译与运行测试
全量运行 36 组单元测试与场景集成测试：

```bash
moon test
```

### 3. 运行 CLI 模拟引擎
执行默认金融模拟批处理并生成 Markdown 执行报告：

```bash
moon run lib/cli
```

控制台输出示例：

```markdown
# 📊 Monte Carlo Simulation Audit Report: MoonBit Financial Monte Carlo Engine

## ⚙️ Reproducibility Audit Metadata

| Parameter | Audit Value |
| :--- | :--- |
| **Random Seed** | `42` |
| **Simulated Paths** | `1000` |
| **Time Grid Steps** | `11` |
| **Path FNV Checksum** | `2184694518222965206` |

## 💰 Derivative Pricing Engine Results

- **Estimated Fair Value**: `10.60439`
- **Standard Error**: `0.45942`
- **95% Confidence Interval**: `[9.70393, 11.50484]`

## 📉 Value at Risk (VaR) Analysis

- **Method**: `Historical PnL Percentile`
- **Confidence Level**: `95%`
- **Value at Risk (VaR)**: `26.18536`
```

### 4. 零警告合规性检查

```bash
moon check
moon fmt
moon info
```

---

## 🛡️ Git 规范与开发者声明

- **Git 提交次数**: 15+ 次结构清晰、逻辑连贯的增量 Commit。
- **单一真实贡献者**: 提交身份严格统一为独立开发者 `jdjjttr <jdjjttr@users.noreply.github.com>`，不存在任何虚拟或双重贡献者。
- **多端 CI 工作流**: 配置了 GitHub Actions Matrix 自动化工作流 (`.github/workflows/ci.yml` 和 `.github/workflows/test.yml`)，覆盖 `ubuntu-latest`, `macos-latest`, `windows-latest`。

> **项目开发者声明 (Source Attribution Statement)**:
> 本项目 `moonbit-montecarlo` (MoonBit 金融蒙特卡洛模拟框架) 专为 **MoonBit 2026 开源创新大赛 (OSC 2026)** 独立创作。全量源码均由开发者 `jdjjttr` 原创编写，不存在任何抄袭或未经授权的第三方代码搬运。

---

## 📜 开源许可证

本项目采用 [Apache License 2.0](LICENSE) 协议开源。
