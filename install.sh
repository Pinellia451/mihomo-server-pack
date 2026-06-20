#!/bin/bash
# One-click installer for mihomo proxy
# Usage: bash install.sh [--port PORT]
#
# This script will:
#   1. Clone the repo to ~/app/Proxy
#   2. Copy config.example.yaml -> config.yaml (if not exists)
#   3. Set permissions on mihomo-core
#   4. Append shell aliases to ~/.zshrc (if not already present)
#      - mstart/mstop/mrestart/mstatus: proxy management
#      - mproxy/munproxy: set/unset proxy env vars
#
# Options:
#   --port PORT    Set proxy port (default: 7899)

set -e

REPO_URL="https://github.com/Pinellia451/mihomo-server-pack.git"
INSTALL_DIR="$HOME/app/Proxy"
PROXY_PORT=7899

# ---------- 解析参数 ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ ]]; then
                echo "[!] --port requires a numeric argument"
                exit 1
            fi
            PROXY_PORT="$2"
            shift 2
            ;;
        *)
            echo "[!] Unknown option: $1"
            echo "Usage: bash install.sh [--port PORT]"
            exit 1
            ;;
    esac
done

echo "[*] Using proxy port: $PROXY_PORT"

# ---------- 前置检查 ----------
for cmd in git; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "[!] '$cmd' is required but not installed."
        exit 1
    fi
done

# 检查系统和架构
if [ "$(uname -s)" != "Linux" ]; then
    echo "[!] This installer is for Linux only. Detected: $(uname -s)"
    exit 1
fi

if [ "$(uname -m)" != "x86_64" ]; then
    echo "[!] mihomo-core is built for x86_64. Detected: $(uname -m)"
    exit 1
fi

# ---------- clone ----------
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "[*] Repo already exists at $INSTALL_DIR, pulling latest ..."
    if ! git -C "$INSTALL_DIR" pull --ff-only; then
        echo "[!] git pull failed (local changes conflict?). Aborting."
        echo "    Resolve manually: cd $INSTALL_DIR && git status"
        exit 1
    fi
else
    echo "[*] Cloning repo to $INSTALL_DIR ..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# ---------- config ----------
if [ ! -f config.yaml ]; then
    if [ -f config.example.yaml ]; then
        cp config.example.yaml config.yaml
        echo "[+] Created config.yaml from config.example.yaml"
        echo "[!] Edit config.yaml and fill in your subscription link before starting."
    else
        echo "[!] No config.example.yaml found — you must create config.yaml manually."
    fi
else
    echo "[*] config.yaml already exists, skipping."
fi

# 更新配置文件中的端口
if [ -f config.yaml ]; then
    sed -i "s/mixed-port: [0-9]*/mixed-port: $PROXY_PORT/" config.yaml
    echo "[+] Updated config.yaml mixed-port to $PROXY_PORT"
fi

# ---------- 权限 ----------
chmod +x mihomo-core
echo "[+] Set mihomo-core executable"

# ---------- shell aliases ----------
install_aliases() {
    local rcfile="$1"
    local block='# mihomo proxy aliases
alias mstart="~/app/Proxy/run.sh start"
alias mstop="~/app/Proxy/run.sh stop"
alias mrestart="~/app/Proxy/run.sh restart"
alias mstatus="~/app/Proxy/run.sh status"
alias mproxy="source ~/app/Proxy/run.sh proxy"
alias munproxy="source ~/app/Proxy/run.sh unproxy"'

    touch "$rcfile"
    if grep -q "mproxy" "$rcfile"; then
        echo "[*] Aliases already in $rcfile, skipping."
    else
        echo "" >> "$rcfile"
        echo "$block" >> "$rcfile"
        echo "[+] Added aliases to $rcfile (mstart/mstop/mrestart/mstatus/mproxy/munproxy)"
    fi
}

# 检测当前 shell，写入对应的 rc 文件
case "$(basename "$SHELL")" in
    zsh)  install_aliases "$HOME/.zshrc" ;;
    bash) install_aliases "$HOME/.bashrc" ;;
    *)
        # fallback：两个都存在就都写
        [ -f "$HOME/.zshrc" ]  && install_aliases "$HOME/.zshrc"
        [ -f "$HOME/.bashrc" ] && install_aliases "$HOME/.bashrc"
        # 一个都没有就默认 zsh
        [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ] && install_aliases "$HOME/.zshrc"
        ;;
esac

# ---------- done ----------
echo ""
echo "=== Installation complete ==="
echo ""
echo "  Proxy port: $PROXY_PORT"
echo ""
echo "  1. Edit config:   vim $INSTALL_DIR/config.yaml"
echo "  2. Start proxy:   $INSTALL_DIR/run.sh start"
echo "  3. Set env vars:  source $INSTALL_DIR/run.sh proxy"
echo "  4. WebUI:         http://127.0.0.1:9011/ui"
echo ""
echo "  Or use aliases (after 'source ~/.zshrc' or 'source ~/.bashrc'):"
echo "    mstart / mstop / mrestart / mstatus / mproxy / munproxy"
