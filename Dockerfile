
#Download base image ubuntu 16.04
FROM ubuntu:16.04

# Make sure apt-get is up to date and dependent packages are installed
RUN \
  apt-get update && \
  apt-get install -y automake autogen build-essential ca-certificates                    \
    gcc-5-arm-linux-gnueabi g++-5-arm-linux-gnueabi libc6-dev-armel-cross                \
    gcc-5-arm-linux-gnueabihf g++-5-arm-linux-gnueabihf libc6-dev-armhf-cross            \
    gcc-5-aarch64-linux-gnu g++-5-aarch64-linux-gnu libc6-dev-arm64-cross                \
    gcc-5-mips-linux-gnu g++-5-mips-linux-gnu libc6-dev-mips-cross                       \
    gcc-5-mipsel-linux-gnu g++-5-mipsel-linux-gnu libc6-dev-mipsel-cross                 \
    gcc-5-mips64-linux-gnuabi64 g++-5-mips64-linux-gnuabi64 libc6-dev-mips64-cross       \
    gcc-5-mips64el-linux-gnuabi64 g++-5-mips64el-linux-gnuabi64 libc6-dev-mips64el-cross \
    gcc-5-multilib g++-5-multilib gcc-mingw-w64 g++-mingw-w64 clang llvm-dev             \
    libtool libxml2-dev uuid-dev libssl-dev swig openjdk-8-jdk pkg-config patch          \
    make xz-utils cpio  zip unzip p7zip git mercurial bzr texinfo help2man               \
    vim curl wget unrar apt-transport-https software-properties-common gnupg             \
    --no-install-recommends

# Fix any stock package issues
RUN ln -s /usr/include/asm-generic /usr/include/asm

# Install golang
RUN \
  add-apt-repository -y ppa:longsleep/golang-backports && \
  apt-get update && \
  apt-get install -y golang-go

RUN mkdir /go 

# Configure the Go environment, since it's not going to change
ENV PATH   /usr/local/go/bin:$PATH
ENV GOPATH /go

# Install nodejs and npm 
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
RUN apt-get -y install nodejs

# Download openssl-1.0.0e-mingw32.tar.gz and openssl-1.0.0e-mingw64.tar.gz
# Used for compiling golang binary on windows(386/amd64) platform (with cgo) 
RUN \
  cd /tmp && \
  wget http://www.blogcompiler.com/wp-content/uploads/2011/12/openssl-1.0.0e-mingw32.tar.gz && \
  wget http://www.blogcompiler.com/wp-content/uploads/2011/12/openssl-1.0.0e-mingw64.tar.gz && \
  tar -xvf openssl-1.0.0e-mingw32.tar.gz && \
  tar -xvf openssl-1.0.0e-mingw64.tar.gz && \
  cp -r ./mingw32/* /usr/i686-w64-mingw32/ && \
  cp -r ./mingw64/* /usr/x86_64-w64-mingw32/ && \
  rm -rf ./mingw32 && \
  rm -rf ./mingw64 && \
  cd /

# Install wine
RUN \
  dpkg --add-architecture i386 && \
  wget -qO - https://dl.winehq.org/wine-builds/winehq.key | apt-key add - && \
  apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main' && \
  apt-get update && \
  apt-get install -y --install-recommends winehq-stable
  
# Install Inno Setup binaries
RUN mkdir /innosetup && \
    cd /innosetup && \
    curl -fsSL -o innounp045.rar "https://downloads.sourceforge.net/project/innounp/innounp/innounp%200.45/innounp045.rar?r=&ts=1439566551&use_mirror=skylineservers" && \
    unrar e innounp045.rar && \
    curl -fsSL -o is-unicode.exe http://files.jrsoftware.org/is/5/isetup-5.5.8-unicode.exe && \
    wine "./innounp.exe" -e "is-unicode.exe"
