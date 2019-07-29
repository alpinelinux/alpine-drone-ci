FROM arm32v6/alpine:latest AS arm

RUN apk update && apk -U add qemu-x86_64

FROM alpine:latest AS x86_64

COPY --from=arm /usr/bin/qemu-x86_64 /usr/bin/qemu-x86_64-static

RUN apk update && apk -U add qemu-arm

FROM arm32v6/alpine:latest

COPY overlay/ /

COPY --from=x86_64 /usr/bin/qemu-arm /use/bin/qemu-arm-static

RUN ["setup.sh", "edge" ]

USER buildozer

ENTRYPOINT [ "/bin/sh" ]

