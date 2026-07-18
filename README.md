# WeChat Linux（Docker 容器化）

一个将微信 Linux 客户端运行在 Docker 容器内的解决方案，支持通过 VNC/noVNC 或者本地端口访问界面。适合用于自动化机器人、消息备份、远程访问等场景。

快照：基于 Ubuntu + Fluxbox 的轻量桌面环境，使用 Xvfb 虚拟显示与 x11vnc 提供远程访问。

## 特性
- 通过 Docker 和 Docker Compose 快速部署
- 支持 VNC（可配合 noVNC 提供浏览器访问）
- 主目录卷挂载，保持微信配置、文件与下载持久化
- 可用于开发微信机器人或远程操作微信 GUI

## 快速开始

### 方式一：使用 Docker Compose（推荐）
1. 克隆并进入仓库
   ```bash
   git clone https://github.com/evvil/wechat_linux.git
   cd wechat_linux
   ```
2. 启动服务（后台）
   ```bash
   docker-compose up -d --build
   ```
3. 连接 VNC：
   - 地址：localhost:5900
   - 密码：默认 `wechat`（强烈建议在生产使用时修改）

### 方式二：直接拉取并运行镜像
```bash
docker pull risingwater/wechat-linux:latest

docker run -d --name wechat \
  -p 5900:5900 \
  -v $HOME/wechat_config:/home/wechat/.xwechat \
  -v $HOME/wechat_files:/home/wechat/xwechat_files \
  -v $HOME/wechat_downloads:/home/wechat/downloads \
  risingwater/wechat-linux:latest
```

## 常用环境变量（在 docker-compose 或 docker run 时设置）
- VNC_PASSWORD — VNC 访问密码（默认：wechat）
- DISPLAY_SIZE — 虚拟显示分辨率，示例：1280x720
- TZ — 容器时区，例如 Asia/Shanghai

示例 docker-compose.yml 中可通过 environment 覆盖这些变量。

## 数据与卷（持久化）
推荐在宿主机创建以下目录并映射：
- $HOME/wechat_config -> /home/wechat/.xwechat  （微信配置、聊天记录）
- $HOME/wechat_files  -> /home/wechat/xwechat_files（微信文件）
- $HOME/wechat_downloads -> /home/wechat/downloads（下载目录）

保证这些目录的权限正确（容器内运行用户有读取写入权限）。

## noVNC（通过浏览器访问）
项目可集成 noVNC 或者你可以自行部署一个 noVNC 服务并将其连接到容器的 VNC 端口。例如：
1. 启动 noVNC 容器，连接目标 VNC 地址 localhost:5900。
2. 在浏览器访问 noVNC 提供的 Web UI（通常是 http://<host>:6080）。

注意：若通过公网访问，请务必使用 HTTPS、认证或反向代理限制访问。

## 本地构建
```bash
git clone https://github.com/evvil/wechat_linux
cd wechat_linux

# 使用 Dockerfile 构建镜像
docker build -t wechat-linux:local .

# 运行
docker run -d --name wechat -p 5900:5900 \
  -v $HOME/wechat_config:/home/wechat/.xwechat \
  -v $HOME/wechat_files:/home/wechat/xwechat_files \
  -v $HOME/wechat_downloads:/home/wechat/downloads \
  wechat-linux:local
```

## 日志与故障排查
- 查看容器日志：docker logs wechat 或 docker-compose logs
- 容器内微信日志路径（示例）：/var/log/wechat/wechat.log
- 常见问题：
  - 无法连接 VNC：确认容器正在运行并且端口已映射（5900）
  - 微信崩溃或无法启动：检查依赖是否安装完整、Xvfb 是否运行
  - 权限问题：确保宿主机挂载目录的 UID/GID 与容器内运行用户兼容

## 升级镜像与数据备份
- 升级镜像：docker pull risingwater/wechat-linux:latest，然后重启容器（先备份数据卷）
- 备份：直接拷贝宿主机映射的目录或使用 docker cp 从容器拷贝配置文件

## 安全建议
- 不要在公网直接暴露 VNC 端口，建议通过 SSH 隧道或反向代理 + 认证访问
- 修改默认 VNC 密码并使用强密码
- 如果在生产环境运行自动化脚本，建议使用独立微信账号并遵守微信使用条款

## 开发者与贡献
欢迎提交 issue 或 PR；若要贡献，请遵循以下流程：
1. Fork 仓库并创建分支
2. 提交代码或文档修改并打开 PR
3. 描述变更与测试步骤

## 许可
本项目采用 MIT License，详见 LICENSE 文件。

## 致谢
基于社区原始方案构建并整理，感谢所有贡献者与原作者。
