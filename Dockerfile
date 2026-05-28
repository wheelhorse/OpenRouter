FROM ubuntu:24.04

# Prevent apt from prompting for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# Update and install base tools needed to fetch the dependency list
RUN apt-get update && apt-get install -y curl wget sudo git locales

# Generate locale (prevents some perl/compile warnings)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Fetch and install the specific OpenWrt dependencies for Ubuntu 24.04
RUN apt-get install -y $(curl -fsSL https://raw.githubusercontent.com/ophub/amlogic-s9xxx-openwrt/refs/heads/main/make-openwrt/scripts/ubuntu2404-make-openwrt-depends)

# Set up the timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Clean up apt cache to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 already has a user with UID 1000 named 'ubuntu'.
# We rename it to 'builder', update its UID/GID to match the host user, and grant passwordless sudo.
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupmod -g ${USER_GID} ubuntu || true && \
    usermod -u ${USER_UID} -g ${USER_GID} ubuntu && \
    usermod -l builder ubuntu && \
    groupmod -n builder ubuntu && \
    usermod -d /home/builder -m builder && \
    chown -R builder:builder /home/builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Switch to the new user and set the working directory
USER builder
WORKDIR /workspace
