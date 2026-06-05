# Brotato 升级数值参考

来源：[Brotato Wiki - Upgrades](https://brotato.wiki.spellsandguns.com/Upgrades)

## 结构

Brotato 每次升级提供 4 个候选升级，升级只提升一级属性。升级分 4 个 tier，tier 越高提供的数值越多。玩家可以重随候选，因此升级系统既是补属性的稳定来源，也是玩家主动寻找关键属性的入口。

## 升级幅度

Brotato 的升级数值表很适合作为“每一档属性价值”的参考：

| 属性 | I | II | III | IV |
|-|-:|-:|-:|-:|
| Max HP | 3 | 6 | 9 | 12 |
| HP Regeneration | 2 | 3 | 4 | 5 |
| Life Steal | 1 | 2 | 3 | 4 |
| Damage | 5 | 8 | 12 | 16 |
| Melee Damage | 2 | 4 | 6 | 8 |
| Ranged Damage | 1 | 2 | 3 | 4 |
| Elemental Damage | 1 | 2 | 3 | 4 |
| Attack Speed | 5 | 10 | 15 | 20 |
| Crit Chance | 3 | 5 | 7 | 9 |
| Engineering | 2 | 3 | 4 | 5 |
| Range | 15 | 30 | 45 | 60 |
| Armor | 1 | 2 | 3 | 4 |
| Dodge | 3 | 6 | 9 | 12 |
| Speed | 3 | 6 | 9 | 12 |
| Luck | 5 | 10 | 15 | 20 |
| Harvesting | 5 | 8 | 10 | 12 |

这个表透露了属性价值排序：护甲、远程/元素伤害、生命偷取等每点价值高；范围、攻速、幸运用更大的数字表达；最大生命居中。

## 稀有度节奏

Brotato 在特定等级保证升级 tier：

- Level 1：必定 Tier I。
- Level 5：必定 Tier II。
- Level 10、15、20：必定 Tier III。
- Level 25 以及之后每 5 级：必定 Tier IV。

其他等级由等级和幸运影响稀有度。设计上，这让玩家早期先补基础，中期看到强升级，后期开始追高阶关键属性。

## 设计启发

Puritato 当前是路线图层数制，不一定需要经验升级。但可以把 Brotato 升级系统转译为三种节点：

- 战斗胜利后的“成长三选一”：提供一级属性。
- 大师节点的“强化三选一”：提供武器/法术局部属性。
- 奇遇节点的“代价升级”：提供强属性但附带风险。

建议 Puritato 采用 3 个升级 tier，而不是一开始就做 4 个：

| 属性 | 普通 | 稀有 | 传说 | 说明 |
|-|-:|-:|-:|-|
| Max HP | 8 | 16 | 28 | Puritato 基础生命较高，单次升级可略大 |
| Max Mana | 6 | 12 | 20 | 魔法构筑核心资源 |
| Melee Attack | 2 | 4 | 7 | 对应近战武器缩放 |
| Ranged Attack | 2 | 4 | 7 | 远程较安全，可用低攻速/低 AOE 平衡 |
| Spell Power | 2 | 4 | 7 | 魔法伤害与治疗共同缩放 |
| Defense | 1 | 2 | 4 | 需配合防御公式 |
| Attack Speed | 6% | 12% | 20% | 建议有软上限 |
| Crit Chance | 3% | 6% | 10% | 刺杀学派可额外获得 |
| Move Speed | 4% | 8% | 14% | 过高会改变走位难度 |
| Health Regen | 1 | 2 | 4 | 定义为每秒或每 5 秒恢复 |
| Mana Regen | 2 | 4 | 7 | 魔法循环重要属性 |
| Luck | 5 | 10 | 18 | 影响奖励质量和标签池 |

如果后续加入经验升级，则可以复用 Brotato 的“固定等级保底高 tier”思想；如果继续用路线图节点，则可改为“层数保底”：第 1 层只出普通，第 2-3 层开始稀有，第 4-6 层开始传说，第 7 层后传说权重增加。
