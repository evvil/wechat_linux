#!/bin/bash
# 容器 PID 1：以 root 做目录准备，然后把整个图形会话交给 ubuntu(uid1000) 运行。
# 这样宿主挂载目录里生成的文件仍归 n100(uid1000)，且 Xwayland 的 X0 属主与客户端一致，无需 XAUTHORITY。
set -u

export DISPLAY=:0
RES="${RESOLUTION:-1024x768x24}"

echo "正在启动系统服务..."

# 必要的目录与权限
mkdir -p /var/run/dbus /var/lib/dbus /tmp/.X11-unix \
         /home/ubuntu/.xwechat /home/ubuntu/xwechat_files /home/ubuntu/downloads \
         /tmp/xdg-runtime
chmod 1777 /tmp/.X11-unix
# 注意：挂载目录在宿主上本就属 n100(uid1000)=容器 ubuntu(uid1000)，此处 chown 为幂等空操作
chown -R ubuntu:ubuntu /home/ubuntu /tmp/xdg-runtime
chmod 700 /tmp/xdg-runtime

# sway 配置：headless 输出分辨率 + 启用 Xwayland；X11 窗口浮动放置（近似原 fluxbox 行为）
CONF=/tmp/xdg-runtime/sway.conf
{
    echo "xwayland enable"
    # RESOLUTION=1024x768x24 -> 1024x768
    echo "output * resolution ${RES%x*}"
    echo 'for_window [shell="xwayland"] floating enable, border none'
} > "$CONF"
chown ubuntu:ubuntu "$CONF"

echo "- VNC: 0.0.0.0:${VNC_PORT:-5909} (wayvnc, RSA-AES 认证, 用户=${VNC_USERNAME:-wechat})"

# 整个图形会话以 ubuntu 身份跑（sway / wayvnc / wechat）
# su - 会清空环境，故显式透传 VNC 凭据相关变量
su - ubuntu -c "export RESOLUTION='$RES' VNC_USERNAME='${VNC_USERNAME:-wechat}' VNC_PASSWORD='${VNC_PASSWORD:-wechat}' VNC_PORT='${VNC_PORT:-5909}'; exec /usr/local/bin/session.sh" &
SESSION_PID=$!

sleep 8
echo "=========================================="
echo "所有系统服务已启动，VNC 端口: ${VNC_PORT:-5909} (wayvnc, RSA-AES 认证, 用户=${VNC_USERNAME:-wechat})"
echo "=========================================="

# 守护：会话退出则容器退出（compose restart: unless-stopped 会拉起）
while true; do
    if ! ps -p "$SESSION_PID" > /dev/null 2>&1; then
        echo "[守护进程] 图形会话已退出，容器停止"
        exit 1
    fi
    sleep 10
done
