# dotfiles-plus

广义 dotfiles 仓库：不只管理隐藏配置文件，也收纳 Codex skills、终端与编辑器配置等。

## 布局

- `codex_skill/`：Codex skills，每个子目录一个 skill
- `notify-done/`：命令跑完自动通知手机的小工具 + 配置模板 + 独立安装器 `install.sh`
- `tmux/`、`vim/`、`zsh/`：预留，待补充

## 安装

在仓库根执行：

```bash
./install.sh                 # 安装全部功能
./install.sh notify-done     # 只安装某个功能（可多个）
```

根目录的 `install.sh` 只是调度器；实际安装逻辑在每个功能目录自己的
`install.sh` 里（幂等、可重复执行）：

- `codex_skill/install.sh`：把每个 skill 符号链接到 `$CODEX_HOME/skills/`（默认 `~/.codex/skills`）
- `notify-done/install.sh`：把 `notify-done` 符号链接到 `~/.local/bin/`，首次生成配置，并添加 `nd()` 快捷命令；详见 [notify-done/README.md](notify-done/README.md)

notify-done 的配置含 Webhook 密钥，只有 `notify-done.conf.example` 模板入库；真实配置保留在 `~/.config/notify-done.conf`（首次运行 install.sh 时才从模板生成，之后不再覆盖），因此**仓库里永远不会出现密钥**。

## 当前内容

- `handoff` skill：讨论收尾时生成 `handoff.md`，供新目录里的新会话一次性读取后继续（见 [codex_skill/handoff](codex_skill/handoff/)）；读完后文档归档到任务目录下的 `temp/handoff_archive/`，不进仓库。
- `notify-done`：跑完命令（无论成败）通过企业微信/钉钉/飞书群机器人通知手机；详见 [notify-done/README.md](notify-done/README.md)。
