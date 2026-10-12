#!/bin/bash

export DISPLAY=:0
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# 确保必要的目录存在并具有正确权限
mkdir -p /var/run/dbus /var/lib/dbus /var/log/ubuntu /home/ubuntu/.xwechat /home/ubuntu/xwechat_files /home/ubuntu/downloads
chown -R ubuntu:ubuntu /home/ubuntu /var/log/ubuntu

echo "正在启动系统服务..."

# weixin自己会启动dbus，所以这里不需要再启动dbus了
# # 1. 启动 DBus
# dbus-uuidgen --ensure
# dbus-daemon --system --fork --print-address
# DBUS_PID=$(pgrep -f dbus-daemon)
# sleep 2
# echo "- DBus 状态: $([ -n "$DBUS_PID" ] && ps -p $DBUS_PID > /dev/null && echo '运行中' || echo '启动失败')"

# 2. 启动虚拟屏幕 (Xvfb)
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset 2>&1 &
XVFB_PID=$!
sleep 3
echo "- Xvfb 状态: $(ps -p $XVFB_PID > /dev/null && echo '运行中' || echo '启动失败')"

# 3. 启动窗口管理器 (fluxbox)
fluxbox 2>&1 &
FLUXBOX_PID=$!
sleep 2
echo "- Fluxbox 状态: $(ps -p $FLUXBOX_PID > /dev/null && echo '运行中' || echo '启动失败')"

# 4. 启动 VNC 服务
x11vnc -display $DISPLAY -forever -shared -passwd wechat -listen 0.0.0.0 -rfbport 5909 -noscr -noxkb -wait 50 -defer 50 -noxdamage 2>&1 &
X11VNC_PID=$!
sleep 2
echo "- x11vnc 状态: $(ps -p $X11VNC_PID > /dev/null && echo '运行中' || echo '启动失败')"

echo "=========================================="
echo "所有系统服务已启动，VNC 端口: 5900 (密码: wechat)"
echo "=========================================="

# 定义启动微信的函数
start_wechat() {
    echo "正在以 ubuntu 用户身份启动微信..."
    # 传递 DISPLAY 环境变量，并重定向输出到控制台
    su - ubuntu -c "export DISPLAY=$DISPLAY; export GDK_BACKEND=x11; export QT_QPA_PLATFORM=xcb; wechat 2>&1" &
    WECHAT_PID=$!
    sleep 5
    if ps -p $WECHAT_PID > /dev/null; then
        echo "- 微信启动成功 (PID: $WECHAT_PID)"
    else
        echo "- 错误: 微信启动失败，请检查上方日志"
    fi
}

start_wechat

# 守护进程：循环检查关键服务
while true; do
    # 检查 Xvfb
    # if ! ps -p $XVFB_PID > /dev/null; then
    #     echo "[守护进程] 检测到 Xvfb 已退出，正在重启..."
    #     Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset 2>&1 &
    #     XVFB_PID=$!
    #     sleep 2
    # fi
    
    # # 检查微信
    # if ! ps -p $WECHAT_PID > /dev/null; then
    #     echo "[守护进程] 检测到微信已退出，正在尝试重启..."
    #     start_wechat
    # fi
    
    sleep 1000
done
