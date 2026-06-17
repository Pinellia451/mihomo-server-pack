# mihomo 代理配置

开箱即用的 [mihomo](https://github.com/MetaCubeX/mihomo)（Clash Meta）代理配置，适用于 Linux。

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/<your-username>/Proxy.git
cd Proxy
```

### 2. 下载 mihomo-core

```bash
curl -L 'https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-v1-go120.gz' -o mihomo-core.gz
gunzip mihomo-core.gz
chmod +x mihomo-core
```

前往 [MetaCubeX/mihomo releases](https://github.com/MetaCubeX/mihomo/releases) 查看最新版本。

### 3. 配置订阅

```bash
cp config.example.yaml config.yaml
```

编辑 `config.yaml`，在 `proxy-providers` 部分填入你的机场订阅链接：

```yaml
proxy-providers:
  my-provider:
    <<: *providers_common
    url: "https://your-subscription-url?clash=1"
    path: ./proxies/my-provider.yaml
```

### 4. 启动

```bash
./run.sh start
```

## 使用方法

### run.sh 命令

```bash
./run.sh start      # 启动 mihomo（后台运行）
./run.sh stop       # 停止 mihomo
./run.sh restart    # 重启
./run.sh status     # 查看运行状态
```

### 设置终端代理

在当前 shell 中启用代理：

```bash
# 方法一：使用 vpn 函数（见下方 Shell 配置）
vpn 7899

# 方法二：手动设置
export http_proxy="http://localhost:7899"
export https_proxy="http://localhost:7899"
```

取消代理：

```bash
unvpn
# 或
unset http_proxy https_proxy
```

### WebUI

启动后访问 WebUI 管理面板：

```
http://127.0.0.1:9011/ui
```

密钥见 `config.yaml` 中的 `secret` 字段。

## Shell 配置

将以下内容添加到 `~/.zshrc`（或 `~/.bashrc`），可以获得快捷命令和灵活的代理切换功能：

```bash
# ---- mihomo 快捷命令 ----
PROXY_DIR="/path/to/your/Proxy"  # 改为你的实际路径
alias mstart="$PROXY_DIR/run.sh start"
alias mstop="$PROXY_DIR/run.sh stop"
alias mrestart="$PROXY_DIR/run.sh restart"
alias mstatus="$PROXY_DIR/run.sh status"

# ---- 通用代理切换 ----
# vpn [端口号] —— 设置终端代理，默认端口 9999
vpn() {
  local port=${1:-9999}
  export http_proxy="http://localhost:${port}"
  export https_proxy="http://localhost:${port}"
  echo "Proxy has been set to localhost:${port}"
}

# unvpn —— 取消终端代理
unvpn() {
  unset http_proxy https_proxy
  echo "Proxy has been disabled"
}
```

添加后执行 `source ~/.zshrc` 使其生效。

**使用示例：**

```bash
mstart          # 启动 mihomo
vpn 7899        # 设置终端代理指向 mihomo 的 mixed-port
# ... 正常上网 ...
unvpn           # 取消代理
mstop           # 停止 mihomo
```

## 项目结构

```
.
├── config.example.yaml   # 配置模板（复制为 config.yaml 后使用）
├── run.sh                # 启动脚本
├── rules/                # 自定义规则文件（自动从远程更新）
├── rule_providers/       # 规则集（自动下载）
├── proxies/              # 代理节点缓存（自动下载）
├── WebUI/MetacubeXD/     # WebUI 前端
├── geoip.dat             # GeoIP 数据库（自动更新）
└── geosite.dat           # GeoSite 数据库（自动更新）
```

> 运行时还会生成 `mihomo-core`（二进制）、`config.yaml`（个人配置）、`mihomo.log`、`mihomo.pid`、`cache.db` 等文件，已在 `.gitignore` 中排除。

## 配置要点

- **代理模式**：系统代理（mixed-port 7899），未启用 TUN
- **DNS**：fake-ip 模式，国内走 AliDNS / Tencent，国外走 Cloudflare / Google
- **节点分组**：按地区自动分类（美国、香港、日本、新加坡、台湾），支持负载均衡
- **规则**：自定义规则 + GeoIP/GEOSITE + 广告拦截，最后 `MATCH` 兜底走代理

## 许可

MIT
