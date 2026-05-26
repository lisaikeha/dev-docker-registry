#!/bin/bash
# 管理 Registry 用户
# 用法:
#   ./auth.sh add <username> <password>
#   ./auth.sh rm  <username>

set -e

HTPASSWD_FILE="$(dirname "$0")/auth/htpasswd"

case "${1:-}" in
  add)
    username="${2:?用法: $0 add <username> <password>}"
    password="${3:?用法: $0 add <username> <password>}"
    if [ -f "$HTPASSWD_FILE" ]; then
      docker run --rm -v "$(realpath "$HTPASSWD_FILE"):/htpasswd" httpd:2.4-alpine \
        htpasswd -Bb /htpasswd "$username" "$password"
    else
      docker run --rm httpd:2.4-alpine \
        htpasswd -Bbn "$username" "$password" > "$HTPASSWD_FILE"
    fi
    echo "用户 $username 已添加"
    ;;

  rm)
    username="${2:?用法: $0 rm <username>}"
    docker run --rm -v "$HTPASSWD_FILE:/htpasswd" httpd:2.4-alpine \
      htpasswd -D /htpasswd "$username"
    echo "用户 $username 已删除"
    ;;

  *)
    echo "用法: $0 {add|rm} <username> [password]"
    exit 1
    ;;
esac
