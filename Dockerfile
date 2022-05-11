FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PAPERLESS_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips"

ENV PAPERLESS_DATA_DIR=/config
ENV PAPERLESS_MEDIA_ROOT=/data/media
ENV PAPERLESS_CONSUMPTION_DIR=/data/consume

ARG BUILD_PACKAGES="\
  automake \
  autotools-dev \
  build-essential \
  git \
  jq \
  libatlas-base-dev \
  libleptonica-dev \
  libpq-dev \
  libqpdf-dev \
  libtool \
  python3-dev \
  python3-pip \
  zlib1g-dev"

ARG RUNTIME_PACKAGES="\
  curl \
  gettext \
  ghostscript \
  gnupg \
  gunicorn \
  icc-profiles-free \
  imagemagick \
  liblept5 \
  libmagic-dev \
  libpoppler-cpp-dev \
  libxml2 \
  libzbar0 \
  optipng \
  pngquant \
  poppler-utils \
  python3 \
  python3-setuptools \
  qpdf \
  redis \
  tesseract-ocr \
  tesseract-ocr-eng \
  tzdata \
  unpaper \
  zlib1g"

RUN \
  apt-get update && \
  echo "**** install build packages ****" && \
  apt-get install -y \
    --no-install-recommends \
    $BUILD_PACKAGES && \
  echo "**** install runtime packages ****" && \
  apt-get install -y \
    --no-install-recommends \
    $RUNTIME_PACKAGES && \
  echo "**** install jbig2enc ****" && \
  git clone https://github.com/agl/jbig2enc /tmp/jbig2enc && \
  cd /tmp/jbig2enc && \
  ./autogen.sh && \
  ./configure && \
  make && \
  cp /tmp/jbig2enc/src/.libs/libjbig2enc* /usr/local/lib/ && \
  cp /tmp/jbig2enc/src/jbig2 /usr/local/bin/ && \
  cp /tmp/jbig2enc/src/*.h /usr/local/include/ && \
  echo "**** install paperless ****" && \
  mkdir -p /app/paperless && \
  if [ -z ${PAPERLESS_RELEASE+x} ]; then \
    PAPERLESS_RELEASE=$(curl -sX GET "https://api.github.com/repos/paperless-ngx/paperless-ngx/releases" \
    | jq -r '.[0] | .tag_name'); \
  fi && \
  curl -o \
    /tmp/paperless.tar.gz -L \
    "https://github.com/paperless-ngx/paperless-ngx/releases/download/${PAPERLESS_RELEASE}/paperless-ngx-${PAPERLESS_RELEASE}.tar.xz" && \
  tar xf \
  /tmp/paperless.tar.gz -C \
    /app/paperless/ --strip-components=1 && \
  echo "**** install pip packages ****" && \
  cd /app/paperless && \
  pip3 install -U pip setuptools==60.10.0 && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/ubuntu/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  apt-get purge -y --auto-remove \
    $BUILD_PACKAGES && \
  rm -rf \
    /root/.cache \
    /root/.cargo \
    /tmp/* && \
  apt-get clean -y

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8000
