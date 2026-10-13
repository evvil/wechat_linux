#!/bin/bash
# 以 ubuntu(uid1000) 身份运行：sway(headless) -> wayvnc(VNC:5909, RSA-AES 认证) -> wechat
set -u

export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/xdg-runtime
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export XDG_SESSION_TYPE=wayland
export WLR_BACKENDS=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
unset XAUTHORITY

# VNC 凭据：可用环境变量覆盖
VNC_USERNAME="${VNC_USERNAME:-wechat}"
VNC_PASSWORD="${VNC_PASSWORD:-wechat}"
VNC_PORT="${VNC_PORT:-5909}"

echo "- 启动 sway (headless, Xwayland)"
sway --unsupported-gpu -c "$XDG_RUNTIME_DIR/sway.conf" 2>&1 &
SWAY_PID=$!
sleep 5

if ! ps -p "$SWAY_PID" > /dev/null 2>&1; then
    echo "- 错误: sway 启动失败"
    exit 1
fi
echo "- sway 状态: 运行中 (PID: $SWAY_PID)"

# 自动探测 sway 创建的 wayland socket（编号由合成器分配，勿硬编码）
WL=$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | grep -v '\.lock$' | head -1)
if [ -z "$WL" ]; then
    echo "- 错误: 未找到 wayland socket"
    exit 1
fi
export WAYLAND_DISPLAY=$(basename "$WL")
echo "- WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# wayvnc RSA-AES 认证配置（密钥在镜像构建时生成于 /etc/wayvnc/rsa_key.pem）
# 说明：wayvnc 0.9.x 只支持 RSA-AES(RA2/RA2_256) 与 Apple-DH，不支持经典 VNC 密码(type 2)。
VNC_CONF="$XDG_RUNTIME_DIR/wayvnc.conf"
{
    echo "address=0.0.0.0"
    echo "port=$VNC_PORT"
    echo "enable_auth=true"
    echo "username=$VNC_USERNAME"
    echo "password=$VNC_PASSWORD"
    echo "rsa_private_key_file=/etc/wayvnc/rsa_key.pem"
} > "$VNC_CONF"
chmod 600 "$VNC_CONF"

echo "- 启动 wayvnc (0.0.0.0:$VNC_PORT, RSA-AES 认证, 用户=$VNC_USERNAME)"
wayvnc --config="$VNC_CONF" 2>&1 &
WAYVNC_PID=$!
sleep 3
if ps -p "$WAYVNC_PID" > /dev/null 2>&1; then
    echo "- wayvnc 状态: 运行中 (PID: $WAYVNC_PID)"
else
    echo "- 错误: wayvnc 启动失败"
fi

echo "- 正在以 ubuntu 用户身份启动微信..."
wechat 2>&1 &
WECHAT_PID=$!
sleep 6
if ps -p "$WECHAT_PID" > /dev/null 2>&1; then
    echo "- 微信启动成功 (PID: $WECHAT_PID)"
else
    echo "- 错误: 微信启动失败，请检查上方日志"
fi

# 任一后台任务结束即退出，交给外层守护判断
wait -n "$SWAY_PID" "$WAYVNC_PID" "$WECHAT_PID"
