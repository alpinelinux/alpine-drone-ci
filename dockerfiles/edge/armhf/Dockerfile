FROM arm32v6/alpine:latest

COPY files/ /

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

