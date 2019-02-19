FROM arm32v6/alpine:3.9

COPY scripts/*.sh /usr/local/bin/
COPY files/etc/ /etc/

RUN ["setup.sh", "v3.9" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

