FROM openjdk:8-jdk-alpine

RUN echo 'unicode="YES"' >> /etc/rc.conf
RUN apk --no-cache add \
    bash util-linux pciutils \
    usbutils coreutils binutils \
    findutils grep

# build-essential
RUN apk add --no-cache \
    ca-certificates curl \
    git openssl \
    tar unzip wget zip

# RUN apk add -no-cache python python-pip && \
#     pip install --upgrade pip setuptools

#  Install Swarm
ENV SWARM_VERSION 3.3
ADD https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_VERSION}/swarm-client-${SWARM_VERSION}.jar /usr/share/jenkins/swarm-client.jar
RUN chmod 755 /usr/share/jenkins && \
    chmod 664 /usr/share/jenkins/swarm-client.jar

# Install Docker
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 17.03.1-ce
ENV DOCKER_SHA256 820d13b5699b5df63f7032c8517a5f118a44e2be548dd03271a86656a544af55

RUN set -x \
	&& curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
	&& echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
	&& tar -xzvf docker.tgz \
	&& mv docker/* /usr/local/bin/ \
	&& rmdir docker \
	&& rm docker.tgz \
	&& docker -v

#  Set up jenkins user
ENV HOME /home/jenkins
RUN addgroup -g 10000 jenkins
RUN adduser -h $HOME -u 10000 -G jenkins -D jenkins
RUN adduser jenkins users

USER jenkins
RUN mkdir /home/jenkins/.jenkins
VOLUME /home/jenkins/.jenkins
WORKDIR /home/jenkins

ADD swarm.sh /usr/local/bin/swarm.sh
ENTRYPOINT ["/usr/local/bin/swarm.sh"]
