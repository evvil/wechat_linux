# WeChat Linux Docker

Docker 容器化的微信 Linux 版解决方案，支持通过 VNC 远程访问微信界面。基于此方案可以进一步开发微信机器人、聊天记录备份等衍生功能。

## 快速开始

### 方式一：使用 Docker Compose（推荐）

```bash
docker-compose up -d
```

然后使用 VNC 客户端连接到：**localhost:5900**
- **VNC 密码**: `wechat`

或使用 noVNC 网页版（需自行配置，见下文）。

### 方式二：直接拉取镜像

```bash
docker pull risingwater/wechat-linux:latest
docker run -d -it -p 5900:5900 \
  -v $HOME/wechat_config:/home/wechat/.xwechat \
  -v $HOME/wechat_files:/home/wechat/xwechat_files \
  -v $HOME/wechat_downloads:/home/wechat/downloads \
  --name wechat \
  risingwater/wechat-linux:latest
```

## 本地构建

### 克隆项目

```bash
git clone https://github.com/evvil/wechat_linux
cd wechat_linux
```

### 方式一：使用 Docker Compose 构建并启动

```bash
docker-compose up -d --build
```

### 方式二：使用 Docker 命令构建

```bash
docker build ./ -t wechat-linux:latest
docker run -d -it -p 5900:5900 \
  -v $HOME/wechat_config:/home/wechat/.xwechat \
  -v $HOME/wechat_files:/home/wechat/xwechat_files \
  -v $HOME/wechat_downloads:/home/wechat/downloads \
  --name wechat \
  wechat-linux:latest
```

## 访问方式

### VNC 连接
使用任何 VNC 客户端连接到：
- **地址**: localhost:5900
- **密码**: wechat

### 推荐的 VNC 客户端
- **TigerVNC** - 高性能、跨平台
- **RealVNC** - 功能完整
- **VNC Viewer** - 官方工具

## 数据持久化

容器使用以下卷挂载来保存数据：

| 宿主机目录 | 容器内目录 | 说明 |
|-----------|------------|------|
| `$HOME/wechat_config` | `/home/wechat/.xwechat` | 微信配置和聊天记录 |
| `$HOME/wechat_files` | `/home/wechat/xwechat_files` | 微信文件存储 |
| `$HOME/wechat_downloads` | `/home/wechat/downloads` | 下载文件存储 |

## 日志

- 容器日志：`docker logs wechat` 或 `docker-compose logs`
- 微信应用日志：`/var/log/wechat/wechat.log`（容器内）
- 启动日志：包含 VNC 密码和端口信息

## 项目结构

```
wechat_linux/
├── Dockerfile                  # Docker 构建文件
├── docker-compose.yml          # Docker Compose 配置文件
├── scripts/                    # 启动脚本
│   ├── start.sh               # 容器启动脚本
│   └── install-wechat.sh      # 微信安装脚本
├── data/                       # 数据卷挂载点（docker-compose 使用）
├── README.md                   # 说明文档
└── LICENSE                     # MIT 许可证
```

## 技术栈

- **基础镜像**: Ubuntu 26.04
- **桌面环境**: Fluxbox
- **远程访问**: X11VNC（VNC 服务，密码: wechat）
- **显示服务**: Xvfb（虚拟显示）
- **容器编排**: Docker Compose

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE) 文件。
