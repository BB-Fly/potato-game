# Puritato 文档中心

本文档中心用于帮助后续开发者或新窗口快速理解项目。阅读时建议先区分两类资料：

- 目标设计：描述 Puritato 最终希望变成什么样。
- 当前实现：描述仓库现在实际怎么跑、怎么改、哪里还只是原型。

## 推荐阅读顺序

1. [开发接手总览](development/README.md)
2. [运行入口与界面流转](development/runtime-flow.md)
3. [内容配置与注册表](development/content-config.md)
4. [地图、路线与奖励](development/map-reward-flow.md)
5. [战斗原型实现](development/combat-slice.md)
6. [资源、美术与导入](development/assets-and-art.md)
7. [模块拆分路线](development/module-splitting.md)
8. [调试、验证与 Git 规范](development/debugging-and-git.md)
9. [Brotato 数值参考总结](balance-reference/README.md)
10. [Puritato 数值设计](balance-design/README.md)
11. [数值计算定义](balance-design/stat-calculation-reference.md)

读完前 8 项，基本就能接手当前可运行版本。需要理解长期系统设计时，再阅读 `architecture/` 和 `gameplay-design/`；需要扩展内容或调整战斗曲线时，再阅读 `balance-reference/` 和 `balance-design/`。

## 文档分层

### 开发实现文档

目录：`docs/development/`

这里记录当前代码真实状态，包括启动、地图、战斗、内容配置、资源引用和常见故障。后续开发任务优先维护这里。

### 玩法设计文档

目录：`docs/gameplay-design/`

这里描述核心玩法、章节路线、节点规则、武器、魔法、道具、怪物和经济设计。它是功能实现的需求来源，但不一定完全等于当前代码。

### 数值参考文档

目录：`docs/balance-reference/`

这里按 Brotato Wiki 的属性、怪物、武器、道具、升级和难度页面提炼数值规律，作为 Puritato 后续设计的外部参考。

### 数值设计文档

目录：`docs/balance-design/`

这里描述 Puritato 自己的数值系统、公式、内容设计参考表和 buff 系统方案。它是后续新增角色、武器、魔法、道具、怪物、Boss 和难度时的数值尺子。

### 架构设计文档

目录：`docs/architecture/`

这里描述长期目标架构、系统边界、事件、固定 tick、领域模型和开放问题。`implementation-notes.md` 是历史上第一份当前实现交接说明，现在已经被 `docs/development/` 进一步拆分。

### 美术资源文档

目录：`docs/art/`

这里记录美术资源清单、生成资产、路线地图设计、像素资源路径和资源命名约定。

## 当前重要事实

- 当前可运行提交基线：`d6ea0ca Restore playable Godot prototype`。
- 最新文档中文化提交：`65508ee Translate implementation docs to Chinese`。
- 主入口是 `src/app/main.gd`。
- 主场景是 `scenes/main.tscn`。
- 当前战斗原型大量逻辑仍在 `main.gd`，尚未完全迁移到 `src/domain/combat/`。
- 武器最多自动装备 4 个，多余武器只进入库存。
- 魔法槽当前为 4 个，对应 `Q`、`E`、`R`、`F`。
- Godot 生成的 `.import` 文件默认不要批量提交。

## 文档维护原则

- 面向开发者的正文优先使用中文。
- 文件名、代码标识、函数名、命令、日志、JSON key 保持英文原文。
- 当前实现和长期目标要分开写，不要把尚未完成的系统写成已经完成。
- 每次修复重大问题后，把故障表现、原因、检查命令和修复点写入 `development/debugging-and-git.md`。
