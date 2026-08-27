# dotfiles-plus

广义 dotfiles 仓库：不只管理隐藏配置文件，也收纳 Codex skills、终端与编辑器配置等。

## 布局

- `codex_skill/`：Codex skills，每个子目录一个 skill
- `notify-done/`：命令跑完自动通知手机的小工具 + 配置模板 + 独立安装器 `install.sh`
- `zsh/`：zsh 通用配置 + `install.sh`（机器相关配置走 `~/.zshrc.local`）
- `tmux/`：tmux 配置（上游 `.tmux.conf` + 你的 `.tmux.conf.local`）+ `install.sh`
- `vim/`：vim 配置（`.vimrc`）+ `install.sh`

## 安装

在仓库根执行：

```bash
./install.sh                 # 安装全部功能
./install.sh notify-done     # 只安装某个功能（可多个）
```

`./install.sh` 会自动先装 zsh 前置依赖（oh-my-zsh + 两个 zsh 插件），
已存在则跳过；系统级依赖（git/zsh/tmux/curl/python3）仍需先手动安装。
根目录的 `install.sh` 负责前置依赖 + 调度；实际安装逻辑在每个功能目录自己的
`install.sh` 里。

## 当前内容

- `handoff` skill：讨论收尾时生成 `handoff.md`，供新目录里的新会话一次性读取后继续（见 [codex_skill/handoff](codex_skill/handoff/)）；读完后文档归档到任务目录下的 `temp/handoff_archive/`，不进仓库。
- `notify-done`：跑完命令（无论成败）通过企业微信/钉钉/飞书群机器人通知手机；详见 [notify-done/README.md](notify-done/README.md)。
- `zsh`：zsh 主题/插件/别名等通用配置随仓库走（含自定义 `bashmix` 主题）；conda/nvm 等机器差异保留在 `~/.zshrc.local`。
- `tmux`：gpakosz 风格 tmux 配置，上游 `.tmux.conf` + 你的定制 `.tmux.conf.local` 都由仓库托管。
- `vim`：学习期 `.vimrc`（显示/缩进/搜索/编辑体验 + 中文编码），随仓库走。
