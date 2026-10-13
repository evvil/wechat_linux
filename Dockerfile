FROM ubuntu:26.04

# 合并环境变量设置
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    RESOLUTION=1024x768x24 \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# 华为镜像提速（archive.ubuntu.com 在本机单层 5 分钟跑不完）。
# 注意：ubuntu:26.04 基础镜像默认无 ca-certificates，只能走 http。
RUN sed -i "s|http://archive.ubuntu.com/ubuntu|http://mirrors.huaweicloud.com/ubuntu|g; s|http://security.ubuntu.com/ubuntu|http://mirrors.huaweicloud.com/ubuntu|g" \
        /etc/apt/sources.list.d/ubuntu.sources

# 一次性安装所有依赖并清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    # 构建时生成 wayvnc 的 RSA-AES 私钥所需
    openssh-client \
    dbus \
    dbus-x11 \
    fonts-noto-cjk \
    procps \
    net-tools \
    # Wayland 合成器 + VNC：sway 属 wlroots 系，是 wayvnc 官方唯一支持的合成器类型。
    # xwayland 必备：微信小程序 runtime(WeChatAppEx) 静态链接 libX11 等 X 库，纯 Wayland 会黑屏。
    sway \
    wayvnc \
    xwayland \
    # wayland 客户端库。微信主进程 /opt/wechat/wechat 会 dlopen
    # "libwayland-egl.so.1" 与 "libwayland-cursor.so.0"，缺库时 GPU 进程直接退出：
    #   "Wayland EGL stub: dlopen(libwayland-egl.so.1) failed"
    #   -> "[E] viz_main_impl.cc Exiting GPU process due to errors during initialization"
    libwayland-client0 \
    libwayland-server0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    # WeChatAppEx(小程序 runtime) 直接依赖的 X 库；原先由 xorg 间接带入，改用 sway 后需显式声明
    libxcomposite1 \
    libxdamage1 \
    libcups2t64 \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-render-util0 \
    libxcb-keysyms1 \
    libpulse0 \
    libnss3 \
    libatk1.0-0t64 \
    libatk-bridge2.0-0t64 \
    libasound2t64 \
    locales \
    tzdata && \
    # 生成中文语言包
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    # 设置时区
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # 清理无用数据
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制并安装脚本
COPY scripts/install-wechat.sh scripts/start.sh scripts/session.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wechat.sh /usr/local/bin/start.sh /usr/local/bin/session.sh && \
    /usr/local/bin/install-wechat.sh && \
    apt-get install -f -y && \
    rm /usr/local/bin/install-wechat.sh

# 生成 wayvnc RSA-AES 认证私钥（构建时固定，容器每次重建后客户端需重新确认一次指纹）
# wayvnc 以 ubuntu 身份运行，故私钥需 ubuntu 可读
RUN mkdir -p /etc/wayvnc && \
    ssh-keygen -m pem -f /etc/wayvnc/rsa_key.pem -t rsa -N "" -q && \
    chown ubuntu:ubuntu /etc/wayvnc/rsa_key.pem && \
    chmod 600 /etc/wayvnc/rsa_key.pem

WORKDIR /home/ubuntu

# 声明数据卷
VOLUME ["/home/ubuntu/.xwechat", "/home/ubuntu/xwechat_files", "/home/ubuntu/downloads"]

EXPOSE 5909
CMD ["/usr/local/bin/start.sh"]
#CMD ["/bin/bash"]
