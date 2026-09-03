# 命令跑完自动通知手机（公司 IM 群机器人版）

```
服务器 ──HTTPS──> 企业微信/飞书群机器人 ──推送──> 手机 IM App
```

## 需要什么

| 端 | 工具 | 说明 |
|---|---|---|
| 服务器 | curl、python3 | 本方案只依赖这两个，无需联网下载 |
| 服务器 | `notify-done` | 包装脚本：跑命令 → 捕获退出码 → 无论如何都通知 → 原样返回退出码 |
| 服务器 | `install.sh` | 功能安装器，与主脚本、配置模板在同一目录 |
| 手机 | 企业微信 / 钉钉 / 飞书 App | 在群里加一个「自定义机器人」即可 |

## 快速开始（推荐：仓库内安装器）

```bash
# 1) 在 dotfiles-plus 仓库里运行（或把整个 notify-done 目录拷到服务器）
cd ~/dotfiles-plus

# 2) 交互安装：会询问平台类型、Webhook 地址、通知前缀；选飞书时还会询问要 @ 的用户
./notify-done/install.sh --interactive

# 3) 新开一个终端，测试
nd --test
```

手机上对应的群应出现一条「测试通知」。如果没收到，先看下面各平台的自测命令。

## 三种群机器人（选一个）

在对应的 IM 群里添加一个「自定义机器人」，复制它的 Webhook 地址。平台配置在 `~/.config/notify-done.conf` 里用 `WEBHOOK_MSG_TYPE` 区分：

### 企业微信（wecom）
- 群聊 → 右上角 → 「添加群机器人」→ 复制 Webhook 地址。
- 配置：`WEBHOOK_MSG_TYPE=wecom`，Webhook 形如 `https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxx`。
- 自测：`curl -X POST '你的Webhook' -H 'Content-Type: application/json' -d '{"msgtype":"text","text":{"content":"测试"}}'`

### 钉钉（dingtalk）
- 群设置 → 智能群助手 → 添加机器人 → 自定义 → 复制 Webhook 地址。
- 配置：`WEBHOOK_MSG_TYPE=dingtalk`，Webhook 形如 `https://oapi.dingtalk.com/robot/send?access_token=xxxx`。
- 自测：`curl -X POST '你的Webhook' -H 'Content-Type: application/json' -d '{"msgtype":"text","text":{"content":"测试"}}'`

### 飞书（feishu）
- 群设置 → 群机器人 → 添加机器人 → 自定义机器人 → 复制 Webhook 地址。
- 配置：`WEBHOOK_MSG_TYPE=feishu`，Webhook 形如 `https://open.feishu.cn/open-apis/bot/v2/hook/xxxx`。
- 自测：`curl -X POST '你的Webhook' -H 'Content-Type: application/json' -d '{"msg_type":"text","content":{"text":"测试"}}'`
- @ 提醒：被 @ 的用户即使把群消息设为静音，手机端也能收到推送。在配置里填 `FEISHU_AT_USERS`（open_id，多个用英文逗号分隔）或 `FEISHU_AT_ALL=1` 即可，`install.sh --interactive` 选 feishu 时会直接询问。
  - open_id 以 `ou_` 开头，仅支持机器人所在群的群成员；获取方法见[飞书官方说明](https://open.feishu.cn/document/uAjLw4CM/ugTN1YjL4UTN24CO1UjN/trouble-shooting/how-to-obtain-openid)。
  - 自测 @：`curl -X POST '你的Webhook' -H 'Content-Type: application/json' -d '{"msg_type":"text","content":{"text":"测试<at user_id=\"ou_你的open_id\"></at>"}}'`

> 注意：上面自测命令里 JSON 只含英文时不会报错；但脚本发送的是完整通知（含换行，用 python3 正确转义），自测仅用于确认网络与机器人本身可用。

## 日常用法

```bash
nd python train.py                 # 跑完（无论成败）都通知
nd -- make -j8 build              # 命令以 - 开头时用 --
nd bash -c 'do_a && do_b'         # 需要整条命令链时
nd --log-file /tmp/run.log python train.py   # 无条件把输出写入指定日志
```

`tmrun` 的用法（命令按参数传给 `sh -c` 执行；含分号时用 `bash -c` 包住，含管道/重定向时用 `sh -c` 包住）：

```bash
tmrun train python train.py --epochs 100          # 简单命令
tmrun train bash -c 'echo a; echo b; exit 1'      # 多条命令/分号
tmrun train sh -c 'echo a | tee out.txt'          # 管道/重定向
```

通知内容包括：主机名、命令、成功/失败（含退出码）、耗时、时间。脚本**原样返回命令的退出码**，可继续链式使用：

```bash
nd python train.py && nd ./deploy.sh
```

crontab / systemd 里同样可以直接调用 `notify-done`。

## 部署到远程服务器

安装器依赖同目录的 `notify-done` 主脚本和配置模板，把**整个目录**传到远程服务器再运行：

```bash
scp -r notify-done user@remote:/tmp/
ssh user@remote 'bash /tmp/notify-done/install.sh --interactive'
```

## 手动安装（不想要安装器时）

```bash
mkdir -p ~/.local/bin ~/.config
cp notify-done ~/.local/bin/notify-done
chmod 755 ~/.local/bin/notify-done
cp notify-done.conf.example ~/.config/notify-done.conf
chmod 600 ~/.config/notify-done.conf
# 编辑 ~/.config/notify-done.conf 填好 WEBHOOK_URL
```

然后在 `~/.bashrc`（或 `~/.zshrc`）加一行快捷命令：

```bash
nd() { notify-done "$@"; }
```

## 注意

- 配置文件里的 Webhook 地址本身就是密钥，务必 `chmod 600`，别外传。
- 不要在通知里写密码等敏感内容。
- 命令被 `kill -9`、SSH 断连时进程已消失，无法通知（所有这类工具的共性）。
- 想先看会发什么、不发，用 `nd --dry-run <命令>`。
- 安装器幂等，重复执行不会覆盖已填好的配置，也不会重复写入 `nd()`；`--interactive` 会重写配置，属有意为之。
- 若公司内部另有可公网访问的通知服务，也可以自行把 `send_notification` 改指向它。
