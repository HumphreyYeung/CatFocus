# CatFocus 开发状态

更新时间：2026-08-02

这份文档用于下一次继续开发时快速恢复上下文。状态分为：已完成、待外部依赖、待开发和验收事项。

## 已完成

### Onboarding

- 完成故事型首屏、姓名、问题、目标、Suggestion、Pre-Train 和 Commitment 流程；Paywall 延后到 Home 点击 Start 时展示。
- 姓名为必填项；未填写时 Continue 置灰，并支持点击输入框唤起键盘。
- Name、Problem、Goal 共用表单容器，列表选项使用单层 border。
- 增加 Onboarding 返回逻辑和顶部进度条；前三个故事插画页不显示进度头部。
- 同一容器内的表单内容使用轻量横向切换动效。
- Pre-Train 使用单卡居中的 Pose carousel，支持左右滑动浏览，并且只有按住 Hold 后才开始 10 秒体验。
- Pre-Train 完成后进入 Commitment；完成 Commitment 后直接进入 Home。
- Paywall 从 Home 点击 Start 时触发；关闭后回到 Home 且不会解锁训练，购买成功后继续进入 Training。Restore 当前使用本地 fake entitlement。
- Paywall 顶部增加两行运动视频轮播：上排向左、下排向右，使用训练视频和 poster。
- 更新 Onboarding 形象资源：
  - Name / Problem / Goal：`luna-onboarding-guide`
  - Suggestion：`luna-onboarding-suggestion`
  - Work Plan / Commitment：`luna-onboarding-celebrate`、`luna-onboarding-pact`
- 新增图片资源统一压缩为最长边 720px，保留 PNG 和纯白背景。

### 核心训练流程

- Home、Training、Results、Break、Break Complete、Stats、My Cat、Settings 主流程已连通。
- Training 支持亮屏、沉浸模式、Focus Mode / Training Pose / BGM 入口定位到 Preset 对应模块。
- Preset 选择改为即时生效；Training Pose 与 My Cat 共用 catalog。
- 免费动作和 Premium 动作已区分，Premium 点击会弹出 Paywall。
- Focus Mode 支持自定义名称，自定义选项会排在最前面。
- Short Break / Long Break 已按完成次数区分，Focus 成功后由用户选择是否开始休息。
- Session Alerts、White Noise / BGM、Timer Duration 已接入主要训练流程。
- Luna 健康度与 Stats 数据挂钩，并有最低值保护和长期不训练衰减机制。

### 动画和资源

- 使用系统 AVFoundation 播放循环 MP4，不引入 Rive 或第三方播放器。
- Home / Break 使用 `luna-break.mp4`。
- Training 已接入 Run、Kettlebell、Lifting、Jump Rope、Sit Up、High Knees 视频。
- 所有训练视频统一使用 poster、首帧保护和加载失败 fallback。
- Results Success / Failure 使用独立静态资源，避免训练动作和结果反馈语义混用。

### 分享视频

- Results 可将当前训练 Pose 合成为真实视频并保存到 Photos。
- 输出为 `720x1280`、`9:16`、30 FPS、H.264、无音轨、约 6 秒。
- 视频主体保持内部 1:1，底部使用白色信息区承载文案。
- 已修复 AVAssetReader 合成时的视频倒置问题。
- 分享信息层级目前为：
  1. `FOCUSED / WORKED / STUDIED / READ WITH LUNA FOR N MIN`
  2. `USER NAME x LUNA`
  3. Pose、Focus 时长、Fit Points
  4. `CATFOCUS`
- Debug / Simulator 会将结果保留到 App Documents，并已导出预览到：
  `/Users/humphreyyeung/Downloads/CatFocus-share-preview.mp4`

## 待外部依赖

这些事项不是单纯改 SwiftUI 就能完整交付，等待产品信息或 Apple 配置：

- 接入真实 StoreKit 订阅和购买：商品 ID、价格、周订阅 / Lifetime 配置、Entitlement 状态。
- 将本地 fake entitlement/Restore 替换为真实 StoreKit 2 购买与恢复逻辑。
- 提供正式 Privacy Policy URL、Terms of Use URL、营销官网 URL。
- 确认 App Support 邮箱和付费相关客服文案。
- 真机签名、Provisioning Profile、Bundle Identifier 和 Apple Developer 能力配置。
- 真机验证 Photos 权限、视频保存、音频播放、亮屏和长时间训练性能。

## 待开发或需要优化

### P0：发布前必须处理

- StoreKit 真实购买、恢复购买、订阅状态持久化和 Paywall 解锁逻辑。
- Privacy / Terms 页面从占位入口变成可打开的正式内容。
- 真机跑通完整 Onboarding -> Paywall -> Training -> Results -> Photos 流程。
- 补齐正式 App 图标、商店截图、隐私说明和审核所需权限文案。

### P1：下一阶段产品体验

- 完善训练气泡消息 catalog：按 Home、Focus Mode、Pose、训练进度和结果状态映射不同内心戏文案。
- 为自定义 Focus Mode 定义分享视频中的显示文案和动词规则。
- 检查 Paywall 视频轮播在 Reduce Motion 下的行为，目前需要进一步确认是否改为静态 poster。
- 在 iPhone 16 Pro 以外补验较小屏幕，重点检查 Onboarding 表单、Paywall、Contract 和 Results 文案是否溢出。
- 检查训练视频在冷启动、首次进入和切换 Pose 时的首帧稳定性，优先在真机验收。
- 完善分享视频的品牌文案、用户与 Luna 的关系表达，以及不同 Focus Mode 的视觉层级。
- 评估是否需要在 Results 增加系统分享面板，而不仅是保存到 Photos。

### P2：数据和内容扩展

- 为本地 AppStorage 数据增加版本号和迁移策略。
- 记录每次训练当时的 Focus Mode、Pose 和 BGM，方便 Stats 与分享历史准确还原。
- 增加训练记录导出 / 清除确认，以及更完整的空状态和错误状态。
- 增加更多 Premium Pose、对应 MP4、poster 和消息文案。
- 后续再评估 UGC 视频模板、平台分享适配和更丰富的 9:16 版式。

## 当前验收入口

### Simulator

当前 Simulator：iPhone 16 Pro，设备 ID：
`8A88C66B-ECA3-4BE2-9B55-62774F0D1B4B`

重置并进入 Onboarding：

```bash
xcrun simctl uninstall 8A88C66B-ECA3-4BE2-9B55-62774F0D1B4B com.CatFocus.CatFocus
xcrun simctl install 8A88C66B-ECA3-4BE2-9B55-62774F0D1B4B /tmp/CatFocusSimDerivedData/Build/Products/Debug-iphonesimulator/CatFocus.app
xcrun simctl launch 8A88C66B-ECA3-4BE2-9B55-62774F0D1B4B com.CatFocus.CatFocus
```

### 分享视频回归

当前已有 UI Test：

```text
CatFocusUITests.testResultsShareVideoCreatesPreview
```

该测试会验证 Results 分享入口、视频生成、Debug 保留和保存成功状态。当前构建已通过。

## 推荐下次顺序

1. 先补齐 StoreKit 商品和正式 URL / 邮箱等外部信息。
2. 打真机包，验收 Onboarding、Pre-Train 视频、Paywall 轮播和训练长时间运行。
3. 再完善气泡消息与训练状态映射。
4. 最后继续打磨分享视频的品牌表达和 UGC 平台适配。
