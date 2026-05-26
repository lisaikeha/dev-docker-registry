# Dev Docker Registry

本地 Docker Registry，可选通过 Cloudflare Tunnel 暴露到公网。

## 前提

- 本机已安装 Docker
- （可选）一个由 Cloudflare 管理的域名

## 快速开始

### 1. 配置环境变量

```bash
cp .env.example .env   # 或直接编辑 .env
```

`.env` 中的变量：

| 变量 | 必填 | 说明 |
|---|---|---|
| `REGISTRY_USER` | 否 | cleanup 服务认证用户名 |
| `REGISTRY_PASS` | 否 | cleanup 服务认证密码 |
| `TUNNEL_TOKEN` | 否 | Cloudflare Tunnel token（启用 tunnel 时填写） |

### 2. 启动

```bash
# 仅启动 Registry（本地使用）
docker compose up -d

# 如需通过公网访问，加上 cloudflare profile
docker compose --profile cloudflare up -d
```

### 3. （可选）配置 Cloudflare Tunnel

如需公网访问，先创建 Cloudflare Tunnel：

1. 打开 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels → Create a tunnel，复制 **token**
2. 在 Tunnel 详情页 → Public Hostname → Add a public hostname：

| 字段 | 值 |
|---|---|
| Subdomain | `registry` |
| Domain | 你的域名 |
| Type | HTTP |
| URL | `registry:5000` |

3. 把 token 填入 `.env` 的 `TUNNEL_TOKEN`，然后通过 profile 启动：

```bash
docker compose --profile cloudflare up -d
```

## 使用

### 登录

```bash
# 本地
docker login localhost:5000

# 公网（需启用 cloudflare profile）
docker login registry.yourdomain.com
```

### 推送 & 拉取

```bash
docker tag myimage localhost:5000/myimage:v1
docker push localhost:5000/myimage:v1
docker pull localhost:5000/myimage:v1
```

## 管理用户

Registry 默认已配置 `htpasswd` 认证，未登录无法拉取或推送。

```bash
# 添加用户
./auth.sh add <username> <password>

# 删除用户
./auth.sh rm <username>
```

添加或删除用户后需重启 Registry 使其生效：

```bash
docker compose restart registry
```

## 自动清理

反复 push 同一 tag 会导致旧 manifest 和 layer 累积占用磁盘。`registry-cleanup` 服务每天定时清理：

1. 通过 API 删除所有无 tag 引用的旧 manifest
2. 执行 GC 回收无引用的 layer blob

手动触发清理：

```bash
docker exec registry-cleanup /cleanup.sh
```

清理服务需要 Registry 认证凭据，请在 `.env` 中配置 `REGISTRY_USER` 和 `REGISTRY_PASS`。

## 停止

```bash
docker compose --profile cloudflare down
```
