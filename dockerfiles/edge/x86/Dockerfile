FROM i386/alpine:latest

COPY files/ /

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

