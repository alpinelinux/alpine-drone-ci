FROM arm32v6/alpine:latest

COPY files/ /

# hack to force system to upgrade to armv7
COPY dockerfiles/edge/armv7/arch /etc/apk/

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

