FROM rockylinux:9

RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf update -y

RUN dnf groupinstall -y "Development Tools"

## curl is conflicting with curl-minimal
## curl-minimal is installed by default in Rocky Linux 9
## dnf is depending on curl-minimal so we can't remove it. use curl-minimal instead
RUN dnf install -y \
    clang \
    lld \
    llvm \
    cmake \
    git \
    # curl \ 
    file \
    unzip \
    nano \
    pkgconf-pkg-config \
    openssl-devel \
    zlib-devel \
    glibc-devel.i686 \
    libstdc++-devel.i686 \
    mingw64-gcc \
    binutils-aarch64-linux-gnu \
    && dnf clean all

    # mingw64-gcc \ # to install x86_64-w64-mingw32-strip
    # mingw64-gcc-c++ \
    # mingw64-winpthreads \
    # mingw64-headers\

# zig 설치
RUN curl -LO https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz && \
    tar -xf zig-linux-x86_64-0.14.0.tar.xz && \
    mv zig-linux-x86_64-0.14.0 /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-0.14.0.tar.xz
    
WORKDIR /workspace

CMD ["tail", "-f", "/dev/null"]
