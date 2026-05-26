# Dev Docker Registry

通过 Cloudflare Tunnel 把本地 Docker Registry 暴露到公网，一键 `docker compose up -d` 即可运行。

## 前提

- 一个由 Cloudflare 管理的域名
- 本机已安装 Docker

## 快速开始

### 1. 创建 Cloudflare Tunnel

打开 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels → Create a tunnel，复制 **token**。

### 2. 配置 Public Hostname

在 Tunnel 详情页 → Public Hostname → Add a public hostname：

| 字段 | 值 |
|---|---|
| Subdomain | `registry` |
| Domain | 你的域名 |
| Type | HTTP |
| URL | `registry:5000` |

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，粘贴 Cloudflare Tunnel Token
```

### 4. 启动

```bash
docker compose up -d
```

## 使用

### 推送镜像

```bash
docker login registry.yourdomain.com
docker tag myimage registry.yourdomain.com/myimage:v1
docker push registry.yourdomain.com/myimage:v1
```

### 拉取镜像

```bash
docker login registry.yourdomain.com
docker pull registry.yourdomain.com/myimage:v1
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

## 清理

```bash
docker compose down -v
```
