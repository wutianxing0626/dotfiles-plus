#!/usr/bin/env bash
# install.sh — notify-done 功能安装器（dotfiles-plus 模块化安装）
#
# 作用：在机器上安装 notify-done（长命令跑完自动通知手机）。
#       只依赖 curl + python3，不需要联网下载依赖，不需要开放入站端口。
#       主脚本唯一来源是同目录的 notify-done 文件（符号链接，无内嵌副本）。
#
# 用法：
#   ./install.sh                        # 仅安装 + 生成占位配置 + 添加 nd()
#   ./install.sh --interactive          # 交互询问 Webhook、平台、前缀后写入配置
#   ./install.sh --help
#
# 幂等：重复执行安全，不会覆盖已有配置，不会重复写入 rc 文件。
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
用法: install.sh [--interactive] [--help]

  --interactive  交互式询问 Webhook 地址、平台类型、通知前缀并写入配置；
                 还会询问日志尾部行数（默认 20）和成功时是否附日志；
                 选 feishu 时额外询问要 @ 的用户（手机端必收通知）
  --help         显示本帮助

安装内容:
  notify-done  ->  $HOME/.local/bin/notify-done（符号链接到本目录的 notify-done）
  配置         ->  $HOME/.config/notify-done.conf（已存在则跳过）
  nd() 函数    ->  追加到 ~/.bashrc 和 ~/.zshrc（已存在则跳过）
EOF
}

INTERACTIVE=0
for arg in "$@"; do
  case "$arg" in
    --interactive) INTERACTIVE=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "未知参数: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

# ---------- 路径 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILENAME="notify-done.conf"
CONF_FILE="${NOTIFY_DONE_CONFIG:-$HOME/.config/$CONF_FILENAME}"
BIN_DIR="${NOTIFY_DONE_BIN_DIR:-$HOME/.local/bin}"
BIN="$BIN_DIR/notify-done"
SRC="$SCRIPT_DIR/notify-done"
CONF_SRC="$SCRIPT_DIR/notify-done.conf.example"

# ---------- 预检查 ----------
for t in curl python3; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "错误: 需要 $t 命令，但当前机器没有，请先安装 $t" >&2
    echo "  例如 Debian/Ubuntu: sudo apt-get install -y $t" >&2
    echo "  例如 RHEL/CentOS:   sudo yum install -y $t" >&2
    exit 1
  fi
done

[[ -f "$SRC" ]] || { echo "错误: 缺少同目录的 notify-done 主脚本" >&2; exit 1; }
[[ -f "$CONF_SRC" ]] || { echo "错误: 缺少同目录的 notify-done.conf.example" >&2; exit 1; }

# ---------- 把 ~/.local/bin 加入 PATH（bash/zsh）----------
add_path_line() {
  local rc="$1"
  [[ -e "$rc" ]] || touch "$rc"
  if grep -q '\.local/bin' "$rc" 2>/dev/null; then
    echo "PATH 已包含 ~/.local/bin，跳过: $rc"
  elif [[ -L "$rc" ]]; then
    echo "跳过: $rc 是符号链接（指向 $(readlink "$rc")），PATH 请在源文件里维护"
  else
    printf '\n# ensure ~/.local/bin in PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
    echo "已把 ~/.local/bin 加入 PATH: $rc"
  fi
}

# ---------- 安装 notify-done（符号链接，仓库即数据源）----------
mkdir -p "$BIN_DIR"
ln -sfn "$SRC" "$BIN"
echo "已链接 notify-done -> $BIN"

# ---------- 生成配置（已存在则保留，避免覆盖密钥）----------
if [[ ! -f "$CONF_FILE" ]]; then
  mkdir -p "$(dirname "$CONF_FILE")"
  install -m 600 "$CONF_SRC" "$CONF_FILE"
  echo "已生成配置: $CONF_FILE"
  if [[ $INTERACTIVE -eq 0 ]]; then
    echo "  请编辑其中的 WEBHOOK_URL 之后再测试。"
  fi
else
  echo "配置已存在: $CONF_FILE（跳过）"
fi

# ---------- 交互式写入配置 ----------
if [[ $INTERACTIVE -eq 1 ]]; then
  read -rp "用哪个群机器人平台？[wecom/dingtalk/feishu]（默认 wecom）: " p_msg
  p_msg="${p_msg:-wecom}"
  p_msg="$(printf '%s' "$p_msg" | tr '[:upper:]' '[:lower:]')"
  read -rp "粘贴 Webhook 地址: " p_url
  read -rp "通知标题前缀（回车用 hostname）: " p_prefix
  if [[ -z "$p_prefix" ]]; then
    p_prefix="$(hostname 2>/dev/null || echo server)"
  fi
  # 飞书支持 @ 指定用户 / @ 所有人：被 @ 的人即使群消息静音，手机端也能收到推送
  p_at_users=""
  p_at_all=0
  if [[ "$p_msg" == "feishu" ]]; then
    echo "飞书可配置 @ 提醒（移动端必收通知的关键）："
    read -rp "  要 @ 哪些用户？填飞书 open_id（ou_ 开头，多个用英文逗号分隔；回车跳过）: " p_at_users
    # open_id 不含空格；去掉输入中的空白，避免逗号后的空格写进配置后被 source 误解析
    p_at_users="$(printf '%s' "$p_at_users" | tr -d '[:space:]')"
    read -rp "  是否同时 @ 所有人？[y/N] " p_at_all_yn
    p_at_all_yn="$(printf '%s' "${p_at_all_yn:-n}" | tr '[:upper:]' '[:lower:]')"
    [[ "$p_at_all_yn" == "y" || "$p_at_all_yn" == "yes" ]] && p_at_all=1
  fi
  # 日志捕获：失败/崩溃时把命令输出末尾若干行附到通知里（失败排查的关键）
  read -rp "失败/崩溃时附上末尾几行日志？（0 = 关闭，回车默认 20）: " p_log_lines
  p_log_lines="${p_log_lines:-20}"
  read -rp "成功时也附带日志尾部吗？[y/N]（回车默认否，只在失败时附）: " p_log_all_yn
  p_log_all_yn="$(printf '%s' "${p_log_all_yn:-n}" | tr '[:upper:]' '[:lower:]')"
  if [[ "$p_log_all_yn" == "y" || "$p_log_all_yn" == "yes" ]]; then
    p_log_all=1
  else
    p_log_all=0
  fi
  mkdir -p "$(dirname "$CONF_FILE")"
  {
    printf '%s\n' '# notify-done 配置（由 install.sh --interactive 生成）'
    printf 'NOTIFY_BACKEND=%s\n' 'webhook'
    printf 'WEBHOOK_MSG_TYPE=%s\n' "$p_msg"
    printf 'WEBHOOK_URL=%s\n' "$p_url"
    if [[ "$p_msg" == "feishu" ]]; then
      printf 'FEISHU_AT_USERS=%s\n' "$p_at_users"
      printf 'FEISHU_AT_ALL=%s\n' "$p_at_all"
    fi
    printf 'NOTIFY_TITLE_PREFIX=%s\n' "$p_prefix"
    # 日志捕获：失败/崩溃时把命令输出末尾若干行附到通知里（失败排查的关键）
    printf 'NOTIFY_LOG_LINES=%s\n' "$p_log_lines"
    printf 'NOTIFY_LOG_ON_ALL=%s\n' "$p_log_all"
  } > "$CONF_FILE"
  chmod 600 "$CONF_FILE"
  echo "已写入配置: $CONF_FILE"
  echo "  日志尾部: NOTIFY_LOG_LINES=$p_log_lines（0 = 关闭），NOTIFY_LOG_ON_ALL=$p_log_all（1 = 成功也附）"
  if [[ "$p_msg" == "feishu" && -z "$p_at_users" && "$p_at_all" == 0 ]]; then
    echo "  提示: 未配置 @ 提醒；之后可在配置里填 FEISHU_AT_USERS / FEISHU_AT_ALL（见模板注释）。"
  fi
fi

# ---------- 添加 nd() 到 rc（bash/zsh）----------
append_nd() {
  local rc="$1"
  [[ -e "$rc" ]] || touch "$rc"
  # 按“是否已定义 nd() 函数”判断，而不是按注释标记：
  # ~/.zshrc 可能是指向仓库 zsh/zshrc 的软链，按标记追加会把仓库文件写脏。
  if grep -Eq '^[[:space:]]*nd\(\)[[:space:]]*\{[[:space:]]*notify-done' "$rc" 2>/dev/null; then
    echo "nd() 已定义，跳过: $rc"
  elif [[ -L "$rc" ]]; then
    echo "跳过: $rc 是符号链接（指向 $(readlink "$rc")），nd() 请在源文件里维护"
  else
    {
      printf '\n# notify-done: nd() 命令跑完自动通知手机\n'
      printf 'nd() { notify-done "$@"; }\n'
    } >> "$rc"
    echo "已添加 nd() 到: $rc"
  fi
}

add_path_line "$HOME/.bashrc"
add_path_line "$HOME/.zshrc"
append_nd "$HOME/.bashrc"
append_nd "$HOME/.zshrc"

# ---------- 完成 ----------
echo
echo "==> 安装完成 ✅"
echo "  工具: $BIN"
echo "  配置: $CONF_FILE"
if [[ $INTERACTIVE -eq 1 ]]; then
  echo "  下一步: 新开终端后运行  nd --test  发一条测试通知，手机上显示即成功。"
else
  echo "  下一步: 编辑 $CONF_FILE 填好 WEBHOOK_URL，然后运行  nd --test  测试。"
fi
echo "  随便用: nd python train.py   （跑完无论成败都会发通知）"
echo "  注意: 需新开终端，或先 source ~/.zshrc（若你用的是 zsh）"
