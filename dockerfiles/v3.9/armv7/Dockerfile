FROM arm32v6/alpine:3.9

COPY overlay/ /

# hack to force system to upgrade to armv7
COPY dockerfiles/v3.9/armv7/arch /etc/apk/

RUN ["setup.sh", "v3.9" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

