# Entity 数值档案

本目录记录当前已有 entity 的重设计数值。这里是“设计源”，不是运行时配置；后续真正改 `content/base/*.json` 前，应先在这里确认设计意图、预算、数值和验证目标。

## 引用规范

文档之间用 `@` 进行语义引用。示例：

- `@entities/weapons/fries.md`：引用薯条武器档案。
- `@entities/buffs/bruise.md`：引用瘀伤 buff 档案。
- `@balance-design/stat-calculation-reference.md`：引用统一数值计算定义。

当一个 entity 使用另一个 entity 的效果时，只在使用者文档中说明“会触发/施加/依赖哪个文档”。具体数值、持续时间、叠层规则、公式和验证目标写在被引用 entity 自己的档案中。

## 目录

### 角色

- [土豆少侠](characters/potato-hero.md)

### 武器

- [薯条](weapons/fries.md)

### 法术

- [全面发展](magics/comprehensive-development.md)

### 道具

- [土豆强化](items/potato-enhancement.md)

### 怪物

- [发芽土豆](monsters/sprouting-potato.md)
- [蘑菇孢子](monsters/mushroom-spore.md)
- [炸弹果苗](monsters/bomb-fruitling.md)

### Boss

- [Demo 污染源](bosses/demo-pollution-source.md)

### Buff

- [瘀伤](buffs/bruise.md)
- [眩晕](buffs/stun.md)
- [全面发展 Buff](buffs/comprehensive-development.md)
- [土豆强化 Buff](buffs/potato-enhancement.md)

## 记录原则

- 每个 entity 一个独立文档，避免总表越来越难维护。
- 每个文档同时记录当前配置值和建议重设计值，方便后续改 JSON 时对照。
- 数值字段使用运行时 JSON 的英文 key；解释、目标和备注使用中文。
- 设计值可以先包含未来字段，例如 `spell_power`、`control_resistance`、`first_floor`。这些字段是否已经实现，应在文档里写清楚。
- 改动运行时配置后，要回到对应 entity 文档更新“当前配置值”或增加“已同步”记录。

## 推荐流程

1. 新增或调整内容时，先复制 [_entity-template.md](_entity-template.md)。
2. 填写定位、当前值、建议值、预算说明和验证目标。
3. 只在设计通过后修改 `content/base`。
4. 修改后跑战斗验证，再把实际表现记录回文档。

## 当前重设计方向

本轮重设计以 6 层 Demo 闭环为基准：

- 角色保留均衡新手定位。
- 薯条从“高频高伤害”下调为稳定近战清群武器。
- 全面发展从“伤害 + 强 buff + 高频自动施放”收敛为通用短窗 buff 法术。
- 土豆强化从无限传说堆叠改为有限堆叠成长道具。
- 三个小怪拆出明确职责：基础追击、慢速孢子压力、爆炸威胁。
- Demo Boss 增加阶段预算和技能预算，避免只靠生命值撑时长。
