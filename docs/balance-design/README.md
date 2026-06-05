# Puritato 数值设计

本目录是 Puritato 的数值系统设计稿，只描述规则和推荐参数，不实现代码。

文档：

- [整体数值系统与算法](puritato-balance-system.md)
- [数值计算定义](stat-calculation-reference.md)
- [内容设计参考数值](content-authoring-reference.md)
- [Buff 系统设计](buff-system-design.md)
- [Entity 数值档案](entities/README.md)

设计目标：

- 适配当前路线图式单局流程，而不是照搬 Brotato 的 20 波完整结构。
- 保留 Brotato 的核心优点：属性清晰、构筑方向明确、奖励有取舍、难度逐档改变体验。
- 与当前项目内容结构兼容：角色、学派、武器、魔法、道具、怪物、Boss、商店、奖励、buff 都可通过配置扩展。
- 让后续新增内容有可用的数值尺子，避免每个条目临时拍脑袋。

当前建议以 6 层 Demo 闭环为第一目标：2 章，每章 3 个小关，每层包含路线奖励、战斗节点和战斗后奖励。第 7 层之后的内容按扩展章节或高难模式处理。

## Entity 记录机制

所有角色、武器、法术、道具、怪物、Boss 和 Buff 都应在 [entities](entities/README.md) 下建立独立数值档案。档案负责记录：

- 当前运行时配置值。
- 建议重设计值。
- 定位、预算、交互关系和验证目标。
- 哪些字段已经实现，哪些只是设计预留。

后续新增或调整内容时，推荐先复制 [Entity 模板](entities/_entity-template.md)，再决定是否同步修改 `content/base`。

## 引用约定

文档之间使用 `@` 标记引用目标。常用形式：

- `@balance-design/stat-calculation-reference.md`：引用数值计算定义。
- `@entities/weapons/fries.md`：引用具体 entity 档案。
- `@entities/buffs/bruise.md`：引用具体 buff 档案。

如果需要点击跳转，可以在同一句里额外放 Markdown 链接；但正文语义引用优先保留 `@...`，方便搜索。
