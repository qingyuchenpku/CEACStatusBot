#!/usr/bin/env bash
# 交互式配置 CEACStatusBot 所需的 GitHub Actions Secrets。
# 所有输入只会通过 gh CLI 直接写入 GitHub 仓库的加密 secrets，不会存到本地文件。
set -euo pipefail

REPO="${REPO:-qingyuchenpku/CEACStatusBot}"

command -v gh >/dev/null || { echo "没找到 gh CLI，请先安装：brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh 未登录，请先运行：gh auth login"; exit 1; }

echo "将为仓库 $REPO 配置 secrets。"
echo "直接回车 = 跳过该项（保留已有的值）。"
echo

set_secret() {   # set_secret 名称 "提示语" [hidden]
  local name="$1" prompt="$2" hidden="${3:-}" value=""
  if [ "$hidden" = "hidden" ]; then
    read -r -s -p "$prompt: " value; echo
  else
    read -r -p "$prompt: " value
  fi
  if [ -z "$value" ]; then
    echo "  → 跳过 $name"
    return
  fi
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO"
  echo "  ✓ 已设置 $name"
}

echo "--- 必填：签证申请信息 ---"
echo "LOCATION 示例：CHINA, BEIJING / CHINA, SHANGHAI / HONG KONG / JAPAN, TOKYO"
echo "（完整列表见仓库里的 LOCATION.md）"
set_secret LOCATION        "LOCATION（使领馆，照抄 LOCATION.md 里的写法）"
set_secret NUMBER          "NUMBER（AA + 9 位的 Application ID，或 Case Number）"
set_secret PASSPORT_NUMBER "PASSPORT_NUMBER（护照号）"
set_secret SURNAME         "SURNAME（姓氏前 5 个字母，不足 5 位就写全）"

echo
echo "--- 必填：时区（Refused 状态的免打扰逻辑依赖它，不设会报错）---"
echo "示例：Asia/Shanghai / America/New_York / Europe/London"
set_secret TIMEZONE     "TIMEZONE"
set_secret ACTIVE_HOURS "ACTIVE_HOURS（可选，Refused 状态只在此时段通知，如 08:00-22:00）"

echo
echo "--- 邮件通知 ---"
echo "提示：QQ/163 邮箱用「授权码」，Gmail 用「应用专用密码」，都不是登录密码。"
set_secret FROM     "FROM（发件邮箱）"
set_secret TO       "TO（收件邮箱，多个用 | 分隔，中间不要有空格）"
set_secret PASSWORD "PASSWORD（发件邮箱的授权码/应用专用密码，输入不回显）" hidden
echo "SMTP 一般可留空：会自动用 smtp.<你的邮箱域名> + SSL 465 端口。"
echo "Outlook/企业邮箱等不走 465 SSL 的，才需要手动填，如 smtp.example.com:465"
set_secret SMTP "SMTP（可选）"

echo
echo "完成。当前仓库已有的 secrets："
gh secret list --repo "$REPO"
echo
echo "下一步：手动触发一次来验证"
echo "  gh workflow run 'CEAC visa status check' --repo $REPO"
