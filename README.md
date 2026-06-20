# mihomo 代理配置

开箱即用的 [mihomo](https://github.com/MetaCubeX/mihomo)（Clash Meta）代理配置，适用于 Linux。

## 一键安装

```bash
# 使用默认端口 7899
curl -sL https://raw.githubusercontent.com/Pinellia451/mihomo-server-pack/master/install.sh | bash

# 指定自定义端口
curl -sL https://raw.githubusercontent.com/Pinellia451/mihomo-server-pack/master/install.sh | bash -s -- --port 8080
```

安装脚本会自动：
1. 克隆仓库到 `~/app/Proxy`
2. 创建配置文件
3. 设置执行权限
4. 添加 Shell 别名

## 快速开始（手动安装）

### 1. 克隆仓库

```bash
git clone https://github.com/Pinellia451/mihomo-server-pack.git ~/app/Proxy
cd ~/app/Proxy
```

### 2. 配置订阅

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

**配置说明：**

1. **获取订阅链接**：从你的机场/代理服务提供商获取 Clash 订阅链接（通常以 `?clash=1` 结尾）
2. **替换 url**：将 `url` 字段替换为你的实际订阅链接
3. **多个订阅**：可以添加多个 provider，每个使用不同的名称

**示例（多个订阅）：**

```yaml
proxy-providers:
  provider-1:
    <<: *providers_common
    url: "https://example1.com/sub?clash=1"
    path: ./proxies/provider-1.yaml
  
  provider-2:
    <<: *providers_common
    url: "https://example2.com/sub?clash=1"
    path: ./proxies/provider-2.yaml
```

**注意事项：**
- 订阅链接必须支持 Clash 格式
- 路径 `path` 用于缓存订阅文件，保持默认即可
- 配置完成后运行 `mstart` 启动代理

### 3. 启动

```bash
./run.sh start
```

## 使用方法

### Shell 别名

安装后自动添加以下别名（需执行 `source ~/.zshrc` 或 `source ~/.bashrc`）：

| 别名 | 功能 |
|------|------|
| `mstart` | 启动代理 |
| `mstop` | 停止代理 |
| `mrestart` | 重启代理 |
| `mstatus` | 查看状态 |
| `mproxy` | 设置代理环境变量 |
| `munproxy` | 取消代理环境变量 |

**使用示例：**

```bash
mstart          # 启动 mihomo
mproxy          # 设置终端代理
# ... 正常上网 ...
munproxy        # 取消代理
mstop           # 停止 mihomo
```

### run.sh 命令

```bash
./run.sh start      # 启动 mihomo（后台运行）
./run.sh stop       # 停止 mihomo
./run.sh restart    # 重启
./run.sh status     # 查看运行状态
./run.sh proxy      # 设置代理环境变量
./run.sh unproxy    # 取消代理环境变量
```

### WebUI

启动后访问 WebUI 管理面板：

```
http://127.0.0.1:9011/ui
```

默认密钥：`passwd`

> 密钥可在 `config.yaml` 的 `secret` 字段中修改。

## 代理端口配置

默认端口为 `7899`，可通过以下方式修改：

### 方式一：安装时指定

```bash
curl -sL https://raw.githubusercontent.com/Pinellia451/mihomo-server-pack/master/install.sh | bash -s -- --port 8080
```

### 方式二：修改配置文件

编辑 `config.yaml`：

```yaml
mixed-port: 8080
```

然后重启代理：

```bash
mrestart
```

`mproxy` 会自动读取配置文件中的端口，无需手动修改。

## vscode 配置

设置项 json：

```json
{
    "http.noProxy": [
        "http://127.0.0.1:7899"
    ],
    "http.proxy": "http://127.0.0.1:7899"
}
```

这样扩展也可以走代理，包括 codex 插件。

## 项目结构

```
.
├── install.sh            # 一键安装脚本
├── config.example.yaml   # 配置模板（复制为 config.yaml 后使用）
├── run.sh                # 启动脚本
├── mihomo-core           # mihomo 二进制文件
├── rules/                # 自定义规则文件（自动从远程更新）
├── rule_providers/       # 规则集（自动下载）
├── proxies/              # 代理节点缓存（自动下载）
├── WebUI/MetacubeXD/     # WebUI 前端
├── geoip.dat             # GeoIP 数据库（自动更新）
└── geosite.dat           # GeoSite 数据库（自动更新）
```

> 运行时还会生成 `config.yaml`（个人配置）、`mihomo.log`、`mihomo.pid`、`cache.db` 等文件，已在 `.gitignore` 中排除。

## 配置要点

- **代理模式**：系统代理（mixed-port 7899），未启用 TUN
- **DNS**：fake-ip 模式，国内走 AliDNS / Tencent，国外走 Cloudflare / Google
- **节点分组**：按地区自动分类（美国、香港、日本、新加坡、台湾），支持负载均衡
- **规则**：自定义规则 + GeoIP/GEOSITE + 广告拦截，最后 `MATCH` 兜底走代理

## 许可

MIT
