FROM arm64v8/alpine:latest

COPY overlay/ /

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

