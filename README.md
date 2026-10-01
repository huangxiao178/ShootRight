# 《拍对了》— AI 拍照构图助手（iOS）

打开相机，AI 告诉你往哪站、怎么拍，点一下快门就出片。

## 功能一览（V1）

- **实时场景识别**：拍美食 / 拍对象 / 单人照 / 合影 / 风景，全部在设备本地完成
- **构图引导**：三分网格 + 水平仪 + 主体框 + 方向箭头 + 一句话提示（≤ 12 字）
- **对齐反馈**：到达建议位置后变绿 + 震动提示"可以拍了"
- **场景滤镜推荐**：每场景精选滤镜，底部缩略图实时预览，一键应用
- **成片页**：滤镜强度滑杆、长按看原图、"为什么这样拍好看"讲解、保存 / 分享
- **拍法卡**：每场景的拍法口诀与常见错误
- **隐私**：不联网、不上传照片，AI 全本地处理

## 环境要求

| 项 | 要求 |
|---|---|
| 电脑 | Mac（需要 Xcode，Windows 无法编译 iOS） |
| Xcode | 16.0 及以上 |
| 系统 | iOS 16.0 及以上 |
| 机型 | iPhone 12 及以上（A14 芯片，保证 AI 实时性） |

## 快速开始

### 方式 A：有 Mac
1. 把 `ShootRight` 文件夹复制到 Mac 上（可用 AirDrop / U 盘 / 网盘）；
2. 双击 `ShootRight.xcodeproj` 打开工程；
3. 选择你的 iPhone 作为运行目标（首次需在 设置 → 开发者选项 信任开发者）；
4. 在 工程 → Signing & Capabilities 里勾选 "Automatically manage signing"，选择你的 Apple ID 团队；
5. 点击 Run（⌘R）。

### 方式 B：没有 Mac（免费，GitHub 云编译 + Windows 签名）
1. 把本文件夹推到 GitHub（Public 仓库，Actions 免费）；
2. 仓库 **Actions** 页 → **Build iOS App** → **Run workflow**，约 10 分钟后下载 `ShootRight-unsigned.ipa`；
3. Windows 安装 **Sideloadly**（https://sideloadly.io，免费）+ iTunes/iCloud 驱动；
4. Sideloadly 里选 .ipa + 填免费 Apple ID → Start → iPhone 上信任开发者 → 使用；
5. 免费签名 7 天有效，到期用 Sideloadly 重装即可。

> 详细图文步骤见项目外的《安装说明-GitHub免费路径.md》。

> 没有付费开发者账号也能用免费 Apple ID 真机运行（有效期 7 天，到期重新签名即可）。
> 上架 App Store 需要开发者账号（$99/年）。

## 工程结构

```
ShootRight/
├── ShootRightApp.swift          # App 入口
├── Models/                      # 场景 / 滤镜 / 提示 / 成片模型
├── Services/                    # 相机 / 识别 / 姿态 / 构图引擎 / 渲染
├── ViewModels/CameraUIState.swift
├── Views/                       # 相机页 / 成片页 / 场景选择 / 拍法卡 / 设置
└── Assets.xcassets
```

核心数据流：取景 → 每 8 帧抽 1 帧做 AI 分析（Vision 人/脸/显著性 + 场景分类 + 陀螺仪姿态）→ 规则引擎出提示 → 叠加层显示 → 按快门出图应用滤镜。

## 已知限制（V1）

- 滤镜实时预览为**底部缩略图条**（全屏实时滤镜预览留待 V2，用 Metal + CIContext 改造）；
- 场景识别用 Vision 内置模型 + 关键词映射，边界场景可能不准；"拍对象"与"单人照"视觉无法自动区分，建议手动切换场景；
- 构图引导为规则引擎（确定性、可解释），非生成式 AI；
- 仅竖屏、简体中文、iPhone。

## 常见问题

**问：编译报 Signing 错误？**
在 工程 → Signing & Capabilities 选择你的团队；免费账号需先在 Xcode 菜单 Settings → Accounts 登录 Apple ID。

**问：真机运行提示"未受信任的开发者"？**
iPhone 上 设置 → 通用 → VPN 与设备管理 → 信任该开发者。

**问：想改 App 名称？**
改 工程 → Build Settings → 搜索 `CFBundleDisplayName`（当前为"拍对了"），以及 Xcode 侧边栏里双击项目名重命名。

## 路线图

- V2：全屏实时滤镜（Metal 管线）、自训练场景分类模型（Create ML）、"拍对象模式"开关、构图评分
- V3：更多场景（宠物 / 夜景 / 商品）、横屏与 iPad、多语言
