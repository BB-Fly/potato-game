# 运行入口与界面流转

本文档说明当前 Godot 原型如何启动、如何构建 UI，以及为什么此前会出现灰屏。

## 主场景

入口场景是：

```text
scenes/main.tscn
```

场景里只有一个 `Node`，挂载脚本：

```text
src/app/main.gd
```

因此，启动是否有画面完全取决于 `main.gd` 是否在 `_ready()` 中创建可见节点。

## `_ready()` 启动链路

当前健康启动链路：

```text
_ready()
  -> _ensure_input_actions()
  -> _bootstrap_architecture()
  -> _build_root()
  -> _show_starter_screen()
```

职责说明：

- `_ensure_input_actions()`：注册移动和魔法按键。
- `_bootstrap_architecture()`：创建 `EventBus`、`ContentRegistry`、`RunContext`、`MapFlow` 等服务，并加载 `content/base`。
- `_build_root()`：创建 `ui_root`，作为所有 UI 和交互对象的逻辑根节点。
- `_show_starter_screen()`：进入初始装备选择界面。

健康日志：

```text
Puritato playable slice ready. Registered types: [...]
```

如果日志变成旧的 architecture bootstrap 文本，说明 `main.gd` 很可能被回退到旧版本。

## 逻辑画布和缩放

当前固定逻辑尺寸：

```gdscript
const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)
```

`_update_ui_root_transform()` 每帧执行，负责：

1. 读取真实 viewport 尺寸。
2. 计算等比缩放比例。
3. 缩放 `ui_root`。
4. 把 `ui_root` 居中。

这让窗口缩放和全屏时，点击热点、奖励节点、战斗活动区域仍保持一致。

新增界面元素时应遵守：

- 加到 `ui_root` 或其子节点下。
- 使用 1280x720 逻辑坐标。
- 不要绕过 `ui_root` 直接挂到主场景根节点。

## 当前 screen 状态

`main.gd` 使用字符串 `screen` 表示当前界面。

| 状态 | 入口函数 | 说明 |
| --- | --- | --- |
| `starter` | `_show_starter_screen()` | 初始装备三选一 |
| `map` | `_show_map_screen()` | 路线选择、奖励预览、战斗入口 |
| `reward` | `_show_reward_choices()` | 奖励三选一 |
| `shop` | `_show_shop_screen()` | 简化商店 |
| `combat` | `_start_combat()` | 战斗 |
| `defeat` | `_show_defeat_screen()` | 失败重试 |
| `victory` | `_show_victory_screen()` | 通关 |

`_clear_screen()` 会清空 `ui_root` 的全部子节点。战斗现在由 `scenes/combat_scene.tscn` 承载，进入战斗时创建独立 `PlayableCombatScene`，战斗结束后销毁整棵战斗场景。切换界面时通常是“清空再重建”。

## UI 构建方式

当前 UI 大多由代码直接创建 Godot `Control` 节点。通用 UI 创建函数已经拆到：

```text
src/app/playable/playable_ui_factory.gd
```

`main.gd` 里保留了同名 wrapper，以降低第一阶段拆分风险。后续可以逐步把调用点直接改成 `PlayableUiFactory` 或继续提取屏幕控制器。

常见节点类型：

- `Button`
- `Label`
- `TextureRect`
- `PanelContainer`
- `ProgressBar`
- `HBoxContainer`
- `VBoxContainer`
- `ColorRect`

通用 helper：

- `_make_label()`
- `_make_pixel_button()`
- `_make_map_node_button()`
- `_make_choice_card()`
- `_make_bar()`
- `_style_box()`

当前仍是原型阶段，尚未形成独立 UI 组件目录。后续如果拆分，建议从 reward card、shop card、combat HUD、map node button 这些重复结构开始。

## 灰屏排查

灰屏最常见原因：

1. `main.gd` 被覆盖成旧版，只做架构初始化，不创建 UI。
2. `_ready()` 没有调用 `_show_starter_screen()`。
3. UI 被加在 `ui_root` 外面，缩放或位置异常。
4. 背景资源缺失并且没有 fallback。

检查命令：

```powershell
rg -n "playable slice ready|_show_starter_screen|LOGICAL_VIEWPORT_SIZE" src\app\main.gd
```

预期：

- 存在 `LOGICAL_VIEWPORT_SIZE`。
- `_ready()` 调用 `_show_starter_screen()`。
- headless 启动日志包含 `Puritato playable slice ready`。

## 可见窗口启动

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

如果误用了 `-WindowStyle Hidden`，游戏可能已经启动但窗口不可见。重新启动可见窗口即可。
