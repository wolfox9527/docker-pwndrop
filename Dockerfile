# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.20 as buildstage
COPY  /root/defaults/   /usr/local/pwndrop/
# build variables
ARG PWNDROP_RELEASE

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    build-base \
    go

RUN \
echo "**** fetch source code ****" && \
  if [ -z ${PWNDROP_RELEASE+x} ]; then \
    PWNDROP_RELEASE=$(curl -sX GET "https://api.github.com/repos/kgretzky/pwndrop/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p \
    /tmp/pwndrop && \
  curl -o \
  /tmp/pwndrop-src.tar.gz -L \
    "https://github.com/kgretzky/pwndrop/archive/${PWNDROP_RELEASE}.tar.gz" && \
  tar xf \
  /tmp/pwndrop-src.tar.gz -C \
    /tmp/pwndrop --strip-components=1 && \
  echo "**** compile pwndrop  ****" && \
  cd /tmp/pwndrop && \
  go build -ldflags="-s -w" \
    -o /app/pwndrop/pwndrop \
    -mod=vendor \
    main.go && \
  cp -r ./www /app/pwndrop/admin

############## runtime stage ##############
FROM ghcr.io/linuxserver/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PWNDROP_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# add pwndrop
COPY --from=buildstage /app/pwndrop/ /app/pwndrop/

RUN \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version

# add local files
COPY /root /

# ports and volumes
EXPOSE 8080 4443
