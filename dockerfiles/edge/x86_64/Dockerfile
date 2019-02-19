FROM amd64/alpine:latest

COPY scripts/*.sh /usr/local/bin/
COPY files/etc/ /etc/

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

