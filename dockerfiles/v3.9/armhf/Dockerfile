FROM arm32v6/alpine:3.9

COPY files/ /

RUN ["setup.sh", "v3.9" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

