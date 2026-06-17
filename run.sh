#!/bin/bash
# mihomo proxy launcher for Linux
# Usage: source run.sh    (用 source 以设置环境变量)
#        ./run.sh          (仅启动代理，不设置环境变量)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIHOMO="$SCRIPT_DIR/mihomo-core"
CONFIG="$SCRIPT_DIR/config.yaml"
PID_FILE="$SCRIPT_DIR/mihomo.pid"
LOG_FILE="$SCRIPT_DIR/mihomo.log"

# ---------- 检查 mihomo-core 是否存在 ----------
if [ ! -f "$MIHOMO" ]; then
    echo "[!] mihomo-core not found. Download it first:"
    echo ""
    echo "    curl -L 'https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-v1-go120.gz' -o '$SCRIPT_DIR/mihomo-core.gz'"
    echo "    gunzip '$SCRIPT_DIR/mihomo-core.gz'"
    echo "    chmod +x '$SCRIPT_DIR/mihomo-core'"
    echo ""
    exit 1
fi

# ---------- 停止已有进程 ----------
stop_mihomo() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "[*] Stopping mihomo (pid=$pid) ..."
            kill "$pid"
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi
}

# ---------- 启动 ----------
start_mihomo() {
    stop_mihomo
    echo "[*] Starting mihomo ..."
    nohup "$MIHOMO" -d "$SCRIPT_DIR" -f "$CONFIG" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    local pid
    pid=$(cat "$PID_FILE")
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        echo "[+] mihomo started (pid=$pid)"
        echo "[+] mixed-port: 7899"
        echo "[+] external-controller: 0.0.0.0:9011"
        echo "[+] WebUI: http://127.0.0.1:9011/ui"
    else
        echo "[!] mihomo failed to start, check $LOG_FILE"
        return 1
    fi
}

# # ---------- 设置环境变量（这里逻辑好像有问题，弃用） ----------
# set_proxy() {
#     export http_proxy="http://127.0.0.1:7899"
#     export https_proxy="http://127.0.0.1:7899"
#     export all_proxy="socks5://127.0.0.1:7899"
#     export no_proxy="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
#     echo "[+] Proxy env vars set (http/https -> 127.0.0.1:7899)"
# }

# unset_proxy() {
#     unset http_proxy https_proxy all_proxy no_proxy
#     echo "[+] Proxy env vars unset"
# }

# ---------- 主逻辑 ----------
case "${1:-start}" in
    start)
        start_mihomo
        ;;
    stop)
        stop_mihomo
        echo "[+] mihomo stopped"
        ;;
    restart)
        start_mihomo
        ;;
    proxy)
        set_proxy
        ;;
    unproxy)
        unset_proxy
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "[+] mihomo running (pid=$(cat "$PID_FILE"))"
        else
            echo "[-] mihomo not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|proxy|unproxy|status}"
        echo ""
        echo "  start   - start mihomo in background"
        echo "  stop    - stop mihomo"
        echo "  restart - restart mihomo"
        echo "  proxy   - set http_proxy/https_proxy env vars"
        echo "  unproxy - unset proxy env vars"
        echo "  status  - check if mihomo is running"
        ;;
esac
