#!/bin/bash
# mihomo proxy launcher for Linux
# Usage: ./run.sh [--port PORT] {start|stop|restart|proxy|unproxy|status}
#        source run.sh proxy    (用 source 以设置环境变量)

SCRIPT_DIR="$HOME/app/Proxy"
MIHOMO="$SCRIPT_DIR/mihomo-core"
CONFIG="$SCRIPT_DIR/config.yaml"
PID_FILE="$SCRIPT_DIR/mihomo.pid"
LOG_FILE="$SCRIPT_DIR/mihomo.log"

# ---------- 检查 mihomo-core 是否存在 ----------
if [ ! -f "$MIHOMO" ]; then
    echo "[!] mihomo-core not found at $MIHOMO"
    echo "    Please re-clone or restore the binary."
    exit 1
fi

# ---------- 解析参数 ----------
PORT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            PORT="$2"; shift 2 ;;
        *) break ;;
    esac
done

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
    local run_config="$CONFIG"

    # 如果指定了 --port，生成临时配置覆盖 mixed-port
    if [ -n "$PORT" ]; then
        run_config="$SCRIPT_DIR/config.port.yaml"
        sed "s/mixed-port: [0-9]*/mixed-port: $PORT/" "$CONFIG" > "$run_config"
        echo "[*] Starting mihomo (port=$PORT) ..."
    else
        echo "[*] Starting mihomo ..."
    fi

    nohup "$MIHOMO" -d "$SCRIPT_DIR" -f "$run_config" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    local pid
    pid=$(cat "$PID_FILE")
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        local port
        port=$(get_proxy_port)
        echo "[+] mihomo started (pid=$pid)"
        echo "[+] mixed-port: $port"
        echo "[+] external-controller: 0.0.0.0:9011"
        echo "[+] WebUI: http://127.0.0.1:9011/ui"
    else
        echo "[!] mihomo failed to start, check $LOG_FILE"
        return 1
    fi
}

# ---------- 设置环境变量 ----------
get_proxy_port() {
    # 优先使用 --port 参数，其次从 config.yaml 读取
    if [ -n "$PORT" ]; then
        echo "$PORT"
        return
    fi
    local port
    port=$(grep -E "^mixed-port:" "$CONFIG" 2>/dev/null | awk '{print $2}')
    echo "${port:-7899}"
}

set_proxy() {
    local port
    port=$(get_proxy_port)
    export http_proxy="http://127.0.0.1:$port"
    export https_proxy="http://127.0.0.1:$port"
    export all_proxy="socks5://127.0.0.1:$port"
    export no_proxy="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
    echo "[+] Proxy env vars set (http/https -> 127.0.0.1:$port)"
}

unset_proxy() {
    unset http_proxy https_proxy all_proxy no_proxy
    echo "[+] Proxy env vars unset"
}

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
            echo "[+] Exit info:"
            if _exit_info=$(curl -sL --max-time 30 -x "http://127.0.0.1:$(get_proxy_port)" "https://my.ippure.com/v1/info" 2>&1); then
                echo "    $_exit_info"
            else
                echo "    [!] $_exit_info"
            fi
        else
            echo "[-] mihomo not running"
        fi
        ;;
    *)
        echo "Usage: $0 [--port PORT] {start|stop|restart|proxy|unproxy|status}"
        echo ""
        echo "  --port PORT  Override mixed-port (default: from config.yaml)"
        echo "  start        start mihomo in background"
        echo "  stop         stop mihomo"
        echo "  restart      restart mihomo"
        echo "  proxy        set http_proxy/https_proxy env vars"
        echo "  unproxy      unset proxy env vars"
        echo "  status       check if mihomo is running"
        ;;
esac
