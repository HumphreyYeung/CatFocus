# CatFocus Motion Specification

这份文档定义 CatFocus 当前阶段的动效执行规范，适用于猫咪动画资源、猫咪状态切换和状态转场 UI。

当前阶段采用“独立状态动画 + 通用云层转场”的方案：每个状态可以独立制作和替换，状态切换由统一转场组件遮蔽资源之间的差异。动效服务于状态理解、反馈和 Luna 的陪伴感，不以持续装饰为目的。

## 1. 当前方案

### 1.1 动效职责

- SwiftUI 原生动画负责 UI 反馈、按钮状态、数字变化和页面进入。
- 猫咪动画资源负责 Luna 在单个产品状态中的表现。
- 云层转场负责遮蔽两个独立猫咪资源之间的姿势、尺寸和播放节奏差异。
- 页面状态是唯一业务真相；动画播放不能反过来决定计时器、积分或训练结果。

### 1.2 当前不采用

- 不要求制作 idle 到 training 的专属角色过渡动画。
- 不引入 Rive 或复杂角色状态机。
- 不在页面中直接嵌入 Lottie/GIF 播放器。
- 不用动画表达唯一的业务信息；文字、数值和 VoiceOver 仍需表达状态。

## 2. 状态模型

猫咪状态使用产品语义命名，避免使用资源文件名直接作为业务状态：

```swift
enum CatMotionState {
    case idle
    case training
    case success
    case failure
}
```

状态映射建议：

| 产品状态 | 资源 | 播放方式 | 使用场景 |
| --- | --- | --- | --- |
| `idle` | `luna-idle` | 循环 | Focus 首页待机 |
| `training` | `luna-training` | 循环 | 训练进行中 |
| `success` | `luna-success` | 一次性或短循环 | 训练完成 |
| `failure` | `luna-failure` | 一次性或短循环 | 训练失败 |

未来增加状态时，先确定产品语义，再添加资源，不允许页面散落资源名和播放逻辑。

## 3. 猫咪资源规范

### 3.1 交付格式

优先级按资源特征决定：

1. MP4：适合已经制作完成、需要高帧率循环的角色动作；使用系统 `AVFoundation` 播放。
2. Lottie JSON 或 `.lottie`：适合需要在应用内控制循环、暂停、一次性播放和播放完成回调的矢量动画。
3. 静态 PNG：每个动画都必须提供，作为加载失败、Reduce Motion、低性能场景和卡片缩略图的 fallback。
4. GIF：仅在无法提供 MP4 或 Lottie 时使用，不作为新的首选格式。

当前训练动作使用“MP4 主资源 + PNG poster”组合。MP4 负责正常播放，PNG 在视频尚未准备好、加载失败或用户开启 Reduce Motion 时显示。GIF 只适合作为视觉资源，播放、暂停和切换时序控制较弱。

### 3.2 画布和对齐

每个状态必须使用一致的资源容器，不由动画文件决定页面布局：

- 保持相同画布宽高。
- 保持透明背景。
- 保持 Luna 的脚底 baseline 一致。
- 保持视觉中心和主体大小接近。
- 不要在不同状态中额外改变角色缩放比例。
- 不要将阴影或大面积背景写死在猫咪资源中，除非该状态明确需要。
- 同一组资源必须能在 `CFCatHero` 的同一 `CFCatAssetSize` 中替换。

建议每个状态同时提供（格式按实现选择）：

```text
luna-idle.json
luna-idle.png
luna-training.json
luna-training.png
luna-success.json
luna-success.png
luna-failure.json
luna-failure.png
```

视频资源示例：

```text
luna-pose-run.mp4
luna-pose-run-poster.png
```

视频交付前应统一预处理为适合 App 的规格：720x720、30 FPS、H.264、无音轨、`yuv420p` 和 fast-start。原始视频保留在素材目录，不覆盖原文件。

### 3.3 播放契约

每个动画资源交付时必须附带：

```text
state: idle | training | success | failure
loop: true | false
duration: 例如 2.4s
canvas: 例如 1024x1024
fallback: 对应 PNG 名称
```

循环动画需要保证首尾帧视觉接近。一次性动画需要明确播放结束后的显示状态，不允许播放结束后停留在空白帧。

## 4. 状态转场 UI

### 4.1 转场形式

使用一套可复用的云层转场覆盖猫咪区域：

```text
当前猫咪状态
  -> 云层进入并完全遮挡
  -> 替换资源和产品状态
  -> 云层离开
  -> 新猫咪状态开始播放
```

云层是“场景切换遮罩”，不是独立业务状态。它不应该修改计时器、积分或训练结果。

### 4.2 默认时序

目标总时长为 400-550ms：

| 阶段 | 建议时长 | 行为 |
| --- | ---: | --- |
| Cover | 180-260ms | 云层进入，覆盖猫咪 |
| Swap | 0-40ms | 替换猫咪资源和状态 |
| Reveal | 180-260ms | 云层离开，展示新状态 |

资源尚未加载完成时，必须保持遮罩，不能让新状态以空白或错误尺寸出现。加载超时应使用静态 PNG fallback，避免转场无限等待。

### 4.3 转场组件状态

转场实现建议拥有独立的视觉阶段：

```swift
enum CatTransitionPhase {
    case visible
    case covering
    case swapping
    case revealing
}
```

页面只提交目标状态，例如 `training`。转场组件负责：

- 播放云层进入。
- 在完全遮挡时替换猫咪资源。
- 播放云层离开。
- 让新的循环或一次性动画开始。
- 在页面离开或状态再次变化时取消未完成任务。

不要让页面自己维护多个 `DispatchQueue`、延迟回调或动画完成标记。

转场组件内部需要为每次切换生成唯一 token。新状态到来时，先取消旧任务并更新 token；旧任务即使在取消边界之后恢复，也不能继续写回 `displayedAsset`、speech 或无障碍状态。

### 4.4 云层视觉规则

- 云层必须在 Cover 阶段完全遮挡猫咪主体。
- 云层颜色和阴影使用 CatFocus 的黑白视觉体系。
- 云层运动方向保持一致，默认从侧边快速进入并离开。
- 云层不应覆盖计时器、导航栏或主要操作按钮，除非转场本身是整页场景变化。
- 云层进入和离开使用平滑减速，不使用夸张弹跳或长时间停留。
- 转场不能阻塞用户操作；用户仍可以取消训练或返回页面。

## 5. 业务状态与视觉状态同步

状态同步顺序必须是：

```text
业务状态确定目标状态
  -> 预加载目标资源
  -> 开始 Cover
  -> 完全遮挡后更新展示状态
  -> Reveal
  -> 播放目标动画
```

例如训练成功时：

1. Training 业务流程先产生 `.success` 结果。
2. 页面准备 success 动画和静态 fallback。
3. 云层覆盖 Luna。
4. 结果页同步更新标题、Fit Points 和语义色。
5. 云层离开，success 动画播放一次。

动画播放失败不能阻止结果页出现。

## 6. SwiftUI 实现边界

动画资源统一通过 `CFCatAsset`、`CFCatHero` 或后续的语义包装组件接入：

```swift
CFCatHero(
    asset: .animated(name: "luna-training"),
    size: .hero
)
```

MP4 资源使用同一语义入口：

```swift
CFCatHero(
    asset: .video(
        name: "luna-pose-run",
        poster: "luna-pose-run-poster"
    ),
    size: .hero
)
```

`CFVideoLoopView` 使用 `AVPlayerLooper` 无控件循环播放，页面离开时停止；播放器不可用时保持 poster，不允许视频加载过程改变 mascot 容器尺寸。

页面不允许直接使用：

```swift
Image("luna-training")
```

或在业务页面中直接创建 Lottie/GIF 播放器。这样可以确保静态图、Lottie、GIF 替换时不会改变外层布局。

UI 动效优先使用 `opacity`、`scaleEffect`、`offset` 和 transform 类属性。不要通过动画改变页面主要布局尺寸、容器高度或核心间距。

当前转场时长和曲线集中在 `CFMotionTokens.swift`。页面和组件不应继续散写相同语义的 duration 或 easing；调整转场手感时优先修改 token。

猫咪资源、speech bubble 和无障碍状态值属于同一个视觉状态快照。状态切换时，它们必须在云层完全覆盖后一起替换，避免出现旧猫咪配新气泡或 VoiceOver 提前读出新状态。

## 7. Reduce Motion 和系统设置

必须支持 `accessibilityReduceMotion`：

- 停止猫咪自动循环动画，显示对应静态 PNG。
- 云层转场改为短淡入淡出，或直接切换到目标状态。
- 不使用大幅缩放、持续摇摆、快速闪烁或强烈位移。
- 状态仍然必须通过文案、数值、颜色和 VoiceOver 传达。

系统设置优先于 App 内部的装饰性动效偏好。动画不能成为理解训练结果的唯一方式。

## 8. 资源验收清单

收到新动画资源后，先检查：

- [ ] 状态名称与产品状态一致。
- [ ] 有对应静态 PNG fallback。
- [ ] 画布尺寸与同组资源一致。
- [ ] 脚底、头部和视觉中心没有明显跳动。
- [ ] 循环动画首尾衔接自然。
- [ ] 一次性动画有明确的播放完成行为。
- [ ] MP4/Lottie/GIF 在固定容器中不会改变页面布局。
- [ ] 资源在白色背景和低亮度环境下都清晰。
- [ ] 资源不会出现明显闪烁、过快位移或不必要的镜头运动。
- [ ] 缺失或加载失败时能回退到静态图。

## 9. 开发验收清单

- [ ] idle -> training 使用统一云层转场。
- [ ] training -> success 使用统一云层转场。
- [ ] training -> failure 使用统一云层转场。
- [ ] 云层完全覆盖后才替换猫咪资源。
- [ ] 目标资源未加载完成时不会露出空白。
- [ ] 快速连续触发状态不会叠加多个转场任务。
- [ ] 页面离开后循环动画会暂停或释放。
- [ ] Reduce Motion 下不播放持续循环和大幅位移动效。
- [ ] UI Test 可以直接进入各个猫咪状态。
- [ ] Simulator 中检查 iPhone 16 Pro 和较小屏幕尺寸。

## 10. 当前资源优先级

第一批只需要：

```text
luna-idle
luna-training
luna-success
luna-failure
transition-cloud
```

每个猫咪状态提供一份动画和一份静态 fallback。`transition-cloud` 全 App 共用，不为每一组状态重复制作。

第一阶段先验证 idle -> training，再扩展 success、failure 和 onboarding。没有通过容器尺寸、转场时序、fallback 和 Reduce Motion 验收前，不批量制作更多猫咪动画。
