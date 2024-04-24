# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.19

# set version label
ARG VERSION
ARG ZIP_DOWNLOAD_LINK
LABEL maintainer="dalphinloser"
ARG BRANCH="develop"
ARG APP_NAME
ARG USER_NAME="DalphinLoser"

# environment settings
ENV XDG_CONFIG_HOME="/config/xdg"

# Convert APP_NAME to lowercase
ENV LOWER_APP_NAME=${APP_NAME,,}
ENV LOWER_USER_NAME=${USER_NAME,,}


# Install necessary packages including Subversion for svn export and curl for downloading assets
RUN \
  echo "**** install packages ****" && \
  apk add -U --upgrade --no-cache \
    icu-libs \
    sqlite-libs \
    xmlstarlet \
    unzip \
    curl \
    git  
RUN \
  echo "**** install ${LOWER_APP_NAME} ****"
RUN \    
  mkdir -p /app/${LOWER_APP_NAME}/bin
RUN \    
  curl -o /tmp/${LOWER_APP_NAME}.zip -L \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/octet-stream" \
      ${ZIP_DOWNLOAD_LINK}
RUN \    
  unzip /tmp/${LOWER_APP_NAME}.zip -d /app/${LOWER_APP_NAME}/bin && \
  chmod 755 /app/${LOWER_APP_NAME}/bin/${APP_NAME} || true
RUN \
  echo -e "UpdateMethod=docker\nBranch=${BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=[${LOWER_USER_NAME}](https://github.com/${USER_NAME})" > /app/${LOWER_APP_NAME}/package_info
RUN \
  echo "**** cleanup ****" && \
  rm -rf \
      /app/${LOWER_APP_NAME}/bin/${APP_NAME}.Update \
      /tmp/* \
    /var/tmp/*

# Fetch the `root` directory and copy contents to the image root
RUN mkdir -p /app/temp_root && \
    git init /app/temp_root && \
    cd /app/temp_root && \
    git remote add -f origin https://github.com/linuxserver/docker-${LOWER_APP_NAME}.git && \
    git config core.sparseCheckout true && \
    echo "root" > .git/info/sparse-checkout && \
    (git pull origin ${BRANCH} || \
    git pull origin $(git remote show origin | awk '/HEAD branch/ {print $NF}')) && \
    cp -rn /app/temp_root/root/. / && \
    rm -rf /app/temp_root

# Expose port and volume
EXPOSE 1234
VOLUME /config
