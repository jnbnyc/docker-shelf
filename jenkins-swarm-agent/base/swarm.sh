#!/bin/bash
set -e

[[ $LOGLEVEL == 'DEBUG' ]] && set -x

# checks and defaults
JENKINS_HOME=${HOME}
SWARM_JAR=/usr/share/jenkins/swarm-client.jar

[ -z "$SWARM_MASTER" ] && echo "INFO: SWARM_MASTER was not specified, enabling autodiscovery"
[ -z "$SWARM_DESCRIPTION" ] && SWARM_DESCRIPTION="INFO: Swarm version: $SWARM_VERSION - Jenkins slave"

SWARM_NAME="${SWARM_NAME:-$HOSTNAME}"
SWARM_EXECUTORS="${SWARM_EXECUTORS:-1}"
SWARM_MODE="${SWARM_MODE:-exclusive}"
SWARM_LABELS="${SWARM_LABELS:-docker}"
SWARM_RETRY="${SWARM_RETRY:-10}"

SWARM_CREDENTIALS="${SWARM_CREDENTIALS:-/etc/swarm/credentials}"
if [[ $SWARM_CREDENTIALS =~ .*:.* ]]; then
    echo 'WARN: Do not use colons, ":" or forwardslashes, "/" in your "username:password"'
    _USERNAME=$(echo $SWARM_CREDENTIALS|sed 's/:.*//')
    _PASSWORD=$(echo $SWARM_CREDENTIALS|sed 's/.*://')
    _CREDENTIALS="-username $_USERNAME -password $_PASSWORD"
elif [ -f $SWARM_CREDENTIALS ]; then
    _CREDENTIALS=$(echo "-username $(head -n1 $SWARM_CREDENTIALS) \
                         -password $(tail -n1 $SWARM_CREDENTIALS)")
fi

DOCKER_CONFIGFILE="${DOCKER_CONFIGFILE:-$JENKINS_HOME/.docker/config.json}"
[ -f $DOCKER_CONFIGFILE ] && ln -s "$DOCKER_CONFIGFILE" "${JENKINS_HOME}/.docker/config.json"

# entrypoint
exec java -jar "$SWARM_JAR" \
          -fsroot "$JENKINS_HOME" \
          -noRetryAfterConnected \
          -showHostName \
          $([ -n "$SWARM_MASTER" ] && echo '-master "$SWARM_MASTER"')\
          -name "$SWARM_NAME" \
          -description "$SWARM_DESCRIPTION" \
          -executors "$SWARM_EXECUTORS" \
          -mode "$SWARM_MODE" \
          -labels "$SWARM_LABELS" \
          -retry "$SWARM_RETRY" \
          $([ -z "$_CREDENTIALS" ] || echo "$_CREDENTIALS")\
          "$@"
