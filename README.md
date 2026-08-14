# dotfiles-plus

广义 dotfiles 仓库：不只管理隐藏配置文件，也收纳 Codex skills、终端与编辑器配置等。

## 布局

- `codex_skill/`：Codex skills，每个子目录一个 skill
- `tmux/`、`vim/`、`zsh/`：预留，待补充

## 安装

在仓库根执行：

```bash
./install.sh
```

脚本会把仓库内容符号链接到对应位置（幂等，可重复执行）：

- `codex_skill/*` → `$CODEX_HOME/skills/`（默认 `~/.codex/skills`）

## 同步

用 git 管理，推送到 GitHub public repo；新机器 `git clone` 后执行 `./install.sh`
即可。

## 当前内容

- `handoff` skill：讨论收尾时生成 `handoff.md`，供新目录里的新会话一次性读取后
  继续（见 [codex_skill/handoff](codex_skill/handoff/)）；读完后文档归档到
  任务目录下的 `temp/handoff_archive/`，不进仓库。
