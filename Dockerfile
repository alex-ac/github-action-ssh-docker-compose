FROM alpine:3.8
LABEL maintainer="ya.alex-ac@yandex.com"
RUN apk add --no-cache ssh
ADD entrypoint.sh /entrypoint.sh
WORKDIR /github/workspace
ENTRYPOINT /bin/sh /entrypoint.sh
