# 调试、验证与 Git 规范

本文档记录当前项目最常用的检查命令、故障排查和提交流程。

## 基础检查

查看工作区：

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game status --short
```

只看 tracked 文件：

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game status --short --untracked-files=no
```

检查 diff 格式：

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game diff --check
```

Godot headless 启动：

```powershell
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

战斗数值/buff 运行时验证：

```powershell
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --script 'res://tools/validate_combat_balance_runtime.gd'
```

健康输出应包含：

```text
Puritato playable slice ready.
```

## 本机 Godot 安装

本机 Godot 目录已确认：

```text
C:\Program Files\Godot
```

当前目录结构：

```text
C:\Program Files\Godot\GodotSharp\
C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe
C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe
```

后续自动验证优先调用 console 版：

```powershell
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

需要打开可见编辑器/游戏窗口时调用 GUI 版：

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

## 启动可见窗口

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

如果看不到窗口，检查是否误用了 `-WindowStyle Hidden`，或是否已经有旧进程：

```powershell
Get-Process Godot* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,MainWindowTitle
```

## PowerShell 编码提示

当前环境下命令输出经常出现：

```text
Cannot set property. Property setting is supported only on core types in this language mode.
```

这是 PowerShell 受限语言模式下设置 `OutputEncoding` 的提示，不是 Godot 项目错误。判断项目是否健康时，看 Godot 自己的日志和退出码。

PowerShell 也可能把中文显示成乱码。文件本身仍可能是正常 UTF-8。必要时可以用 Node 按 UTF-8 读取确认。

## 常见故障

### 灰屏

检查：

```powershell
rg -n "playable slice ready|_show_starter_screen|LOGICAL_VIEWPORT_SIZE" src\app\main.gd
```

常见原因：

- `main.gd` 被覆盖回旧版。
- `_ready()` 没有进入 `_show_starter_screen()`。
- 背景资源硬依赖了不存在的图片。
- UI 没有挂在 `ui_root` 下。

### 全屏后点击错位

检查新增节点是否挂在 `ui_root` 下。当前缩放模型只管理 `ui_root`。

### 武器数量不对

检查是否把库存数量当成装备数量。应使用：

```text
run_context.equipped_weapons
_equipped_weapon_count()
```

最多 4 个武器自动装备槽。

### 魔法没有触发

检查：

- `RunContext.equipped_magics.resize(4)`。
- `_ensure_input_actions()` 是否注册了 `cast_magic_0` 到 `cast_magic_3`。
- HUD 是否显示 `Q`、`E`、`R`、`F`。
- `player_mana` 是否足够。

### 图标或贴图不显示

检查：

- 文件是否存在。
- `base_assets.json` 的路径是否正确。
- `asset_refs` 是否引用了正确 asset ID。
- 是否误引用了规划中但未提交的资源。

## 提交规范

提交前：

1. `git diff --check`
2. Godot headless 启动检查
3. `git status --short`
4. 确认没有误提交 `.import` 噪声

推荐提交粒度：

- 代码功能提交只包含相关代码和必要配置。
- 资源提交包含运行时 PNG、source、prompt、必要配置。
- 文档提交只包含文档。

## 推送已知可运行版本

保存一个可运行点时，建议提交信息写清楚：

```text
Restore playable Godot prototype
Document playable prototype implementation
```

当前可用恢复点：

- `d6ea0ca Restore playable Godot prototype`
- `65508ee Translate implementation docs to Chinese`

## Git 索引权限问题

如果 `git add` 报：

```text
Unable to create '.git/index.lock': Permission denied
```

检查：

- 是否存在 `.git/index.lock`。
- 是否有 Godot 或其他程序占用项目。
- 在当前 Codex 环境中，可能需要用提权方式写入 Git 索引。

不要手动删除不确定来源的 lock 文件。先确认没有正在运行的 Git 进程。
