FROM alpine
RUN echo 'unicode="YES"' >> /etc/rc.conf
RUN apk --no-cache add bash bash-completion
RUN apk --no-cache add util-linux pciutils usbutils coreutils binutils findutils grep
ENTRYPOINT /bin/bash
