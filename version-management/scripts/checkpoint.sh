#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: checkpoint.sh [--init-approved] [--message MESSAGE] [--path PATH]

Records the current local version of a folder so an agent can return to it later.
Every successful run creates one version record, even when no files changed.

Options:
  --init-approved   Allow first-time setup when the folder has no version record.
  --message TEXT    Use a custom plain-language version label.
  --path PATH       Folder to protect. Defaults to the current directory.
  -h, --help        Show this help.
EOF
}

init_approved=0
message="记录当前版本"
target_path="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-approved)
      init_approved=1
      shift
      ;;
    --message)
      if [[ $# -lt 2 ]]; then
        echo "缺少 --message 的内容。" >&2
        exit 64
      fi
      message="$2"
      shift 2
      ;;
    --path)
      if [[ $# -lt 2 ]]; then
        echo "缺少 --path 的路径。" >&2
        exit 64
      fi
      target_path="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      show_help >&2
      exit 64
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  cat >&2 <<'EOF'
你的电脑还没有安装用于版本管理的基础工具。要我帮你安装吗？安装后我就可以在改文件前后记录版本，方便之后回退。
EOF
  exit 127
fi

if [[ ! -d "$target_path" ]]; then
  echo "目标文件夹不存在：$target_path" >&2
  exit 66
fi

cd "$target_path"

ensure_local_identity() {
  if ! git config user.name >/dev/null; then
    git config user.name "Local Agent"
  fi
  if ! git config user.email >/dev/null; then
    git config user.email "local-agent@example.invalid"
  fi
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ "$init_approved" -ne 1 ]]; then
    cat <<'EOF'
这个文件夹还没有版本记录。我可以先记录当前状态，这样改错了可以回到现在这个版本。要我现在设置吗？
EOF
    exit 2
  fi

  git init -q
  ensure_local_identity
  git add -A
  git commit --allow-empty -q -m "$message"
  echo "已记录当前版本。"
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
ensure_local_identity

git add -A

git commit --allow-empty -q -m "$message"
echo "已记录当前版本。"
