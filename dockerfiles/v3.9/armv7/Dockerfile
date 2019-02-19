FROM arm32v6/alpine:3.9

COPY scripts/*.sh /usr/local/bin/
COPY files/etc/ /etc/

# hack to force system to upgrade to armv7
COPY dockerfiles/v3.9/armv7/arch /etc/apk/

RUN ["setup.sh", "v3.9" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

