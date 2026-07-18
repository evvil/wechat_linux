FROM ubuntu:26.04

# 合并环境变量设置
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    RESOLUTION=1024x768x24 \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# 一次性安装所有依赖并清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    xvfb \
    x11vnc \
    fluxbox \
    dbus-x11 \
    xorg \
    fonts-noto-cjk \
    procps \
    net-tools \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-render-util0 \
    libxcb-keysyms1 \
    locales \
    tzdata && \
    # 生成中文语言包
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    # 设置时区
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # 创建用户（无需设置密码，减少步骤）
    useradd -m -s /bin/bash wechat && \
    # 清理无用数据
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制并安装脚本
COPY scripts/install-wechat.sh scripts/start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wechat.sh /usr/local/bin/start.sh && \
    /usr/local/bin/install-wechat.sh && \
    rm /usr/local/bin/install-wechat.sh

WORKDIR /home/wechat
EXPOSE 5900
CMD ["/usr/local/bin/start.sh"]
#CMD ["/bin/bash"]