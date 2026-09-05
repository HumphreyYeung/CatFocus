# CatFocus Design System / Component System

这份文档定义 CatFocus 当前阶段的设计系统和 SwiftUI 组件规范。它不是通用 UI Kit，而是服务 CatFocus 这个产品的语义组件系统：让 Figma 设计、SwiftUI 开发、图片/GIF/动画资源替换、状态文案替换都尽量不产生散乱 UI diff。

## 1. 当前阶段锁定

### 产品语义

- 猫咪默认名：`Luna`。
- 核心数值：`Fitness Score` 和 `Fit Points`。
- `Fitness Score` 用百分比展示，是健康/状态相关 UI 的主信息。
- `Health Status` 由 `Fitness Score` 派生，只作为弱标签展示，例如 `LOW`、`HEALTHY`、`STRONG`、`PEAK`。
- `Fit Points` 使用明确加减值，例如 `+100 Fit Points`、`-50 Fit Points`。
- Training 失败会扣分。
- Paywall 右上角 close / cancel 可以关闭。
- Share Card 对外品牌暂用 `CatFocus`，但必须保持可配置。

### 当前已实现基线

- Focus / Training / Success 已接入真实 Luna PNG 资源。
- Focus / Training 的短消息使用 `CFCatScene + CFSpeechBubbleConfig` 挂在猫咪画面上。
- Training 的取消控件必须是真正的左滑交互，不能点击即取消。
- Focus、Stats、My Cat 顶部与底部使用统一 tab screen layout 规则。
- 主按钮、底部 tab icon、preset pill 已按“画面主导”方向弱化。

### 仍需后续决策

- 用户是否可以给 Luna 改名。
- `Fitness Score` 的具体百分比公式、衰减机制和失败扣分权重。
- 未付费用户是否仍然进入 Contract。
- Share Card 最终品牌名是否继续使用 `CatFocus`。
- 多条 cat message 的展示时长、隐藏时长和轮播策略。

## 2. 设计原则

### 画面主导

CatFocus 的主体验不是传统番茄钟，而是和 Luna 建立 Practice Partner 关系。页面应优先让 Luna 的画面、姿态和情绪成为第一视觉层级。

规则：

- 猫咪插画是主视觉，功能组件不能压过画面。
- 按钮、pill、tab、preset 入口都应是辅助层级。
- Training 计时是训练中的核心状态，可以强，但不应比画面更重。
- 页面不要靠大量卡片或装饰建立“丰富感”，优先靠插画状态和轻量信息层级。

### Product Surface 与 Narrative Surface 分层

`Product Surface` 适用：

- Focus
- Training
- Training Success / Fail
- Stats
- My Cat
- Focus Preset
- Share Card

特征：

- 白色背景。
- 黑白极简。
- 大留白。
- 组件克制，数据清楚。
- 猫咪插画承担主要情绪表达。

`Narrative Surface` 适用：

- Onboarding Greeting
- User Name
- Problems
- Goal
- Suggestion
- Trial
- Trial Finish
- Plan Lead
- Paywall
- Contract

特征：

- 故事感更强。
- 对话气泡是主要信息载体。
- 可以有黑白电影感、暗角、聚光、仪式化交互。
- 不应污染主 App 的轻量 Product Surface。

## 3. Tokens

页面不直接散写颜色、字体、圆角、阴影和主要 padding。稳定的视觉值必须进入 token 或语义组件。

### Color

当前语义 token：

```swift
enum CFColor {
    static let backgroundPrimary: Color
    static let backgroundDimmed: Color
    static let surfacePrimary: Color
    static let surfaceSoft: Color
    static let surfaceSelected: Color
    static let surfaceElevated: Color

    static let textPrimary: Color
    static let textSecondary: Color
    static let textTertiary: Color
    static let textInverse: Color

    static let borderPrimary: Color
    static let borderSubtle: Color
    static let divider: Color

    static let accentHealth: Color
    static let accentSuccess: Color
    static let accentDanger: Color
    static let accentReward: Color
}
```

规则：

- 黑白灰是主体。
- 红色只用于语义提示，例如 heart、danger、扣分。
- 绿色只用于成功、增长、正向反馈。
- 不使用大面积彩色渐变。
- 失败状态可以红色提示，但文案和画面避免惩罚感过强。

### Typography

当前语义 token：

```swift
enum CFFont {
    static let screenTitle: Font
    static let heroNumber: Font
    static let sectionTitle: Font
    static let cardTitle: Font
    static let body: Font
    static let bodySmall: Font
    static let caption: Font
    static let button: Font
    static let labelCaps: Font
    static let dialogue: Font
}
```

规则：

- `heroNumber` 用于 Training 倒计时，必须使用等宽数字或固定宽度行为，避免跳动。
- `button` 用于主黑色 CTA，目前应保持 `bold` 左右，不恢复到过重的 `black`。
- `labelCaps` 用于小标签和辅助操作，不能抢主视觉。
- Product Surface 的短消息 bubble 使用更轻的 `semibold` 字重。
- Narrative Surface 的对话字体可以更有故事感，但必须保证可读性。

### Spacing And Layout

当前基础 token：

```swift
enum CFSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let section: CGFloat = 40
    static let screenHorizontal: CGFloat = 24
    static let bottomActionInset: CGFloat = 32
}
```

当前页面级 token：

```swift
enum CFTabScreenLayout {
    static let horizontalPadding: CGFloat = CFSpacing.xl
    static let headerTopPadding: CGFloat = CFSpacing.lg
    static let headerBottomPadding: CGFloat = CFSpacing.lg
    static let scrollBottomPadding: CGFloat = 96
}

enum CFButtonLayout {
    static let primaryHorizontalInset: CGFloat = 72
}
```

规则：

- Focus、Stats、My Cat 顶部区域使用 `CFTabScreenLayout` 对齐。
- 主黑色 CTA 默认不横向铺满页面，使用 `CFButtonLayout.primaryHorizontalInset` 控宽。
- 页面不要散写主要 horizontal padding、section spacing、button width。
- 局部 offset 只允许作为组件配置出现，例如 `CFSpeechBubbleConfig.offset`，不要在页面里随手修图。

### Radius And Shadow

当前 radius：

```swift
enum CFRadius {
    static let button: CGFloat = 14
    static let tile: CGFloat = 12
    static let card: CGFloat = 20
    static let largeCard: CGFloat = 26
    static let sheet: CGFloat = 36
    static let pill: CGFloat = 999
}
```

当前 shadow：

```swift
enum CFShadow {
    static let cta: CFShadowStyle
    static let floating: CFShadowStyle
    static let cardSoft: CFShadowStyle
}
```

规则：

- Product Surface 的圆角保持克制，不继续放大。
- 普通 card 默认使用 border，不使用重阴影。
- CTA 可使用轻阴影，但不要像浮动广告卡。
- Speech bubble 可使用轻阴影来和插画背景分离。

## 4. 组件规范

组件使用 `CF` 前缀，优先表达产品语义。避免 `CustomButton`、`RoundedCard`、`OptionView` 这类无语义名称。

### `CFPrimaryButton`

用途：

- `START`
- `BACK TO HOME`
- `CONTINUE`
- `ACCEPT COMMITMENT`

规则：

- 高度、圆角、阴影、文字样式由组件控制。
- 页面只控制外部布局，例如是否使用 `CFButtonLayout.primaryHorizontalInset`。
- Disabled 和 loading 不改变布局尺寸。
- 视觉上是主行动，但不能压过猫咪画面。

### `CFStatusPill` / `CFFitnessStatusPill`

用途：

- `FOCUS`
- `FIT POINTS +100`
- `FIT POINTS -50`
- Fitness 顶部状态
- Paywall badge

规则：

- `CFStatusPill` 用于一般状态。
- `CFFitnessStatusPill` 用于 Fitness Score + Health Status。
- Fitness pill 中百分比是主信息，Health Status 是弱信息。
- Health Status 使用短词，不使用 `NEEDS TRAINING` 这类长标签。
- tone 决定颜色，页面不直接传颜色。

### `CFIconCircleButton`

用途：

- Settings
- White Noise
- Share
- Close / secondary tool action

规则：

- 图标尺寸和圆形背景由组件控制。
- Product Surface 中图标按钮要轻，不要比页面内容更抢。
- 如果是破坏性操作，不使用普通 icon circle 表达。

### `CFBottomTabBar`

用途：

- Focus
- Stats
- My Cat

规则：

- 底部 tab icon 尽量轻，当前应避免 `.black` 字重和过大 size。
- active state 清楚即可，不需要大面积黑块。
- 点击区域必须足够，但视觉宽度不需要铺满。
- 修改 tab 图标优先在 `CFAppTab` / `CFIcon` 层处理，不在页面散写。

### `CFCatHero` / `CFCatScene`

`CFCatHero` 负责单个猫咪资源的展示：

```swift
CFCatHero(
    asset: CFCatAsset,
    size: CFCatAssetSize,
    alignment: CFCatAlignment = .center
)
```

`CFCatScene` 负责猫咪资源和短消息的组合：

```swift
CFCatScene(
    asset: CFCatAsset,
    size: CFCatAssetSize,
    alignment: CFCatAlignment = .center,
    speech: CFSpeechBubbleConfig? = nil
)
```

规则：

- 页面不直接使用 `Image("...")` 展示猫咪主资源。
- 资源使用 `.scaledToFit()`，避免裁切主体。
- 找不到资源时必须有 fallback。
- Focus / Training 的短消息使用 `CFCatScene`，不要在页面里散写 overlay。
- 1024x1024 方图自带留白，不要用负 padding 修图；优先用 asset size、alignment 和 speech offset。

### `CFSpeechBubbleConfig`

用途：

- Product Surface 中挂在猫图上的短消息。

规则：

- Bubble 是临时叙事提示层，不是永久信息栏。
- Bubble 贴近猫咪图片留白或边缘，但不能遮住脸、身体、关键动作。
- 背景使用黑色半透明。
- 文案字重保持轻，不能比猫图更抢。
- 多条消息应由 message queue 控制当前显示内容，`CFCatScene` 只负责展示当前 message。
- 未来可扩展为 `CFCatMessageQueue(messages:displayDuration:hiddenDuration:)`，不要在页面里散写 timer。

### `CFSlideToCancel`

用途：

- Training 中放弃当前训练。
- 未来可用于需要防误触的负向操作。

规则：

- 必须通过 `DragGesture` 触发。
- 点击文字或 handle 不允许取消。
- 默认方向为从右向左滑动。
- 未达到阈值时 handle 弹回。
- 达到阈值后触发失败/取消状态。
- 必须有 UI test 覆盖“点击不触发、滑动触发”。

### `CFSelectableTile`

用途：

- Focus Mode
- White Noise
- Workout Pose
- Onboarding choices

规则：

- selected、normal、add、locked、disabled 通过 state 表达。
- 新增 mode / sound / pose 时只增加数据，不新写 UI。
- Tile 内部尺寸、圆角、边框和 icon 样式由组件控制。

### `CFTrainingResultView`

用途：

- Training Success
- Training Fail

规则：

- 成功和失败由 `TrainingResultState` 驱动，不写两套页面。
- 状态控制插画、标题、文案、Fit Points、语义色和 action。
- 失败页文案不应过度羞辱用户。
- 主按钮使用 `CFPrimaryButton`，次操作使用轻量 text button。

### 待抽取业务组件

以下组件还未全部稳定实现，进入对应页面开发时再抽取，不提前新增：

- `CFMetricBlock`
- `CFSessionRow`
- `CFPoseCard`
- `CFSettingSliderRow`
- `CFSharePreviewCard`
- `CFShareActionBar`
- `CFPaywallPlanCard`
- `CFContractCard`
- `CFOnboardingQuestionScreen`
- `CFDialogueBubble`

## 5. 资源规范

当前 SwiftUI 资源模型：

```swift
enum CFCatAsset {
    case staticImage(name: String)
    case animated(name: String)
}
```

未来扩展目标：

```swift
enum CFCatAsset {
    case staticImage(name: String)
    case gif(name: String)
    case lottie(name: String)
    case rive(name: String, stateMachine: String?)
}
```

当前尺寸 variant：

```swift
enum CFCatAssetSize {
    case icon
    case small
    case medium
    case hero
    case onboardingHero
    case shareCard
}
```

用途：

| Size | 用途 |
| --- | --- |
| `icon` | 小头像、pose 小图 |
| `small` | onboarding 小猫旁白 |
| `medium` | result 页猫 |
| `hero` | Focus / Training 主插画 |
| `onboardingHero` | 剧情页大插画 |
| `shareCard` | 分享卡专用尺寸 |

资源命名：

- `luna-focus`
- `luna-training`
- `luna-success`
- `luna-fail`
- `luna-pilates`
- `luna-running`
- `luna-stretch`
- `luna-lifting`

规则：

- 新增猫图必须放入 `Assets.xcassets/*.imageset`。
- 页面只能选择 asset name 和 size variant。
- 不直接传任意 frame。
- 静态图、GIF、Lottie、Rive 尺寸不一致时，由 wrapper 适配。
- 动画加载失败时 fallback 到静态图。

## 6. Layout 规范

### Product Screen

规则：

- 白色背景。
- 顶部 header 使用统一 top padding。
- 内容区保留大留白，让 Luna 画面成为焦点。
- 底部 tab 固定在底部，视觉轻，不遮内容。
- Scroll 页面底部必须预留 tab bar 空间。

### Bottom Sheet / Preset

规则：

- 使用 `CFBottomSheetScaffold`。
- 顶部包含 grabber、标题和右上角 confirm。
- Confirm 对整张 preset sheet 生效，不属于某一个 section。
- Section 使用明确标题，例如 `FOCUS MODE`、`TIMER CONFIGURATION`、`WHITE NOISE`。
- 底部按钮如果影响可见内容，应改为右上角 confirm 或 scroll footer，不遮住第三个模块。

### Grid

规则：

- Workout Pose 使用 2 columns。
- Focus Mode 使用 3 columns。
- White Noise 使用 3 columns。
- item 宽度由 grid 决定，不在 item 内写死。

## 7. Figma 到 SwiftUI 对齐

| Figma Component | SwiftUI Component |
| --- | --- |
| Primary Button | `CFPrimaryButton` |
| Status Pill | `CFStatusPill` |
| Fitness Status Pill | `CFFitnessStatusPill` |
| Icon Circle Button | `CFIconCircleButton` |
| Bottom Tab Bar | `CFBottomTabBar` |
| Cat Hero | `CFCatHero` |
| Cat Scene | `CFCatScene` |
| Slide To Cancel | `CFSlideToCancel` |
| Training Result | `CFTrainingResultView` |
| Selectable Tile | `CFSelectableTile` |
| Bottom Sheet | `CFBottomSheetScaffold` |

规则：

- Figma 使用 component instance，不复制 detached component。
- Component properties 对应 SwiftUI enum / props。
- Selected、normal、disabled、locked、loading 必须在 Figma variants 中体现。
- 资源容器在 Figma 中也要固定尺寸，方便替换插画或动画预览图。
- 页面 frame 不存放散装样式，样式上移到 component 或 token。

## 8. 减少 UI Diff 的规则

- 页面只传数据、状态、asset、action。
- 页面不定义主要视觉值。
- 同类页面使用模板组件。
- 插画资源通过 `CFCatAsset` 替换，不改 layout。
- 组件 variant 使用 enum，不使用多个 bool 组合。
- Magic number 如果复用两次以上，必须提升为 token 或组件配置。
- 对齐问题优先修 component / token，不逐页调。
- 动画资源替换必须经过 asset wrapper，不直接在页面嵌播放器。
- 高风险交互必须有 UI test，例如 slide-to-cancel。

## 9. 验收标准

一个页面符合 CatFocus Component System，需要满足：

- 页面没有散写主要 font、corner radius、shadow、padding。
- 猫咪插画通过 `CFCatHero`、`CFCatScene` 或 asset wrapper 插入。
- Product Surface 短消息通过 `CFCatScene` 的 speech 配置，不散写 overlay。
- Success / Fail 等状态由 enum 驱动。
- 替换猫图、文案、积分、状态时，不需要改布局代码。
- 新增 Focus Mode / White Noise / Pose 只需要增加数据。
- Training cancel 是滑动确认，不是点击按钮。
- 主按钮、tab icon、pill、倒计时不压过猫咪画面。
- 动画资源加载失败时有静态 fallback。
- 关键交互有 UI test 或至少有明确的手动验证截图。
