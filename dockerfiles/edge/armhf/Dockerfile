FROM arm32v6/alpine:latest

COPY overlay/ /

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

