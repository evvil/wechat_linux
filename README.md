# WeChat Linux（Docker 容器化）

一个将微信 Linux 客户端运行在 Docker 容器内的解决方案，支持通过 VNC/noVNC 或者本地端口访问界面。适合用于自动化机器人、消息备份、远程访问等场[...]

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

## noVNC（已从仓库移除）
注意：仓库中已故意移除了 noVNC 的实际配置与文件。README 中保留的 noVNC 相关说明仅作为集成参考，并不表示仓库包含 noVNC 的实现。

如果你需要将 noVNC 真正集成到项目中，我可以在新分支中添加一个可运行的 noVNC docker-compose 示例（包括如何通过 websockify/novnc 连接到 wechat 容器的 VN[...]

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

---

## 与原作者的对比（补充说明）

说明：下面是对最近三个提交的摘要，帮助读者快速了解本仓库相对于上游（原作者/早期维护者）的主要变更。

- 提交 946a69db6c1ef4ce430162c6f0b85c5fdf27459e — "[ubuntu] upgrade to 26" (2026-07-18)
  - 概要：将基础镜像从 ubuntu:22.04 升级到 ubuntu:26.04；合并并优化了环境变量和包安装步骤；移除或简化了 noVNC 的相关安装与启动；将微信安装与启动脚本的复制与执行整合到 Dockerfile 中；将暴露端口调整为 5900 并以 start 脚本作为容器入口。
  - 影响：镜像基础系统更新为更高版本（可能带来更好的包支持与安全更新）；同时简化镜像构建流程和运行时脚本，减少了在容器内对残留文件和复杂启动顺序的处理。

- 提交 4d5dadfa0f8b67157051df6c6f6c04a3ea230de5 — "[compose] add compose" (2026-07-18)
  - 概要：为项目添加 docker-compose.yml 示例并在 Dockerfile 中声明持久化卷（VOLUME）；补充了一些运行时依赖（如 dbus 等库）；对 start.sh 做了小幅调整以简化日志重定向与启动行为；暴露并默认映射 VNC 端口。
  - 影响：为用户提供更便捷的一键启动方式（docker-compose）；明确声明要挂载的数据卷位置，便于数据持久化与备份；补强了运行时的依赖声明，降低容器运行时缺少库导致的问题。

- 提交 2a5f2384b50c26bad48af6f288351da8d0da6b61 — "[compose] add compose" (2026-07-18)
  - 概要：添加 .gitignore（忽略 data/）；调整 docker-compose.yml 中的默认挂载路径为 ./data/ 下的目录（更清晰地将运行数据集中到 data/）；对 start.sh 中的守护循环（自动重启逻辑）进行了注释/停用，改为更简单的前台运行模式；微调 compose 配置（注释掉 user 设置等）。
  - 影响：将默认本地数据目录集中到仓库下的 data/ 目录，便于示例与本地测试；减少容器内的后台守护行为，便于调试与容器化系统对进程的管理（容器通常期望主进程在前台运行以便 Docker 管理）。

总体评价与建议：
- 这三次提交以实用性和可维护性为主线：升级基础镜像、简化启动脚本、补充 compose 支持并规范数据目录。若你依赖 noVNC 的浏览器访问功能，需要注意当前分支已移除或未启用 noVNC 的完整实现（可以在单独分支中再行集成）。
- 建议在升级基础镜像后进行一次完整的 CI 构建与运行测试，验证在 Ubuntu 26.04 下所有依赖（尤其是微信二进制所需的库）都能正常工作。若需要，我可以为你：
  1) 在新分支添加完整的 noVNC compose 示例并做基本测试；
  2) 添加一个基于 GitHub Actions 的简单构建+lint 流程以自动化验证镜像能否构建并运行基本启动脚本。

我已将上述摘要替换到 README 的“与原作者的对比（补充说明）”部分。如需我把这些变更单独放到一个 commit 或分支（而非直接修改 main README），我可以创建一个分支并提交变更.