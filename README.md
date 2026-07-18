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

## noVNC（已从仓库移除）
注意：仓库中已故意移除了 noVNC 的实际配置与文件。README 中保留的 noVNC 相关说明仅作为集成参考，并不表示仓库包含 noVNC 的实现。

如果你需要将 noVNC 真正集成到项目中，我可以在新分支中添加一个可运行的 noVNC docker-compose 示例（包括如何通过 websockify/novnc 连接到 wechat 容器的 VNC 端口）并发起 PR。

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

说明：下面是我对本仓库 README 的改动摘要以及对原始作者（upstream）工作记录的简要说明，方便读者了解历史与差异。

- 我所做的 README 改动（2026-07-18, 提交者：Evvil）
  - 将 README 重构为更清晰的章节（特性、快速开始、环境变量、数据卷、noVNC、故障排查、备份、安全建议、贡献等）。
  - 在文档中注明仓库已移除 noVNC 的实际配置/文件（这是故意的删除），并把 noVNC 相关说明保留为集成参考。

- 上游/原作者与历史提交要点（摘选）
  - 初始化提交（init version）: b8fb433 — 作者显示为 王旭（wangxu），建立项目基础结构。
  - RisingWater 的维护提交（多次）: 包括更新 README、添加许可证、调整 Docker 工作流等（例如 4c7b45e、dc1ac64、4b7bbc5 等）。RisingWater 看起来是早期主要维护者/贡献者之一。
  - 我在此仓库的提交（Evvil）: 0c8b53e 等，用于扩展 README 内容并调整示例与说明。

- 关于 noVNC：
  - README 之前提及 noVNC，但仓库中并未包含 noVNC 的实际文件或配置（例如 noVNC 子模块、websockify、相关 Dockerfile 或 docker-compose 服务定义）。因此当前文档明确标注 noVNC 已被移除；若需要，我可以在新分支中添加实际集成示例。

- 建议
  - 若想把 noVNC 当作可直接运行的功能，建议添加一个 docker-compose 服务示例：
    - 使用 consol/novnc 或 novnc/noVNC 的镜像（或官方镜像），把 VNC_HOST/VNC_PORT 指向 wechat 容器的 5900 端口；并添加必要的安全配置（认证、HTTPS）示例。
  - 如需我代为实现，我会：
    1. 新建分支（例如 feat/novnc-compose），添加 docker-compose.yml 的 noVNC 服务示例和运行说明；
    2. 运行简单测试（本地或通过说明步骤）；
    3. 提交并打开 PR，描述变更与安全注意事项。

我已根据你的选择（直接在 main 上应用方案 A）更新并提交了 README.md。