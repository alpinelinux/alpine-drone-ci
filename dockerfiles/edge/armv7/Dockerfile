FROM arm32v7/alpine:latest

COPY overlay/ /

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

