FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FFMPEG_VERSION=4.3
ENV NODE_MAJOR=18
ENV EPGSTATION_VERSION=v2.7.3

RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  build-essential \
  cmake \
  curl \
  g++ \
  gcc \
  git \
  intel-media-va-driver-non-free \
  libaribb24-dev \
  libasound2 \
  libass-dev \
  libass9 \
  libdrm-dev \
  libfdk-aac-dev \
  libfreetype6-dev \
  libigfxcmrt7 \
  libmfx-dev \
  libmfx-tools \
  libmfx1 \
  libmp3lame-dev \
  libnuma-dev \
  libopus-dev \
  libsdl1.2-dev \
  libsdl2-dev \
  libssl-dev \
  libtheora-dev \
  libtheora0 \
  libtool \
  libva-dev \
  libva-drm2 \
  libva-glx2 \
  libva-x11-2 \
  libvdpau-dev \
  libvdpau1 \
  libvorbis-dev \
  libvorbisenc2 \
  libvpx-dev \
  libx11-dev \
  libx264-dev \
  libx265-dev \
  libxcb-shape0 \
  libxcb-shm0 \
  libxcb-shm0-dev \
  libxcb-xfixes0 \
  libxcb-xfixes0-dev \
  libxcb1-dev \
  make \
  meson \
  nasm \
  ninja-build \
  pkg-config \
  texinfo \
  vainfo \
  wget \
  yasm \
  zlib1g-dev \
  && \
  # install nodejs
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" |  tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update -y && \
  apt-get install --no-install-recommends -y nodejs

#AvisynthPlus install
WORKDIR /tmp
RUN git clone https://github.com/eginoy/AviSynthPlus.git && \
  cd AviSynthPlus && mkdir -p avisynth-build && cd avisynth-build && \
  cmake -DCMAKE_CXX_FLAGS=-latomic ../ -G Ninja && ninja && ninja install

#fdk-aac
WORKDIR /tmp
RUN git clone https://github.com/eginoy/fdk-aac.git && \
  cd fdk-aac && \
  ./autogen.sh && \
  ./configure && \
  make -j$(($(nproc)+1)) && \
  make install && \
  /sbin/ldconfig

#l-smash
WORKDIR /tmp
RUN git clone https://github.com/eginoy/l-smash.git && \
  cd l-smash && \
  ./configure --enable-shared && \
  make -j$(($(nproc)+1)) && \
  make install && \
  ldconfig

# ffmpeg install
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/eginoy/FFmpeg.git && \
  cd FFmpeg && \
  ./configure \
  --disable-x86asm \
  --enable-gpl \
  --enable-libass \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-version3 \
  --enable-libaribb24 \
  --enable-nonfree \
  --disable-debug \
  --disable-doc \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree \
  --enable-libfdk-aac \
  --enable-openssl \
  --enable-libmfx \
  --enable-avisynth \ 
  --enable-vaapi && \
  make -j$(($(nproc)+1)) && make install

#l-smash-works
WORKDIR /tmp
RUN git clone https://github.com/eginoy/L-SMASH-Works.git &&  \
  cd L-SMASH-Works/AviSynth &&  \
  LDFLAGS="-Wl,-Bsymbolic" meson build &&  \
  cd build &&  \
  ninja &&  \
  ninja install

#join_logo_scp
WORKDIR /tmp
RUN git clone --recursive https://github.com/eginoy/JoinLogoScpTrialSetLinux.git && \
  git clone https://github.com/tobitti0/chapter_exe.git && \
  cd /tmp/JoinLogoScpTrialSetLinux/modules/logoframe/src && \
  make -j$(($(nproc)+1)) && \
  cd /tmp && cp JoinLogoScpTrialSetLinux/modules/logoframe/src/logoframe JoinLogoScpTrialSetLinux/modules/join_logo_scp_trial/bin/logoframe && \
  cd /tmp/JoinLogoScpTrialSetLinux/modules/join_logo_scp/src && \
  make -j$(($(nproc)+1)) && \
  cd /tmp && cp JoinLogoScpTrialSetLinux/modules/join_logo_scp/src/join_logo_scp JoinLogoScpTrialSetLinux/modules/join_logo_scp_trial/bin/join_logo_scp && \
  cd /tmp/chapter_exe/src && \
  make -j$(($(nproc)+1)) && \
  cd /tmp && cp chapter_exe/src/chapter_exe JoinLogoScpTrialSetLinux/modules/join_logo_scp_trial/bin/chapter_exe && \
  mv JoinLogoScpTrialSetLinux/modules/join_logo_scp_trial /join_logo_scp_trial && \
  cd /join_logo_scp_trial && npm i && npm link

#delogo
WORKDIR /tmp
RUN git clone https://github.com/eginoy/delogo-AviSynthPlus-Linux.git && \
  cd delogo-AviSynthPlus-Linux/src && \
  make -j$(($(nproc)+1)) && make install && \
  cp /usr/local/lib/avisynth/libdelogo.so /join_logo_scp_trial 

# install EPGStation
RUN git clone https://github.com/eginoy/EPGStation.git -b ${EPGSTATION_VERSION} /app && \
  cd /app && \
  npm install && \
  npm install async && \
  npm run all-install && \
  npm run build

# clean
RUN apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/*

WORKDIR /app
ENTRYPOINT ["npm"]
CMD ["start"]
