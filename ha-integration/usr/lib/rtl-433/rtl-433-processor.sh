#!/bin/ash -e

echoerr() { echo "$@" 1>&2; }

MQTT_AUTH='--unix /tmp/mosquitto.sock'
JQ_SCRIPT='/usr/lib/rtl-433/rtl-433-processor.jq'

mosquitto_sub $MQTT_AUTH -V 5 -x 86400 \
    -t rtl_433/output/# \
    -F '%t\t%p' | jq --unbuffered -n -c -f ${JQ_SCRIPT} -R -S
