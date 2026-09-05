# CatFocus Current Design Optimization Recommendations

## 1. 总体判断

CatFocus 当前设计最强的资产，是黑白极简、猫咪训练叙事和 Practice Partner 关系。它不是普通专注计时器，而是把用户的专注行为转译成 Luna / Kuro 的训练、健康、成长和情绪反馈。

后续优化的核心不是让界面变得更丰富，而是让现有叙事更稳定、组件更一致、状态更清楚，并降低设计和开发之间的 UI diff。

优化原则：

- 保留黑白极简风格，不引入大面积彩色装饰。
- 让猫咪角色成为主要情绪载体，UI 本身保持克制。
- 每个页面都服务同一个关系模型：用户专注，猫咪训练；用户放弃，猫咪受影响。
- 优先解决命名、组件一致性、状态表达和交互反馈问题。
- 不为了系统化牺牲当前手绘感和故事感。

一句话方向：

> CatFocus 的设计系统不只是 UI 规范，而是一套 Practice Partner 关系的表达系统。

## 2. 优先级概览

### P0：必须优先处理

- 统一猫咪伙伴命名：当前 onboarding 使用 Luna，主应用部分出现 Kuro。需要确定这是同一只猫、用户可命名猫，还是默认名不同。
- 统一核心数值体系：`Health`、`Fitness`、`Fit Points`、`Training Energy` 的关系需要明确。
- 统一按钮、卡片、胶囊、描边选择项的尺寸和状态。
- 明确 onboarding -> paywall -> contract -> focus 首页之间的叙事连续性。
- 明确成功/失败结果页对用户的情绪反馈边界，避免失败页过度惩罚。

### P1：建议近期优化

- 增强 Focus 首页的状态解释，让用户更快理解为什么现在要训练。
- 优化 Preset 页的信息密度和分组，让配置项更像训练计划，而不是普通设置。
- 让 Stats 页不仅展示数据，还能回扣猫咪成长。
- My Cat 页增加成长目标、解锁动机和当前状态解释。
- Share Card 强化品牌一致性和可分享动机。

### P2：后续增强

- 增加轻量动效规范，例如猫咪状态变化、hold button、训练完成、契约签署。
- 建立插画资源位规范，方便替换静态图、GIF、Lottie 或 Rive。
- 为 onboarding 增加进度感，但不要破坏沉浸故事。
- 为 paywall 增加更明确的价值映射。

## 3. 产品叙事优化

### 3.1 统一 Practice Partner 关系

当前 onboarding 的核心很清楚：用户发现猫咪，猫咪承认自己需要练习，用户和猫咪成为互相监督的伙伴。

建议把产品叙事固定为：

> You focus. Luna trains. You both get stronger.

具体建议：

- 如果默认猫名是 `Luna`，主应用也统一为 `Luna`。
- 如果 `Kuro` 是用户可设置的猫名，onboarding 或 My Cat 中需要解释命名逻辑。
- 结果页、分享卡、Stats、My Cat 都应持续使用同一只猫的状态，而不是像不同功能模块。
- 文案中避免让猫咪只像奖励物，应该始终保持伙伴关系。

### 3.2 明确行为转化机制

用户需要理解：

- 专注时间会转化为训练收益。
- 完成 session 会增加 `Fit Points` / `Fitness` / `Health`。
- 放弃 session 会减少 `Fit Points` 或影响状态。
- 猫咪姿势、健康、训练状态是用户行为的反馈。

建议统一语义：

| 概念 | 建议含义 |
| --- | --- |
| `Focus Time` | 用户投入的专注时间 |
| `Fit Points` | 训练奖励积分 |
| `Fitness` | 猫咪长期训练水平 |
| `Health` | 猫咪当前状态或活力 |
| `Training Energy` | 专注时间转化出的训练能量 |
| `Workout Pose` | 猫咪训练动作、收藏或成长表现 |

## 4. Onboarding 优化建议

### 4.1 Greeting 三连页

当前优点：

- 黑暗房间、手电筒、猫咪被发现的场景很有记忆点。
- 很好地建立了“发现一只猫”的故事开场。
- 与主应用白底极简形成情绪反差。

建议优化：

- 保持前三页电影感，不加过多 UI 控件。
- `TAP TO CONTINUE` 的位置、透明条高度和文字间距固定成组件。
- 对话气泡的位置和宽度需要统一规则：短句居中，长句使用固定最大宽度。
- 第三页文案信息量偏大，可拆成两句或在下一页承接，降低阅读压力。

优先级：P1  
原因：这是产品第一印象，情绪很好，但需要保证阅读节奏稳定。

### 4.2 用户姓名页

当前优点：

- 小猫、对话气泡、输入框的结构清楚。
- 从故事自然进入用户信息收集。

建议优化：

- 输入框和选项按钮视觉语言统一，但输入框保留更强焦点态。
- Continue 按钮在未输入时需要 disabled 状态。
- 用户输入后，后续页面直接称呼用户名字。
- 如果用户跳过输入，需要有默认称呼，避免后续文案断裂。

优先级：P0  
原因：这是用户从旁观者变成参与者的关键节点。

### 4.3 Problems / Goal 页

当前优点：

- 选项大、清晰，适合移动端点击。
- 问题和目标都通过猫咪对话提出，符合叙事。

建议优化：

- 明确单选或多选。目前视觉上像单选，但没有展示 selected state。
- 选中态建议使用黑底白字或黑色描边加轻微填充，和 Preset selected state 保持一致。
- Continue 按钮应在选择后变为 active。
- `ADHD` 属于敏感/临床相关表达，建议改为 `I struggle with attention`，避免医疗诊断暗示。

优先级：P0  
原因：这两页影响个性化计划和后续文案，也涉及敏感表达。

### 4.4 Suggestion / Trial / Trial Finish

当前优点：

- “你专注，我训练”的机制在这里被讲清楚。
- 10 秒 hold trial 是很好的 proof moment，比直接讲价值更有效。
- Trial finish 的即时正反馈有说服力。

建议优化：

- Trial 页的 hold button 需要明确按住进度，例如圆形进度环、倒计时变化或轻微压缩动效。
- `00:00` 可改成 `00:10` 起始倒计时，更直观。
- Trial finish 建议展示一个微奖励，例如 `Fit Points +10`，提前建立奖励机制。
- `Imagine 25 minutes...` 很好，但可以更具体地连接到正式 session。

优先级：P1  
原因：这是从故事进入产品机制的桥。

## 5. Paywall 优化建议

当前优点：

- Paywall 没有完全脱离故事，仍然使用猫咪训练计划语境。
- 价格卡、勾选权益、CTA 都比较清楚。
- 黑白风格和主产品一致。

建议优化：

- 标题 `UNLOCK THE FULL WORKOUT PLAN` 是正确方向，继续避免泛泛的 `Premium`。
- 权益应更具体地映射产品价值，例如：
  - `Unlock all workout poses`
  - `Earn advanced training rewards`
  - `Keep Luna's full training plan active`
- `More Fitness Points` 可能有 pay-to-win 感，建议改成更偏体验或成长系统的表达。
- Weekly 和 Lifetime 的 selected state 清楚，但价格层级需要更强对比。
- 关闭按钮在 onboarding paywall 中需要决定是否允许跳过；如果允许，后续 contract 是否仍出现需要明确。
- `3-DAY FREE TRAIL` 应修正为 `3-DAY FREE TRIAL`。

优先级：P0  
原因：Paywall 是商业转化节点，同时不能破坏用户和猫咪之间的信任关系。

## 6. Contract 页面优化建议

当前优点：

- 契约页非常符合产品气质，有仪式感。
- 用户签名、猫爪印、打字机/键盘视觉强化了承诺感。
- Paywall 后接 contract 是很好的情绪收束。

建议优化：

- Contract 的日期、用户签名、猫名必须使用真实数据。
- 契约正文建议更自然，避免过度严肃：
  - `Every minute I spend in deep work becomes Luna's training energy.`
- `Absolute focus during sessions` 可以改得不那么苛刻，避免用户压力过大。
- `ACCEPT COMMITMENT` 可加入轻微签署动效：猫爪章盖下、纸张轻震、按钮完成态。
- 如果用户没有购买，也要有免费版契约文案，避免流程断裂。

优先级：P1  
原因：这是 onboarding 的情绪高点，应该把用户转化为长期关系。

## 7. Focus 首页优化建议

当前优点：

- 首页很干净，猫咪状态、时长、Start 都非常聚焦。
- `Health`、`Time to Train?`、猫咪睡觉状态形成了明确动机。
- 底部 Tab 简洁。

建议优化：

- `TIME TO TRAIN?` 可根据猫状态变化，例如饥饿、疲惫、兴奋、等待训练。
- Health pill 建议点击可解释：Health 是什么，如何提升。
- `25:00` preset 入口可以更明显地表达可配置性。
- Start 按钮状态应支持 disabled、pressed、loading。
- 设置按钮和 preset 入口的关系需要明确：设置是全局设置，时间胶囊是本次训练配置。

优先级：P0  
原因：首页是最高频页面，组件规范收益最大。

## 8. Training 页面优化建议

当前优点：

- 进行中页面信息很少，符合专注场景。
- 大倒计时和猫咪训练插画形成强反馈。
- `slide to cancel` 增加放弃成本，很适合产品理念。

建议优化：

- `FOCUS` pill 和音乐按钮需要保持与 Focus 首页的 icon button 规范一致。
- 倒计时数字需要定义动态宽度，避免时间变化时视觉跳动。
- `KEEP PUSHING, HUMPHREY` 可根据训练进度动态变化。
- Slide to cancel 需要明确滑动完成态和取消确认策略。
- 若用户误触取消，建议提供二次确认或短暂 undo。

优先级：P1  
原因：训练中应尽量减少误操作和视觉跳动。

## 9. Training Success / Fail 优化建议

当前优点：

- 成功和失败页结构高度一致，很适合组件化。
- 成功页情绪正向，失败页也有清晰反馈。
- Fit Points 胶囊是很好的状态组件。

建议优化：

- Success / Fail 应抽成同一个 `TrainingResultView`。
- 失败页文案建议避免过度羞辱用户。当前 `lazy habits are returning` 情绪略重。
- 可改为更像伙伴提醒：
  - `Kuro got a little discouraged, but you can still restart together.`
- 失败也可以给微小恢复路径，例如 `Try 5 min`，减少流失。
- Restart 的视觉权重可以略提高，当前过弱。

优先级：P0  
原因：失败体验直接影响留存和用户情绪。

## 10. Stats 页面优化建议

当前优点：

- 信息架构清楚：summary、weekly activity、recent sessions。
- 视觉上比 Focus 更功能型，但仍保持黑白简洁。
- Recent Sessions 已经体现正负结果。

建议优化：

- `Fitness 85%` 和 My Cat 的 `Fitness 92%` 需要统一数据来源。
- Weekly Activity 图表建议显示目标线或 streak 信息。
- Recent Sessions 中 abandoned session 的图标和负分颜色可以更统一。
- 分享按钮点击后的 Share Card 很好，但 Stats 页可以增加分享动机，例如训练成果或本周总结。
- Metric card 的 label、value、trend、status pill 应统一组件规范。

优先级：P1  
原因：Stats 是用户理解成长的地方，不能只是数据展示。

## 11. My Cat 页面优化建议

当前优点：

- My Cat 很好地承载了养成系统。
- 猫名、Health、Fitness、Pose grid 都有发展空间。
- Selected pose 的黑色描边清楚。

建议优化：

- Health 和 Fitness 同时出现时，需要解释差异。
- 角色展示区可以根据当前 pose / mood / fitness 动态切换。
- Pose grid 建议明确 locked、selected、available 三种状态。
- 未解锁姿势可以展示解锁条件，例如 `Complete 3 focus sessions`。
- 大卡片内的留白和插画位置需要固定资源容器，方便后续替换 GIF / 动画。

优先级：P0  
原因：这是产品长期养成和付费价值的核心页面。

## 12. Share Card 优化建议

当前优点：

- 分享卡片有强品牌感，适合传播。
- 插画、quote、三列数据、品牌 footer 结构完整。
- Action bar 清晰。

建议优化：

- Quote 可以根据猫咪状态和训练类型动态生成。
- 三列指标应从统一 Metric 数据模型生成。
- `PAW-MODORO` 命名需要确认是否最终品牌名；如果产品叫 CatFocus，需要统一。
- App Store badge 尺寸、品牌 footer、logo 区需要固定规范。
- 分享渠道按钮需要考虑不可用状态和系统 share sheet fallback。

优先级：P1  
原因：分享卡可能是外部用户第一次看到产品的入口。

## 13. Focus Preset 优化建议

当前优点：

- Focus Mode、Timer Configuration、White Noise 分组清楚。
- Tile grid 适合快速选择。
- Slider panel 视觉统一。

建议优化：

- Add、selected、normal 三种 tile 状态需要统一组件定义。
- Timer slider 的刻度含义需要更清楚，当前点位较抽象。
- 数值变化时建议给轻微 haptic feedback。
- White Noise 和 Focus Mode 可以共享底层 `SelectableTile`，但尺寸 variant 不同。
- Sheet 顶部 grabber、圆角、背景遮罩需要规范化。

优先级：P0  
原因：Preset 是之后扩展模式、声音、训练配置的主要入口。

## 14. 视觉系统建议

### 14.1 保留黑白极简

不建议引入复杂色彩系统。颜色应作为语义提示，而不是装饰。

建议颜色层级：

- 黑：主操作、主文字、选中态。
- 白：主背景、卡片背景。
- 浅灰：次级表面、disabled、分割线。
- 红：失败、扣分、health warning。
- 绿：增长、健康提升、正向趋势。
- 灰：中性说明、未激活状态。

### 14.2 收紧圆角和阴影

当前圆角很多，需要规范：

- Primary button：固定高度和圆角。
- Pill：全圆角。
- Metric card / session row：统一卡片圆角。
- My Cat 大卡：更大圆角，但需要成为特例组件。
- Onboarding choice：保留黑色厚底边，但固定 shadow / offset。

### 14.3 插画资源容器化

所有猫咪插画、GIF、动画都应放入固定资源容器：

- 定义最大宽高。
- 定义 baseline 或视觉中心。
- 定义不同场景的 anchor：hero center、card center、dialogue companion、share preview。
- 静态图、GIF、Lottie、Rive 替换时不改变外层布局。
- 插画不直接决定页面 spacing，由容器决定。

## 15. 文案与情绪边界

CatFocus 的语气应该是伙伴式、轻微夸张、鼓励但不羞辱。

建议：

- 成功页可以更兴奋：强化“我们一起变强了”。
- 失败页要表达失落，但不要让用户感到被责备。
- Paywall 文案围绕训练计划，不围绕高级会员身份。
- Contract 文案要有仪式感，但不要过度严厉。
- Share Card quote 可用猫咪第一人称，增加传播记忆点。

避免：

- `lazy habits are returning` 这类过强负面评价。
- 暗示医疗诊断的选项，例如直接使用 `ADHD`。
- 把付费包装成猫咪被用户抛弃的压力。

## 16. 推荐执行顺序

1. 统一 Luna / Kuro 命名和核心数值体系。
2. 建立按钮、pill、tile、card、bottom tab、dialogue bubble 的组件规范。
3. 把 Success / Fail、Problems / Goal、Preset tiles 抽象成状态驱动模板。
4. 优化失败页、Paywall、Contract 的文案，降低挫败感，增强伙伴感。
5. 规范插画资源容器，为后续 GIF / 动画替换做准备。
6. 处理动效、分享卡变体、解锁姿势等增强体验。

## 17. 需要产品决策的点

进入实现前建议确认：

- 猫咪最终默认名是 `Luna` 还是 `Kuro`。
- 用户是否可以命名猫咪。
- `Health` 与 `Fitness` 是否都需要存在。
- `Fit Points` 是否会被失败扣除。
- Paywall 是否允许跳过。
- 未付费用户是否仍能签订 Contract。
- 分享卡品牌使用 `CatFocus` 还是 `Paw-modoro`。

## 18. 总结

CatFocus 当前设计已经具备明确的产品气质：克制的黑白界面、强记忆点的猫咪角色，以及用户和猫一起训练的情感机制。

优化方向不应是把它变成更常见的 productivity app，而是把现有故事机制系统化：让每个按钮、卡片、插画、结果页和分享卡都服务同一个核心关系。
