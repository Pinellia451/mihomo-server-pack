#!/bin/bash
# mihomo proxy uninstaller
# Usage: bash uninstall.sh [--purge]
#
# This script will:
#   1. Stop mihomo if running
#   2. Remove shell aliases from ~/.zshrc and ~/.bashrc
#   3. Remove runtime files (logs, PID, cache DB, downloaded geo/rule files)
#
# Options:
#   --purge    Also remove the entire project directory (~/app/Proxy or current dir)
#              Without --purge, only runtime files are cleaned; source code is kept.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PURGE=false

# ---------- 解析参数 ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge)
            PURGE=true
            shift
            ;;
        *)
            echo "[!] Unknown option: $1"
            echo "Usage: bash uninstall.sh [--purge]"
            exit 1
            ;;
    esac
done

# ---------- 停止进程 ----------
echo "[*] Stopping mihomo ..."
pkill -f "mihomo-core.*-d.*$SCRIPT_DIR" 2>/dev/null && echo "[+] mihomo stopped" || echo "[-] mihomo not running"

# 等待进程退出
sleep 1
if pgrep -f "mihomo-core.*-d.*$SCRIPT_DIR" >/dev/null 2>&1; then
    echo "[*] Force killing mihomo ..."
    pkill -9 -f "mihomo-core.*-d.*$SCRIPT_DIR" 2>/dev/null || true
    sleep 1
fi

# ---------- 删除 shell aliases ----------
remove_aliases() {
    local rcfile="$1"
    if [ ! -f "$rcfile" ]; then
        return
    fi

    local changed=false

    # 删除 install.sh 写入的 alias 块（# mihomo proxy aliases ... 到空行）
    if grep -q "# mihomo proxy aliases" "$rcfile" 2>/dev/null; then
        sed -i '/^# mihomo proxy aliases$/,/^$/d' "$rcfile"
        changed=true
    fi

    # 删除旧版格式：# mihomo proxy + PROXY_DIR + alias 行到空行
    if grep -q "# mihomo proxy" "$rcfile" 2>/dev/null; then
        sed -i '/^# mihomo proxy$/,/^$/d' "$rcfile"
        changed=true
    fi

    # 清理残留的 PROXY_DIR 变量（可能没有被上面的范围覆盖）
    sed -i '/^PROXY_DIR=.*[Pp]roxy/d' "$rcfile"

    # 清理残留的 mihomo 相关 alias
    sed -i '/^alias m\(start\|stop\|restart\|status\|proxy\|unproxy\)=.*[Pp]roxy/d' "$rcfile"

    if [ "$changed" = true ]; then
        echo "[+] Removed aliases from $rcfile"
    fi
}

echo "[*] Removing shell aliases ..."
remove_aliases "$HOME/.zshrc"
remove_aliases "$HOME/.bashrc"

# ---------- 清理运行时文件 ----------
echo "[*] Cleaning runtime files ..."
RUNTIME_FILES=(
    "$SCRIPT_DIR/mihomo.pid"
    "$SCRIPT_DIR/mihomo.log"
    "$SCRIPT_DIR/cache.db"
)

# 下载的 geo 数据库（由 mihomo 自动更新）
GEO_FILES=(
    "$SCRIPT_DIR/geoip.dat"
    "$SCRIPT_DIR/geosite.dat"
)

# 缓存目录
CACHE_DIRS=(
    "$SCRIPT_DIR/proxies"
    "$SCRIPT_DIR/rule_providers"
)

for f in "${RUNTIME_FILES[@]}"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo "  removed: $(basename "$f")"
    fi
done

for f in "${GEO_FILES[@]}"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo "  removed: $(basename "$f")"
    fi
done

for d in "${CACHE_DIRS[@]}"; do
    if [ -d "$d" ]; then
        rm -rf "$d"
        echo "  removed: $(basename "$d")/"
    fi
done

# ---------- purge 模式：删除整个目录 ----------
if [ "$PURGE" = true ]; then
    echo ""
    echo "[!] --purge mode: removing entire project directory"
    echo "    $SCRIPT_DIR"
    echo ""
    read -rp "Are you sure? This cannot be undone. [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 删除前确保进程已停止
        pkill -9 -f "mihomo-core.*-d.*$SCRIPT_DIR" 2>/dev/null || true
        cd /
        rm -rf "$SCRIPT_DIR"
        echo "[+] Project directory removed"
    else
        echo "[-] Purge cancelled"
    fi
fi

# ---------- done ----------
echo ""
echo "=== Uninstall complete ==="
echo ""
if [ "$PURGE" = false ]; then
    echo "  Runtime files cleaned. Source code preserved at:"
    echo "    $SCRIPT_DIR"
    echo ""
    echo "  To fully remove everything, run:"
    echo "    bash $0 --purge"
fi
echo ""
echo "  Please run 'source ~/.zshrc' or start a new shell to clear aliases."
