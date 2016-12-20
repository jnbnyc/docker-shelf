FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV LC_ALL C.UTF-8
ENV BASE_INSTALLED_PACKAGES "ca-certificates curl wget vim less locales dnsutils tcpdump pypy"

ADD install-apts.sh /usr/local/sbin/install-apts
ADD remove-apts.sh /usr/local/sbin/remove-apts

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN install-apts ${BASE_INSTALLED_PACKAGES}

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
