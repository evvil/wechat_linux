#!/bin/bash

# 确保必要的目录存在并具有正确权限
mkdir -p /var/run/dbus /var/log/wechat /home/wechat/.xwechat /home/wechat/xwechat_files
chown -R wechat:wechat /home/wechat /var/log/wechat

# 启动 DBus
mkdir -p /var/lib/dbus
dbus-uuidgen --ensure
dbus-daemon --system --fork --print-address &
sleep 1

# 启动虚拟屏幕 (Xvfb)
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset 2>&1 &
XVFB_PID=$!

# 启动轻量级窗口管理器
fluxbox 2>&1 &

# 启动 VNC 服务 (5900端口，设置密码为 wechat)
x11vnc -display $DISPLAY -forever -shared -passwd wechat -listen 0.0.0.0 2>&1 &
X11VNC_PID=$!

echo "服务已启动，VNC 端口: 5900 (密码: wechat)"

# 以 wechat 用户身份启动微信，将日志输出到控制台
su - wechat -c "export DISPLAY=$DISPLAY; wechat 2>&1" &
WECHAT_PID=$!

# 守护进程：如果关键服务退出，则重启或保持运行
while true; do
    if ! ps -p $XVFB_PID > /dev/null; then
        Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /dev/null 2>&1 &
        XVFB_PID=$!
    fi
    if ! ps -p $WECHAT_PID > /dev/null; then
        su - wechat -c "export DISPLAY=$DISPLAY; wechat 2>&1" &
        WECHAT_PID=$!
    fi
    sleep 10
done
